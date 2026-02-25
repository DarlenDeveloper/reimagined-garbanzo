import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/store_service.dart';
import '../services/auth_service.dart';
import '../services/currency_service.dart';
import '../services/image_service.dart';
import 'currency_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storeService = StoreService();
  final _authService = AuthService();
  final _currencyService = CurrencyService();
  final _imageService = ImageService();
  bool _notificationsEnabled = true;
  String _language = 'English';
  String _currency = 'UGX';
  
  // User data
  String _userName = '';
  String _userEmail = '';
  String _subscription = 'Free';
  String? _logoUrl;
  Map<String, dynamic>? _storeData;
  bool _isLoading = true;
  
  // Image picker state
  XFile? _selectedImage;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? 'User';
        _userEmail = user.email ?? '';
      });
    }
    
    try {
      final storeId = await _storeService.getUserStoreId();
      if (storeId != null) {
        final data = await _storeService.getStore(storeId);
        if (data != null && mounted) {
          setState(() {
            _storeData = data;
            _logoUrl = data['logoUrl'];
            _subscription = (data['subscription'] ?? 'free').toString().toUpperCase();
            if (_subscription == 'FREE') _subscription = 'Free Plan';
            else if (_subscription == 'PRO') _subscription = 'Pro Plan';
            else if (_subscription == 'BUSINESS') _subscription = 'Business Plan';
          });
          // Pre-cache the logo so it never shows loading
          if (_logoUrl != null && _logoUrl!.isNotEmpty) {
            await precacheImage(CachedNetworkImageProvider(_logoUrl!), context);
          }

          // Load currency from service
          await _currencyService.init(storeId);
          if (mounted) {
            setState(() => _currency = _currencyService.currentCurrency);
          }
        }
      }
    } catch (e) {
      // Handle error
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildProfileCard(context),
              const SizedBox(height: 24),
              _buildSection('Account', [
                _SettingsItem(icon: Iconsax.user, label: 'Personal Information', onTap: () => _showPersonalInfoSheet(context)),
                _SettingsItem(icon: Iconsax.lock, label: 'Password & Security', onTap: () => _showSecuritySheet(context)),
                _SettingsItem(icon: Iconsax.card, label: 'Payment Methods', onTap: () => _showPaymentMethodsSheet(context)),
                _SettingsItem(icon: Iconsax.wallet_2, label: 'Bank Accounts', onTap: () => _showBankAccountsSheet(context)),
              ]),
              const SizedBox(height: 16),
              _buildSection('Store', [
                _SettingsItem(icon: Iconsax.shop, label: 'Store Profile', onTap: () => _showStoreProfileSheet(context)),
                _SettingsItem(icon: Iconsax.location, label: 'Store Address', onTap: () => _showStoreAddressSheet(context)),
                _SettingsItem(icon: Iconsax.clock, label: 'Business Hours', onTap: () => _showBusinessHoursSheet(context)),
                _SettingsItem(icon: Iconsax.document, label: 'Policies', onTap: () => _showPoliciesSheet(context)),
              ]),
              const SizedBox(height: 16),
              _buildSection('Preferences', [
                _SettingsItem(icon: Iconsax.notification, label: 'Notifications', trailing: _buildSwitch(_notificationsEnabled, (v) => setState(() => _notificationsEnabled = v)), onTap: () {}),
                _SettingsItem(icon: Iconsax.language_square, label: 'Language', trailing: _buildTrailingText(_language), onTap: () => _showLanguageSheet(context)),
                _SettingsItem(icon: Iconsax.dollar_circle, label: 'Currency', trailing: _buildTrailingText(_currency), onTap: () => _showCurrencySheet(context)),
              ]),
              const SizedBox(height: 16),
              _buildSection('Support', [
                _SettingsItem(icon: Iconsax.message_question, label: 'Help Center', onTap: () => _showHelpCenterSheet(context)),
                _SettingsItem(icon: Iconsax.message, label: 'Contact Support', onTap: () => _showContactSupportSheet(context)),
              ]),
              const SizedBox(height: 24),
              _buildLogoutButton(context),
              const SizedBox(height: 16),
              _buildVersionInfo(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
              child: const Icon(Iconsax.arrow_left, color: Colors.black, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Text('Settings', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _showEditProfileSheet(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _logoUrl != null && _logoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: _logoUrl!,
                          cacheKey: 'store_logo',
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          memCacheWidth: 120,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholderFadeInDuration: Duration.zero,
                          placeholder: (context, url) => const Icon(Iconsax.user, color: Colors.white, size: 28),
                          errorWidget: (context, url, error) => const Icon(Iconsax.user, color: Colors.white, size: 28),
                        ),
                      )
                    : const Icon(Iconsax.user, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                    Text(_userEmail, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
                      child: Text(_subscription, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Icon(Iconsax.arrow_right_3, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(bool value, Function(bool) onChanged) {
    return Switch(value: value, onChanged: onChanged, activeColor: Colors.black, activeTrackColor: Colors.grey[400], inactiveThumbColor: Colors.grey[400], inactiveTrackColor: Colors.grey[200]);
  }

  Widget _buildTrailingText(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(width: 4),
        Icon(Iconsax.arrow_right_3, color: Colors.grey[400], size: 18),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _showLogoutDialog(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[300]!)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.logout, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              Text('Log Out', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[700])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Column(
        children: [
          Text('POP Vendor', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600])),
          Text('Version 1.0.0', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400])),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        content: Text('Are you sure you want to log out?', style: GoogleFonts.poppins(color: Colors.grey[600])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600]))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.signOut();
              if (mounted) context.go('/');
            },
            child: Text('Log Out', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showBottomSheet(BuildContext context, String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
                  const Spacer(),
                  GestureDetector(onTap: () => Navigator.pop(ctx), child: Icon(Iconsax.close_circle, color: Colors.grey[400])),
                ],
              ),
            ),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16), child: content)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {bool obscure = false, int maxLines = 1, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSaveButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFb71000),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Save Changes', 
            style: GoogleFonts.poppins(
              color: Colors.white, 
              fontSize: 15, 
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    final contact = _storeData?['contact'] as Map<String, dynamic>? ?? {};
    _showBottomSheet(context, 'Edit Profile', Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(File(_selectedImage!.path), fit: BoxFit.cover, width: 80, height: 80),
                        )
                      : _logoUrl != null && _logoUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CachedNetworkImage(imageUrl: _logoUrl!, fit: BoxFit.cover, width: 80, height: 80),
                            )
                          : const Icon(Iconsax.user, color: Colors.white, size: 36),
                ),
                Positioned(
                  bottom: 0, 
                  right: 0, 
                  child: Container(
                    padding: const EdgeInsets.all(6), 
                    decoration: BoxDecoration(
                      color: const Color(0xFFfb2a0a), 
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ), 
                    child: _isUploadingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Iconsax.camera, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField('Full Name', _userName.isNotEmpty ? _userName : 'Enter your name'),
        _buildTextField('Email', _userEmail.isNotEmpty ? _userEmail : 'Enter your email'),
        _buildTextField('Phone', contact['phone']?.toString() ?? 'Enter phone number'),
        _buildSaveButton(() => _saveProfileChanges(context)),
      ],
    ));
  }
  
  Future<void> _pickProfileImage() async {
    try {
      final image = await _imageService.pickImage();
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _saveProfileChanges(BuildContext context) async {
    if (_selectedImage == null) {
      Navigator.pop(context);
      return;
    }
    
    setState(() => _isUploadingImage = true);
    
    try {
      final storeId = await _storeService.getUserStoreId();
      if (storeId == null) {
        throw Exception('Store not found');
      }
      
      // Convert XFile to File
      final imageFile = File(_selectedImage!.path);
      
      // Upload the new logo
      final logoUrl = await _imageService.uploadStoreLogo(storeId, imageFile);
      
      // Update store with new logo
      await _storeService.updateStoreLogo(storeId, logoUrl);
      
      setState(() {
        _logoUrl = logoUrl;
        _selectedImage = null;
        _isUploadingImage = false;
      });
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture updated', style: GoogleFonts.poppins()),
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPersonalInfoSheet(BuildContext context) {
    final contact = _storeData?['contact'] as Map<String, dynamic>? ?? {};
    _showBottomSheet(context, 'Personal Information', Column(
      children: [
        _buildTextField('Full Name', _userName.isNotEmpty ? _userName : 'Enter your name'),
        _buildTextField('Email', _userEmail.isNotEmpty ? _userEmail : 'Enter your email'),
        _buildTextField('Phone Number', contact['phone']?.toString() ?? 'Enter phone number'),
        _buildTextField('Date of Birth', 'Not set'),
        _buildSaveButton(() => Navigator.pop(context)),
      ],
    ));
  }

  void _showSecuritySheet(BuildContext context) {
    _showBottomSheet(context, 'Password & Security', Column(
      children: [
        _buildTextField('Current Password', '••••••••', obscure: true),
        _buildTextField('New Password', 'Enter new password', obscure: true),
        _buildTextField('Confirm Password', 'Confirm new password', obscure: true),
        const SizedBox(height: 16),
        _buildSecurityOption('Two-Factor Authentication', 'Add extra security to your account', true),
        _buildSecurityOption('Login Alerts', 'Get notified of new logins', true),
        const SizedBox(height: 16),
        _buildSaveButton(() => Navigator.pop(context)),
      ],
    ));
  }

  Widget _buildSecurityOption(String title, String subtitle, bool enabled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: (_) {}, activeColor: Colors.black),
        ],
      ),
    );
  }

  void _showPaymentMethodsSheet(BuildContext context) {
    final paymentMethods = _storeData?['paymentMethods'] as Map<String, dynamic>? ?? {};
    final hasMomo = paymentMethods['mobileMoney'] == true;
    final hasCard = paymentMethods['cardPayments'] == true;
    final hasCod = paymentMethods['cashOnDelivery'] == true;
    
    _showBottomSheet(context, 'Payment Methods', Column(
      children: [
        if (hasCod) _buildPaymentMethodItem('Cash on Delivery', 'Enabled', Iconsax.money, true),
        if (hasMomo) _buildPaymentMethodItem('Mobile Money', paymentMethods['momoNumber']?.toString() ?? 'Enabled', Iconsax.mobile, true),
        if (hasCard) _buildPaymentMethodItem('Card Payments', 'Visa, Mastercard', Iconsax.card, true),
        if (!hasCod && !hasMomo && !hasCard)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('No payment methods configured', style: GoogleFonts.poppins(color: Colors.grey[500])),
          ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.add, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('Add Payment Method', style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildPaymentMethodItem(String type, String detail, IconData icon, bool isEnabled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.black)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black)),
                Text(detail, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          if (isEnabled) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)), child: Text('Active', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white))),
        ],
      ),
    );
  }

  void _showBankAccountsSheet(BuildContext context) {
    final paymentMethods = _storeData?['paymentMethods'] as Map<String, dynamic>? ?? {};
    final hasBankTransfer = paymentMethods['bankTransfer'] == true;
    final bankName = paymentMethods['bankName']?.toString() ?? '';
    final accountName = paymentMethods['accountName']?.toString() ?? '';
    final accountNumber = paymentMethods['accountNumber']?.toString() ?? '';
    
    _showBottomSheet(context, 'Bank Accounts', Column(
      children: [
        if (hasBankTransfer && bankName.isNotEmpty)
          _buildBankAccount(bankName, accountName.isNotEmpty ? accountName : 'Account: •••• ${accountNumber.length > 4 ? accountNumber.substring(accountNumber.length - 4) : accountNumber}', true)
        else
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('No bank accounts configured', style: GoogleFonts.poppins(color: Colors.grey[500])),
          ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.add, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('Add Bank Account', style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildBankAccount(String bank, String number, bool isDefault) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Icon(Iconsax.bank, color: Colors.black)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bank, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black)),
                Text(number, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          if (isDefault) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)), child: Text('Primary', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white))),
        ],
      ),
    );
  }

  void _showStoreProfileSheet(BuildContext context) {
    final storeName = _storeData?['name']?.toString() ?? '';
    final storeDesc = _storeData?['description']?.toString() ?? '';
    final storeCategory = _storeData?['category']?.toString() ?? '';
    
    _showBottomSheet(context, 'Store Profile', Column(
      children: [
        Center(
          child: Stack(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                child: _logoUrl != null && _logoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CachedNetworkImage(imageUrl: _logoUrl!, fit: BoxFit.cover, width: 80, height: 80),
                      )
                    : const Icon(Iconsax.shop, color: Colors.white, size: 36),
              ),
              Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle), child: const Icon(Iconsax.camera, size: 16, color: Colors.black))),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField('Store Name', storeName.isNotEmpty ? storeName : 'Enter store name'),
        _buildTextField('Store URL', '${storeName.toLowerCase().replaceAll(' ', '')}.purl.com'),
        _buildTextField('Description', storeDesc.isNotEmpty ? storeDesc : 'Tell customers about your store...', maxLines: 3),
        _buildTextField('Category', storeCategory.isNotEmpty ? storeCategory : 'Select category'),
        _buildSaveButton(() => Navigator.pop(context)),
      ],
    ));
  }

  void _showStoreAddressSheet(BuildContext context) {
    final address = _storeData?['address'] as Map<String, dynamic>? ?? {};
    
    _showBottomSheet(context, 'Store Address', Column(
      children: [
        _buildTextField('Street Address', address['street']?.toString() ?? 'Enter street address'),
        _buildTextField('City', address['city']?.toString() ?? 'Enter city'),
        _buildTextField('State/Province', address['state']?.toString() ?? 'Enter state'),
        _buildTextField('Postal Code', address['postalCode']?.toString() ?? 'Enter postal code'),
        _buildTextField('Country', address['country']?.toString() ?? 'Select country'),
        _buildSaveButton(() => Navigator.pop(context)),
      ],
    ));
  }

  void _showBusinessHoursSheet(BuildContext context) {
    final businessHours = _storeData?['businessHours'] as Map<String, dynamic>? ?? {};
    
    Widget buildDayRow(String day) {
      final dayData = businessHours[day] as Map<String, dynamic>?;
      final isOpen = dayData?['isOpen'] ?? false;
      final open = dayData?['open']?.toString() ?? '09:00';
      final close = dayData?['close']?.toString() ?? '18:00';
      return _buildDayHours(day, open, close, isOpen);
    }
    
    _showBottomSheet(context, 'Business Hours', Column(
      children: [
        buildDayRow('Monday'),
        buildDayRow('Tuesday'),
        buildDayRow('Wednesday'),
        buildDayRow('Thursday'),
        buildDayRow('Friday'),
        buildDayRow('Saturday'),
        buildDayRow('Sunday'),
        const SizedBox(height: 16),
        _buildSaveButton(() => Navigator.pop(context)),
      ],
    ));
  }

  Widget _buildDayHours(String day, String open, String close, bool isOpen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(day, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black))),
          Expanded(child: Text(isOpen ? '$open - $close' : 'Closed', style: GoogleFonts.poppins(color: isOpen ? Colors.grey[700] : Colors.grey[400]))),
          Switch(value: isOpen, onChanged: (_) {}, activeColor: Colors.black),
        ],
      ),
    );
  }

  void _showPoliciesSheet(BuildContext context) {
    _showBottomSheet(context, 'Store Policies', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPolicyRule('1', 'Deliver in 24 Hours', 'All orders must be delivered within 24 hours of confirmation'),
        const SizedBox(height: 16),
        _buildPolicyRule('2', 'Price Well', 'Set fair and competitive prices for your products'),
        const SizedBox(height: 16),
        _buildPolicyRule('3', 'Sell the Right Products', 'Only sell authentic, legal, and quality products'),
        const SizedBox(height: 16),
        _buildPolicyRule('4', 'No Cash Outside Platform', 'Never ask for cash payments outside the platform or you will be banned'),
      ],
    ));
  }

  Widget _buildPolicyRule(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFfb2a0a),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPoliciesSheetOld(BuildContext context) {
    _showBottomSheet(context, 'Store Policies', Column(
      children: [
        _buildPolicyItem('Return Policy', 'Define your return and refund policy'),
        _buildPolicyItem('Shipping Policy', 'Set shipping terms and conditions'),
        _buildPolicyItem('Privacy Policy', 'Customer data handling policy'),
        _buildPolicyItem('Terms of Service', 'Store terms and conditions'),
      ],
    ));
  }

  Widget _buildPolicyItem(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        trailing: Icon(Iconsax.edit_2, color: Colors.grey[400], size: 20),
        onTap: () {},
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final languages = ['English', 'Spanish', 'French', 'German', 'Chinese', 'Japanese', 'Arabic'];
    _showBottomSheet(context, 'Language', Column(
      children: languages.map((lang) => _buildSelectionItem(lang, _language == lang, () {
        setState(() => _language = lang);
        Navigator.pop(context);
      })).toList(),
    ));
  }

  void _showCurrencySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CurrencySelectionSheet(
        currentCurrency: _currency,
        onCurrencyChanged: (newCurrency) {
          setState(() => _currency = newCurrency);
        },
      ),
    );
  }

  Widget _buildSelectionItem(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isSelected ? Colors.black : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: isSelected ? Colors.white : Colors.black)),
            const Spacer(),
            if (isSelected) const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  void _showHelpCenterSheet(BuildContext context) {
    _showBottomSheet(context, 'Help Center', Column(
      children: [
        _buildHelpItem(Iconsax.book_1, 'Getting Started', 'Learn the basics of selling'),
        _buildHelpItem(Iconsax.box, 'Managing Products', 'Add and edit your products'),
        _buildHelpItem(Iconsax.receipt_2, 'Orders & Fulfillment', 'Process and ship orders'),
        _buildHelpItem(Iconsax.wallet_2, 'Payments & Payouts', 'Understand your earnings'),
        _buildHelpItem(Iconsax.chart_2, 'Analytics & Reports', 'Track your performance'),
        _buildHelpItem(Iconsax.truck_fast, 'Shipping Setup', 'Configure shipping options'),
      ],
    ));
  }

  Widget _buildHelpItem(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.black, size: 20)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        trailing: Icon(Iconsax.arrow_right_3, color: Colors.grey[400], size: 18),
        onTap: () {},
      ),
    );
  }

  void _showContactSupportSheet(BuildContext context) {
    _showBottomSheet(context, 'Contact Support', Column(
      children: [
        _buildContactOption(Iconsax.message, 'Live Chat', 'Chat with our support team', () {}),
        _buildContactOption(Iconsax.sms, 'Email Support', 'support@purl.com', () {}),
        _buildContactOption(Iconsax.call, 'Phone Support', '+1 800 123 4567', () {}),
        const SizedBox(height: 24),
        Text('Support Hours', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        Text('Monday - Friday: 9AM - 6PM EST\nSaturday: 10AM - 4PM EST\nSunday: Closed', style: GoogleFonts.poppins(color: Colors.grey[600], height: 1.5), textAlign: TextAlign.center),
      ],
    ));
  }

  Widget _buildContactOption(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  void _showTermsSheet(BuildContext context) {
    _showBottomSheet(context, 'Terms of Service', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last updated: December 2024\n', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12)),
        Text('1. Acceptance of Terms', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        Text('By accessing and using POP, you accept and agree to be bound by the terms and provision of this agreement.', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        Text('2. Use License', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        Text('Permission is granted to temporarily use POP for personal, non-commercial transitory viewing only.', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        Text('3. Disclaimer', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        Text('The materials on POP are provided on an "as is" basis. POP makes no warranties, expressed or implied.', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 13, height: 1.5)),
        const SizedBox(height: 24),
      ],
    ));
  }

  void _showPrivacySheet(BuildContext context) {
    _showBottomSheet(context, 'Privacy Policy', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last updated: December 2024\n', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12)),
        Text('Information We Collect', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        Text('We collect information you provide directly to us, such as when you create an account, make a purchase, or contact us for support.', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        Text('How We Use Your Information', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        Text('We use the information we collect to provide, maintain, and improve our services, process transactions, and send you related information.', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        Text('Data Security', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        Text('We take reasonable measures to help protect information about you from loss, theft, misuse, and unauthorized access.', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 13, height: 1.5)),
        const SizedBox(height: 24),
      ],
    ));
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsItem({required this.icon, required this.label, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: const Color(0xFFfb2a0a), size: 20)),
      title: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
      trailing: trailing ?? Icon(Iconsax.arrow_right_3, color: Colors.grey[400], size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    );
  }
}
