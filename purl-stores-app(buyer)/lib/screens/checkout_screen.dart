import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/colors.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/currency_service.dart';
import '../services/delivery_fee_service.dart';
import 'order_history_screen.dart';
import 'location_picker_screen.dart';
import 'main_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String? promoCode;
  final double? promoDiscount;
  final String? discountId;
  final String? discountStoreId;

  const CheckoutScreen({
    super.key,
    this.promoCode,
    this.promoDiscount,
    this.discountId,
    this.discountStoreId,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();
  final CurrencyService _currencyService = CurrencyService();
  final DeliveryFeeService _deliveryFeeService = DeliveryFeeService();
  
  int _selectedAddressIndex = -1;
  bool _showAddressError = false;
  bool _useMyContactDetails = true;
  bool _isProcessing = false;
  GeoPoint? _currentLocation;
  String _userCurrency = 'UGX';
  bool _isLoadingLocation = false;
  String? _locationError;
  List<DeliveryFeeEstimate> _deliveryEstimates = [];
  bool _isCalculatingFees = false;
  
  // Promo code fields
  late String? _promoCode;
  late double? _promoDiscount;
  late String? _discountId;
  late String? _discountStoreId;
  
  // Contact details controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  final List<_DeliveryAddress> _savedAddresses = [];

  @override
  void initState() {
    super.initState();
    _promoCode = widget.promoCode;
    _promoDiscount = widget.promoDiscount;
    _discountId = widget.discountId;
    _discountStoreId = widget.discountStoreId;
    print('🎟️ Checkout received promo data:');
    print('   Code: $_promoCode');
    print('   Discount: $_promoDiscount');
    print('   Discount ID: $_discountId');
    print('   Store ID: $_discountStoreId');
    _loadUserContactDetails();
    _loadUserCurrency();
    _fixCartStoreNames();
    // Calculate delivery fees if location is already set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentLocation != null) {
        _calculateDeliveryFees();
      }
    });
  }

  Future<void> _fixCartStoreNames() async {
    try {
      await _cartService.fixMissingStoreNames();
    } catch (e) {
      print('Error fixing cart store names: $e');
    }
  }

  Future<void> _loadUserCurrency() async {
    final currency = await _currencyService.getUserCurrency(forceRefresh: true);
    if (mounted) {
      setState(() => _userCurrency = currency);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserContactDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Try to get from Firestore first
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          setState(() {
            _nameController.text = userData?['name'] ?? user.displayName ?? '';
            _emailController.text = userData?['email'] ?? user.email ?? '';
            _phoneController.text = userData?['phoneNumber'] ?? user.phoneNumber ?? '';
          });
          return;
        }
      } catch (e) {
        print('Error loading user data from Firestore: $e');
      }
      
      // Fallback to Firebase Auth
      setState(() {
        _nameController.text = user.displayName ?? '';
        _emailController.text = user.email ?? '';
        _phoneController.text = user.phoneNumber ?? '';
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Location services are disabled. Please enable them.';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please enable location services', style: GoogleFonts.poppins()),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            ),
          );
        }
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
            _locationError = 'Location permission denied';
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location permission is required for delivery', style: GoogleFonts.poppins()),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Location permission permanently denied';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please enable location permission in settings', style: GoogleFonts.poppins()),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentLocation = GeoPoint(position.latitude, position.longitude);
        _isLoadingLocation = false;
        _locationError = null;
        
        // Auto-create delivery address from location if none exists
        if (_savedAddresses.isEmpty) {
          _savedAddresses.add(_DeliveryAddress(
            label: 'Current Location',
            street: 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
            city: 'GPS Location',
            icon: Iconsax.gps,
          ));
          _selectedAddressIndex = 0;
          _showAddressError = false;
        }
      });

      // Calculate delivery fees
      _calculateDeliveryFees();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Location captured and delivery address set',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _locationError = 'Failed to get location: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location. Please try again.', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<GeoPoint>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: _currentLocation,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _currentLocation = result;
        _locationError = null;
        
        // Auto-create delivery address from location if none exists
        if (_savedAddresses.isEmpty) {
          _savedAddresses.add(_DeliveryAddress(
            label: 'Selected Location',
            street: 'Lat: ${result.latitude.toStringAsFixed(6)}, Lng: ${result.longitude.toStringAsFixed(6)}',
            city: 'Map Location',
            icon: Iconsax.location,
          ));
          _selectedAddressIndex = 0;
          _showAddressError = false;
        }
      });

      // Calculate delivery fees after state is updated
      await _calculateDeliveryFees();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.tick_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Location set successfully', style: GoogleFonts.poppins()),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _calculateDeliveryFees() async {
    if (_currentLocation == null) {
      print('⚠️ Cannot calculate delivery fees: location is null');
      return;
    }

    print('📍 Calculating delivery fees for location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
    setState(() => _isCalculatingFees = true);

    try {
      // Get all store IDs from cart
      final cartItems = await _cartService.getCartItemsByStoreStream().first;
      final storeIds = cartItems.keys.toList();
      
      print('🛒 Store IDs in cart: $storeIds');

      // Calculate delivery fees for all stores
      final estimates = await _deliveryFeeService.calculateDeliveryFeesForStores(
        storeIds: storeIds,
        buyerLocation: _currentLocation!,
      );

      print('💰 Delivery estimates calculated: ${estimates.length}');
      for (var estimate in estimates) {
        print('  - ${estimate.storeName ?? estimate.storeId}: ${estimate.distance.toStringAsFixed(1)} km = ${estimate.fee.toStringAsFixed(0)} UGX');
        if (estimate.hasError) {
          print('    ❌ Error: ${estimate.error}');
        }
      }

      setState(() {
        _deliveryEstimates = estimates;
        _isCalculatingFees = false;
      });
      
      print('✅ Delivery estimates updated in state');
    } catch (e) {
      print('❌ Error calculating delivery fees: $e');
      setState(() => _isCalculatingFees = false);
    }
  }

  double get _totalDeliveryFee {
    return _deliveryEstimates.fold(0.0, (sum, estimate) => sum + estimate.fee);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: StreamBuilder<Map<String, List<CartItemData>>>(
          stream: _cartService.getCartItemsByStoreStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.black));
            }

            final itemsByStore = snapshot.data ?? {};
            if (itemsByStore.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.grey400),
                    const SizedBox(height: 16),
                    Text('Your cart is empty', style: GoogleFonts.poppins(color: AppColors.grey600)),
                  ],
                ),
              );
            }

            final totalsByStore = _cartService.calculateTotalsByStore(itemsByStore);
            
            // Calculate grand total from all stores
            double grandTotal = 0;
            for (var totals in totalsByStore.values) {
              grandTotal += totals.total;
            }

            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLocationSection(),
                        const SizedBox(height: 24),
                        _buildDeliveryAddressSection(),
                        const SizedBox(height: 24),
                        _buildContactDetailsSection(),
                        const SizedBox(height: 24),
                        _buildOrderSummary(itemsByStore, totalsByStore, grandTotal),
                      ],
                    ),
                  ),
                ),
                _buildPayButton(itemsByStore, totalsByStore),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Iconsax.arrow_left, color: AppColors.black, size: 24),
            ),
          ),
          const Spacer(),
          Text('Checkout', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const Spacer(),
          const SizedBox(width: 40), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final hasLocation = _currentLocation != null;
    final hasError = _locationError != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasLocation 
            ? Colors.green.shade50 
            : (hasError ? Colors.red.shade50 : AppColors.grey100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasLocation 
              ? Colors.green 
              : (hasError ? Colors.red : AppColors.grey300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_isLoadingLocation)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                  ),
                )
              else
                Icon(
                  hasLocation 
                      ? Iconsax.tick_circle5 
                      : (hasError ? Iconsax.close_circle : Iconsax.location),
                  color: hasLocation 
                      ? Colors.green 
                      : (hasError ? Colors.red : AppColors.black),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isLoadingLocation
                      ? 'Getting your location...'
                      : (hasLocation 
                          ? 'Location Captured' 
                          : (hasError ? 'Location Error' : 'Location Required')),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (hasLocation) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Iconsax.gps, size: 14, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}, Lng: ${_currentLocation!.longitude.toStringAsFixed(6)}',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.green.shade700),
                  ),
                ),
              ],
            ),
          ],
          if (!hasLocation && !_isLoadingLocation) ...[
            const SizedBox(height: 8),
            Text(
              hasError 
                  ? _locationError! 
                  : 'We need your location to calculate delivery distance and find the nearest courier',
              style: GoogleFonts.poppins(
                fontSize: 12, 
                color: hasError ? Colors.red.shade700 : AppColors.grey600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openMapPicker,
                icon: const Icon(Iconsax.map, size: 18),
                label: Text(
                  'Set on Map', 
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
          if (hasLocation) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openMapPicker,
                icon: const Icon(Iconsax.map, size: 18),
                label: Text(
                  'Change Location on Map', 
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.black),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactDetailsSection() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _nameController.text.isNotEmpty ? _nameController.text : 'Not set';
    final displayPhone = _phoneController.text.isNotEmpty ? _phoneController.text : 'Not set';
    final displayEmail = _emailController.text.isNotEmpty ? _emailController.text : user?.email ?? 'Not set';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact Details', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _useMyContactDetails,
                    onChanged: (value) => setState(() => _useMyContactDetails = value ?? true),
                    activeColor: AppColors.black,
                  ),
                  Expanded(
                    child: Text(
                      'Use my contact details',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ],
              ),
              if (_useMyContactDetails) ...[
                const SizedBox(height: 12),
                _buildContactInfoRow(Iconsax.user, 'Name', displayName),
                const SizedBox(height: 8),
                _buildContactInfoRow(Iconsax.call, 'Phone', displayPhone),
                const SizedBox(height: 8),
                _buildContactInfoRow(Iconsax.sms, 'Email', displayEmail),
              ],
              if (!_useMyContactDetails) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: GoogleFonts.poppins(),
                    filled: true,
                    fillColor: AppColors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: GoogleFonts.poppins(),
                    filled: true,
                    fillColor: AppColors.white,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: GoogleFonts.poppins(),
                    filled: true,
                    fillColor: AppColors.white,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildContactInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey600),
        const SizedBox(width: 8),
        Text('$label: ', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.grey600)),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('Delivery Address', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Text('*', style: TextStyle(color: Colors.red, fontSize: 16)),
              ],
            ),
            GestureDetector(
              onTap: _showAddNewAddressSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.add, size: 16),
                    const SizedBox(width: 4),
                    Text('Add New', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_showAddressError && _selectedAddressIndex == -1) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.warning_2, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Text('Please select a delivery address', style: GoogleFonts.poppins(fontSize: 12, color: Colors.red)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (_savedAddresses.isEmpty)
          _buildNoAddressCard()
        else
          ..._savedAddresses.asMap().entries.map((entry) => _buildAddressCard(entry.value, entry.key)),
      ],
    );
  }

  Widget _buildNoAddressCard() {
    return GestureDetector(
      onTap: _showAddNewAddressSheet,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.location_add, size: 28),
            ),
            const SizedBox(height: 12),
            Text('Add Delivery Address', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Tap to add your delivery location', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(_DeliveryAddress address, int index) {
    final isSelected = _selectedAddressIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedAddressIndex = index;
        _showAddressError = false;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.grey100 : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.black : AppColors.grey300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.black : AppColors.grey100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(address.icon, color: isSelected ? AppColors.white : AppColors.black, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address.label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(address.street, style: GoogleFonts.poppins(fontSize: 13)),
                  Text(address.city, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600)),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.black : Colors.transparent,
                border: Border.all(color: isSelected ? AppColors.black : AppColors.grey400, width: 2),
              ),
              child: isSelected ? const Icon(Icons.check, size: 14, color: AppColors.white) : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNewAddressSheet() {
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    String selectedLabel = 'Home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Add New Address', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              Text('Label', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.grey600)),
              const SizedBox(height: 8),
              Row(
                children: ['Home', 'Office', 'Other'].map((label) {
                  final isSelected = selectedLabel == label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setSheetState(() => selectedLabel = label),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.black : AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? AppColors.black : AppColors.grey300),
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? AppColors.white : AppColors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Street Address',
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cityController,
                decoration: InputDecoration(
                  labelText: 'City / Region',
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (addressController.text.isNotEmpty && cityController.text.isNotEmpty) {
                      setState(() {
                        _savedAddresses.add(_DeliveryAddress(
                          label: selectedLabel,
                          street: addressController.text,
                          city: cityController.text,
                          icon: selectedLabel == 'Home'
                              ? Iconsax.home_2
                              : selectedLabel == 'Office'
                                  ? Iconsax.building
                                  : Iconsax.location,
                        ));
                        _selectedAddressIndex = _savedAddresses.length - 1;
                        _showAddressError = false;
                      });
                      Navigator.pop(sheetContext);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Save Address', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(
    Map<String, List<CartItemData>> itemsByStore,
    Map<String, CartTotals> totalsByStore,
    double grandTotal,
  ) {
    // Debug logging
    print('🛒 Order Summary Debug:');
    itemsByStore.forEach((storeId, items) {
      print('  Store: $storeId (${items.first.storeName})');
      print('  Items: ${items.length}');
      for (var item in items) {
        print('    - ${item.productName}: ${item.price} x ${item.quantity} = ${item.itemTotal}');
      }
      final totals = totalsByStore[storeId]!;
      print('  Store Total: ${totals.total}');
    });
    print('  Grand Total: $grandTotal');
    print('  Delivery Estimates Count: ${_deliveryEstimates.length}');
    print('  Total Delivery Fee: $_totalDeliveryFee');
    for (var estimate in _deliveryEstimates) {
      print('    - ${estimate.storeName ?? estimate.storeId}: ${estimate.fee} UGX (${estimate.distance} km)');
    }
    
    return FutureBuilder<Map<String, String>>(
      future: _convertAllStoreTotals(itemsByStore, totalsByStore),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.black));
        }
        
        final convertedTotals = snapshot.data!;
        final convertedGrandTotal = convertedTotals['grandTotal']!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Summary', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...itemsByStore.entries.map((entry) {
              final storeName = entry.value.first.storeName;
              final storeId = entry.key;
              final formattedTotal = convertedTotals[storeId] ?? 'Loading...';
              
              // Find delivery estimate for this store
              final deliveryEstimate = _deliveryEstimates.firstWhere(
                (e) => e.storeId == storeId,
                orElse: () => DeliveryFeeEstimate(storeId: storeId, storeName: storeName, distance: 0, fee: 0),
              );
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.store, size: 16),
                        const SizedBox(width: 8),
                        Text(storeName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${entry.value.length} items', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600)),
                        Text(
                          formattedTotal,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (deliveryEstimate.fee > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Iconsax.truck_fast, size: 12, color: AppColors.grey600),
                              const SizedBox(width: 4),
                              Text(
                                'Delivery (${deliveryEstimate.distance.toStringAsFixed(1)} km)',
                                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.grey600),
                              ),
                            ],
                          ),
                          Text(
                            _currencyService.formatPrice(deliveryEstimate.fee, 'UGX'),
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey700, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
            if (_deliveryEstimates.isNotEmpty && _totalDeliveryFee > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.truck_fast, size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Total Delivery Fee',
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange.shade900),
                        ),
                      ],
                    ),
                    Text(
                      _currencyService.formatPrice(_totalDeliveryFee, 'UGX'),
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.orange.shade900),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.grey600)),
                Text(
                  convertedGrandTotal,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (_promoDiscount != null && _promoDiscount! > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_offer, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Promo ($_promoCode)',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                  Text(
                    '-${_currencyService.formatPrice(_promoDiscount!, _userCurrency)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ],
            if (_totalDeliveryFee > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.grey600)),
                  Text(
                    _currencyService.formatPrice(_totalDeliveryFee, 'UGX'),
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Divider(height: 16),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Grand Total', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(
                  _currencyService.formatPrice(
                    double.parse(convertedGrandTotal.replaceAll(RegExp(r'[^0-9.]'), '')) - (_promoDiscount ?? 0) + _totalDeliveryFee,
                    _userCurrency,
                  ),
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
  
  Future<Map<String, String>> _convertAllStoreTotals(
    Map<String, List<CartItemData>> itemsByStore,
    Map<String, CartTotals> totalsByStore,
  ) async {
    final Map<String, String> result = {};
    double grandTotalConverted = 0;
    
    for (var entry in itemsByStore.entries) {
      final storeId = entry.key;
      final storeCurrency = entry.value.first.currency;
      final storeTotal = totalsByStore[storeId]!.total;
      
      // Convert to user currency
      final convertedAmount = _currencyService.convertPrice(
        storeTotal,
        storeCurrency,
        _userCurrency,
      );
      
      grandTotalConverted += convertedAmount;
      result[storeId] = _currencyService.formatPrice(convertedAmount, _userCurrency);
    }
    
    result['grandTotal'] = _currencyService.formatPrice(grandTotalConverted, _userCurrency);
    return result;
  }

  Widget _buildPayButton(
    Map<String, List<CartItemData>> itemsByStore,
    Map<String, CartTotals> totalsByStore,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main Pay Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () => _processOrder(itemsByStore, totalsByStore),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Proceed Transactions',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processOrder(
    Map<String, List<CartItemData>> itemsByStore,
    Map<String, CartTotals> totalsByStore,
  ) async {
    // Validate location
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please allow location access to continue',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Allow',
            textColor: Colors.white,
            onPressed: _requestLocationPermission,
          ),
        ),
      );
      return;
    }

    // Validate address
    if (_selectedAddressIndex == -1) {
      setState(() => _showAddressError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a delivery address', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final selectedAddress = _savedAddresses[_selectedAddressIndex];
      final user = FirebaseAuth.instance.currentUser!;
      
      // Calculate grand total
      double grandTotal = 0;
      for (var totals in totalsByStore.values) {
        grandTotal += totals.total;
      }
      
      // Generate payment hash (dummy for now)
      final paymentHash = 'PAY_${DateTime.now().millisecondsSinceEpoch}_${user.uid.substring(0, 8)}';
      
      // Create payment record
      final paymentRef = await FirebaseFirestore.instance.collection('payments').add({
        'hash': paymentHash,
        'userId': user.uid,
        'amount': grandTotal,
        'currency': _userCurrency,
        'status': 'approved', // Dummy: auto-approve for testing
        'method': 'dummy_payment',
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Create orders with payment reference
      final deliveryFeesByStore = <String, double>{};
      for (var estimate in _deliveryEstimates) {
        deliveryFeesByStore[estimate.storeId] = estimate.fee;
      }
      
      final orderIds = await _orderService.createOrdersFromCart(
        itemsByStore: itemsByStore,
        totalsByStore: totalsByStore,
        deliveryAddress: DeliveryAddress(
          label: selectedAddress.label,
          street: selectedAddress.street,
          city: selectedAddress.city,
        ),
        contactDetails: ContactDetails(
          name: _useMyContactDetails ? (user.displayName ?? _nameController.text) : _nameController.text,
          phone: _useMyContactDetails ? (user.phoneNumber ?? _phoneController.text) : _phoneController.text,
          email: _useMyContactDetails ? (user.email ?? _emailController.text) : _emailController.text,
        ),
        deliveryLocation: _currentLocation,
        deliveryFeesByStore: deliveryFeesByStore,
        paymentId: paymentRef.id,
        paymentHash: paymentHash,
        promoCode: _promoCode,
        promoDiscount: _promoDiscount,
        discountId: _discountId,
        discountStoreId: _discountStoreId,
      );

      // Clear cart
      for (var storeId in itemsByStore.keys) {
        await _cartService.clearStoreCart(storeId);
      }

      if (mounted) {
        setState(() => _isProcessing = false);
        _showSuccessDialog(orderIds.length);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(int orderCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 50),
              ),
              const SizedBox(height: 24),
              Text(
                'Order Successful!',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '$orderCount ${orderCount == 1 ? 'order' : 'orders'} placed successfully',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.grey600),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.go('/home');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.black),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Go Home', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.black)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(); // Close dialog
                        Navigator.of(context).popUntil((route) => route.isFirst); // Go back to MainScreen
                        MainScreen.navigateToOrders(context); // Navigate to orders tab
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('View Orders', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryAddress {
  final String label;
  final String street;
  final String city;
  final IconData icon;

  _DeliveryAddress({
    required this.label,
    required this.street,
    required this.city,
    required this.icon,
  });
}
