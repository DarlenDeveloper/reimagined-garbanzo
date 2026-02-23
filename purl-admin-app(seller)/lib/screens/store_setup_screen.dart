import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../services/store_service.dart';

class StoreSetupScreen extends StatefulWidget {
  const StoreSetupScreen({super.key});

  @override
  State<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends State<StoreSetupScreen> {
  final _storeService = StoreService();
  final _imagePicker = ImagePicker();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;
  bool _isCreating = false;
  File? _logoFile;
  String? _logoUrl;

  // Step 1: Store Info
  final _storeNameController = TextEditingController();
  final _storeDescController = TextEditingController();
  String _selectedCategory = '';

  // Step 2: Store Address
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalController = TextEditingController();
  String _selectedCountry = '';

  // Step 3: Contact Info
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  // Step 4: Business Hours
  final Map<String, _BusinessHour> _businessHours = {
    'Monday': _BusinessHour(isOpen: true, open: '09:00', close: '18:00'),
    'Tuesday': _BusinessHour(isOpen: true, open: '09:00', close: '18:00'),
    'Wednesday': _BusinessHour(isOpen: true, open: '09:00', close: '18:00'),
    'Thursday': _BusinessHour(isOpen: true, open: '09:00', close: '18:00'),
    'Friday': _BusinessHour(isOpen: true, open: '09:00', close: '18:00'),
    'Saturday': _BusinessHour(isOpen: true, open: '10:00', close: '16:00'),
    'Sunday': _BusinessHour(isOpen: false, open: '', close: ''),
  };

  // Step 5: Shipping
  bool _enableLocalDelivery = true;
  bool _enableNationwide = false;
  bool _enablePickup = true;

  final List<String> _categories = [
    'Fashion & Apparel', 'Electronics', 'Beauty & Cosmetics', 'Food & Beverages',
    'Home & Garden', 'Health & Wellness', 'Sports & Outdoors', 'Books & Stationery',
    'Toys & Games', 'Automotive', 'Jewelry & Accessories', 'Art & Crafts', 'Other'
  ];

  final List<String> _countries = [
    'United States', 'United Kingdom', 'Canada', 'Nigeria', 'Ghana', 'Kenya',
    'Uganda', 'Tanzania', 'South Africa', 'Saudi Arabia', 'UAE', 'Japan', 'Other'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _storeNameController.dispose();
    _storeDescController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _createStore();
    }
  }

