import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/currency_service.dart';
import 'order_history_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();
  final CurrencyService _currencyService = CurrencyService();
  
  int _selectedAddressIndex = -1;
  bool _showAddressError = false;
  bool _useMyContactDetails = true;
  bool _isProcessing = false;
  GeoPoint? _currentLocation;
  String _userCurrency = 'UGX';
  
  // Contact details controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  final List<_DeliveryAddress> _savedAddresses = [];

  @override
  void initState() {
    super.initState();
    _loadUserContactDetails();
    _loadUserCurrency();
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
      setState(() {
        _nameController.text = user.displayName ?? '';
        _emailController.text = user.email ?? '';
        _phoneController.text = user.phoneNumber ?? '';
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    // Simulate location permission - in production use geolocator package
    setState(() {
      _currentLocation = const GeoPoint(0.3476, 32.5825); // Kampala coordinates
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location access granted', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
    }
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
            final grandTotal = totalsByStore.values.fold<double>(
              0,
              (sum, totals) => sum + totals.total,
            );

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
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Iconsax.arrow_left, color: AppColors.black),
          ),
          const Spacer(),
          Text('Checkout', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const Spacer(),
          const SizedBox(width: 24), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _currentLocation != null ? Colors.green.shade50 : AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _currentLocation != null ? Colors.green : AppColors.grey300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _currentLocation != null ? Iconsax.tick_circle5 : Iconsax.location,
                color: _currentLocation != null ? Colors.green : AppColors.black,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _currentLocation != null ? 'Location Access Granted' : 'Location Permission Required',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (_currentLocation == null) ...[
            const SizedBox(height: 8),
            Text(
              'We need your location to find the nearest pickup point',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _requestLocationPermission,
                icon: const Icon(Iconsax.gps, size: 18),
                label: Text('Allow Location Access', style: GoogleFonts.poppins(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactDetailsSection() {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Summary', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        ...itemsByStore.entries.map((entry) {
          final storeName = entry.value.first.storeName;
          final totals = totalsByStore[entry.key]!;
          
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
                      _currencyService.formatPrice(totals.total, _userCurrency),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Grand Total', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(
              _currencyService.formatPrice(grandTotal, _userCurrency),
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
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
          // TEST MODE: Skip Payment Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isProcessing ? null : () => _processOrder(itemsByStore, totalsByStore),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Skip Payment (Test Mode)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Regular Pay Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: null, // Disabled for now
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.grey300,
                foregroundColor: AppColors.grey600,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Pay with Pesapal (Coming Soon)',
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
    // TEST MODE: Skip validation for location and address
    // Auto-fill with dummy data if missing
    if (_currentLocation == null) {
      setState(() {
        _currentLocation = const GeoPoint(0.3476, 32.5825); // Kampala
      });
    }

    if (_selectedAddressIndex == -1 && _savedAddresses.isEmpty) {
      setState(() {
        _savedAddresses.add(_DeliveryAddress(
          label: 'Test Address',
          street: 'Test Street, Building 1',
          city: 'Kampala, Uganda',
          icon: Iconsax.location,
        ));
        _selectedAddressIndex = 0;
      });
    }

    setState(() => _isProcessing = true);

    try {
      final selectedAddress = _savedAddresses[_selectedAddressIndex];
      final user = FirebaseAuth.instance.currentUser!;

      // Create orders
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
                        context.go('/orders'); // Replace entire stack with orders screen
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