  Future<void> _createStore() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);
    try {
      // First create store to get ID
      final storeId = await _storeService.createStore(
        name: _storeNameController.text.trim(),
        category: _selectedCategory,
        description: _storeDescController.text.trim(),
        address: {
          'country': _selectedCountry,
          'street': _streetController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'postalCode': _postalController.text.trim(),
        },
        contact: {
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'website': _websiteController.text.trim(),
        },
        businessHours: _businessHours.map((day, hours) => MapEntry(day, {
          'isOpen': hours.isOpen,
          'open': hours.open,
          'close': hours.close,
        })),
        shipping: {
          'localDelivery': _enableLocalDelivery,
          'nationwide': _enableNationwide,
          'storePickup': _enablePickup,
        },
      );

      // Upload logo with store ID in path
      if (_logoFile != null) {
        final ref = FirebaseStorage.instance.ref().child('store_logos/$storeId/logo.jpg');
        await ref.putFile(_logoFile!);
        _logoUrl = await ref.getDownloadURL();
        await _storeService.updateStoreLogo(storeId, _logoUrl!);
      }

      if (mounted) context.go('/dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create store: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStoreInfoStep(),
                  _buildAddressStep(),
                  _buildContactStep(),
                  _buildBusinessHoursStep(),
                  _buildShippingStep(),
                ],
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final stepTitles = ['Store Info', 'Address', 'Contact', 'Hours', 'Shipping'];
    // Safety check for hot reload
    if (_currentStep >= stepTitles.length) {
      _currentStep = stepTitles.length - 1;
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentStep > 0)
            GestureDetector(
              onTap: _prevStep,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                child: const Icon(Iconsax.arrow_left, size: 20),
              ),
            )
          else
            const SizedBox(width: 36),
          Expanded(
            child: Column(
              children: [
                Text('Step ${_currentStep + 1} of $_totalSteps', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                Text(stepTitles[_currentStep], style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: isCompleted || isCurrent ? const Color(0xFFfb2a0a) : Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomButtons() {
    const double buttonHeight = 52;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: _isCreating ? null : _nextStep,
        child: Container(
          width: double.infinity,
          height: buttonHeight,
          decoration: BoxDecoration(
            color: _isCreating ? Colors.grey : const Color(0xFFb71000),
            borderRadius: BorderRadius.circular(buttonHeight / 2),
          ),
          child: Center(
            child: _isCreating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    _currentStep == _totalSteps - 1 ? 'Finish Setup' : 'Continue',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {IconData? icon, TextInputType? keyboardType, int maxLines = 1}) {
    const double fieldHeight = 52;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
        const SizedBox(height: 8),
        Container(
          height: maxLines == 1 ? fieldHeight : null,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(maxLines == 1 ? fieldHeight / 2 : 16),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
              filled: false,
              prefixIcon: icon != null ? Icon(icon, color: Colors.grey[500], size: 20) : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: maxLines == 1 ? 20 : 16, vertical: maxLines == 1 ? 16 : 14),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdown(String label, String hint, String value, List<String> items, Function(String) onChanged, {IconData? icon}) {
    const double fieldHeight = 52;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showSelectionSheet(label, items, value, onChanged),
          child: Container(
            height: fieldHeight,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(fieldHeight / 2)),
            child: Row(
              children: [
                if (icon != null) ...[Icon(icon, color: Colors.grey[500], size: 20), const SizedBox(width: 12)],
                Expanded(child: Text(value.isEmpty ? hint : value, style: GoogleFonts.poppins(fontSize: 14, color: value.isEmpty ? Colors.grey[400] : Colors.black))),
                Icon(Iconsax.arrow_down_1, color: Colors.grey[500], size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showSelectionSheet(String title, List<String> items, String selected, Function(String) onChanged) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.all(16), child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600))),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = item == selected;
                  return GestureDetector(
                    onTap: () {
                      onChanged(item);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: isSelected ? const Color(0xFFfb2a0a) : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Expanded(child: Text(item, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: isSelected ? Colors.white : Colors.black))),
                          if (isSelected) const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1: Store Info
  Widget _buildStoreInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Logo
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                      image: _logoFile != null
                          ? DecorationImage(image: FileImage(_logoFile!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _logoFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Iconsax.camera, color: Colors.grey[400], size: 28),
                              const SizedBox(height: 4),
                              Text('Add Logo', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_logoFile != null ? 'Tap to change' : 'Tap to upload', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField('Store Name', 'Enter your store name', _storeNameController, icon: Iconsax.shop),
          _buildTextField('Store Description', 'Tell customers about your store...', _storeDescController, maxLines: 3, icon: Iconsax.document_text),
          _buildDropdown('Store Category', 'Select a category', _selectedCategory, _categories, (v) => setState(() => _selectedCategory = v), icon: Iconsax.category),
        ],
      ),
    );
  }

  Future<void> _pickLogo() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked != null) {
      setState(() => _logoFile = File(picked.path));
    }
  }

  // STEP 2: Address
  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Icon(Iconsax.location, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(child: Text('This address will be shown to customers and used for shipping calculations.', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildDropdown('Country', 'Select your country', _selectedCountry, _countries, (v) => setState(() => _selectedCountry = v), icon: Iconsax.global),
          _buildTextField('Street Address', '123 Main Street', _streetController, icon: Iconsax.home),
          Row(
            children: [
              Expanded(child: _buildTextField('City', 'City', _cityController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('State/Province', 'State', _stateController)),
            ],
          ),
          _buildTextField('Postal Code', 'Postal/ZIP code', _postalController, icon: Iconsax.location, keyboardType: TextInputType.number),
        ],
      ),
    );
  }

  // STEP 3: Contact Info
  Widget _buildContactStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Icon(Iconsax.call, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(child: Text('How can customers reach you? This info will be visible on your store.', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField('Phone Number', '+1 234 567 8900', _phoneController, icon: Iconsax.call, keyboardType: TextInputType.phone),
          _buildTextField('Business Email', 'store@example.com', _emailController, icon: Iconsax.sms, keyboardType: TextInputType.emailAddress),
          _buildTextField('Website (Optional)', 'www.yourstore.com', _websiteController, icon: Iconsax.global, keyboardType: TextInputType.url),
          const SizedBox(height: 16),
          Text('Social Media', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildSocialInput('Instagram', Iconsax.instagram, '@yourstore'),
          _buildSocialInput('Facebook', Iconsax.link, 'facebook.com/yourstore'),
          _buildSocialInput('Twitter/X', Iconsax.message, '@yourstore'),
        ],
      ),
    );
  }

  Widget _buildSocialInput(String label, IconData icon, String hint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 4: Business Hours
  Widget _buildBusinessHoursStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Icon(Iconsax.clock, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(child: Text('Set your store operating hours. Customers will see when you\'re available.', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ..._businessHours.entries.map((entry) => _buildDayHoursRow(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildDayHoursRow(String day, _BusinessHour hours) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(day, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
          Expanded(
            child: hours.isOpen
                ? Row(
                    children: [
                      _buildTimeSelector(hours.open, (t) => setState(() => _businessHours[day] = hours.copyWith(open: t))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('-', style: GoogleFonts.poppins(color: Colors.grey[500]))),
                      _buildTimeSelector(hours.close, (t) => setState(() => _businessHours[day] = hours.copyWith(close: t))),
                    ],
                  )
                : Text('Closed', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14)),
          ),
          Switch(
            value: hours.isOpen,
            onChanged: (v) => setState(() => _businessHours[day] = hours.copyWith(isOpen: v)),
            activeColor: const Color(0xFFfb2a0a),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(String time, Function(String) onChanged) {
    return GestureDetector(
      onTap: () => _showTimePicker(time, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: Text(time, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }

  void _showTimePicker(String currentTime, Function(String) onChanged) {
    final times = ['06:00', '07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00', '22:00', '23:00'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: 300,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.all(16), child: Text('Select Time', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600))),
            Expanded(
              child: ListView.builder(
                itemCount: times.length,
                itemBuilder: (context, index) {
                  final t = times[index];
                  return GestureDetector(
                    onTap: () {
                      onChanged(t);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: t == currentTime ? const Color(0xFFfb2a0a) : Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text(t, style: GoogleFonts.poppins(color: t == currentTime ? Colors.white : Colors.black, fontWeight: FontWeight.w500))),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 5: Shipping Setup
  Widget _buildShippingStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Icon(Iconsax.truck_fast, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(child: Text('Configure how you\'ll deliver products to your customers.', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Delivery Options', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildShippingOption('Local Delivery', 'Deliver within your city', Iconsax.location, _enableLocalDelivery, (v) => setState(() => _enableLocalDelivery = v)),
          _buildShippingOption('Nationwide Shipping', 'Ship across the country', Iconsax.truck, _enableNationwide, (v) => setState(() => _enableNationwide = v)),
          _buildShippingOption('Store Pickup', 'Customers pick up from your location', Iconsax.shop, _enablePickup, (v) => setState(() => _enablePickup = v)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFfb2a0a), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Icon(Iconsax.info_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('You can always change these settings later in your store dashboard.', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingOption(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: value ? const Color(0xFFfb2a0a) : Colors.grey[100], borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: value ? Colors.white.withAlpha(25) : Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: value ? Colors.white : Colors.black, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: value ? Colors.white : Colors.black)),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: value ? Colors.grey[400] : Colors.grey[600])),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: Colors.white, activeTrackColor: Colors.grey[600]),
        ],
      ),
    );
  }
}

class _BusinessHour {
  final bool isOpen;
  final String open;
  final String close;

  _BusinessHour({required this.isOpen, required this.open, required this.close});

  _BusinessHour copyWith({bool? isOpen, String? open, String? close}) {
    return _BusinessHour(isOpen: isOpen ?? this.isOpen, open: open ?? this.open, close: close ?? this.close);
  }
}
