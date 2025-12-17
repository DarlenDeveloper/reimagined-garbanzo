import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';

class CheckoutScreen extends StatefulWidget {
  final double orderAmount;
  final double promoDiscount;
  final double delivery;
  final double tax;
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.orderAmount,
    required this.promoDiscount,
    required this.delivery,
    required this.tax,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedPaymentIndex = 0;
  int _selectedAddressIndex = -1;
  bool _showAddressError = false;

  final List<_PaymentMethod> _paymentMethods = [
    _PaymentMethod(name: 'Master Card', detail: '******** 8463', icon: 'mastercard', color: const Color(0xFFEB001B)),
    _PaymentMethod(name: 'Paypal', detail: 'ord*****@gmail.com', icon: 'paypal', color: const Color(0xFF003087)),
    _PaymentMethod(name: 'Mobile Money', detail: '+256 7** *** **9', icon: 'mobile', color: const Color(0xFFFFB800)),
    _PaymentMethod(name: 'Buy Now Pay Later', detail: 'Pay in 4 installments', icon: 'bnpl', color: const Color(0xFF8B5CF6)),
  ];

  final List<_DeliveryAddress> _savedAddresses = [
    _DeliveryAddress(label: 'Home', address: '11/2 Diriyah, Road no A3', city: 'Riyadh (SA)', icon: Iconsax.home_2),
    _DeliveryAddress(label: 'Office', address: '45 Business Park, Tower B', city: 'Riyadh (SA)', icon: Iconsax.building),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDeliveryAddressSection(),
                    const SizedBox(height: 24),
                    _buildPaymentMethods(),
                    const SizedBox(height: 16),
                    _buildAddPaymentMethod(),
                    const SizedBox(height: 24),
                    _buildOrderSummary(),
                  ],
                ),
              ),
            ),
            _buildPayButton(),
          ],
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
            onTap: () => Navigator.pop(context),
            child: Icon(Iconsax.arrow_left, color: context.textPrimaryColor),
          ),
          const Spacer(),
          Text('Checkout', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
          const Spacer(),
          Icon(Iconsax.more, color: context.textPrimaryColor),
        ],
      ),
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
                Text('Delivery Address', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                const SizedBox(width: 4),
                Text('*', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.error)),
              ],
            ),
            GestureDetector(
              onTap: _showAddNewAddressSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: context.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.add, size: 16, color: context.primaryColor),
                    const SizedBox(width: 4),
                    Text('Add New', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: context.primaryColor)),
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
            decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Iconsax.warning_2, size: 16, color: AppColors.error),
                const SizedBox(width: 8),
                Text('Please select a delivery address', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.error)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: context.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Iconsax.location_add, color: context.primaryColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text('Add Delivery Address', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
            const SizedBox(height: 4),
            Text('Tap to add your delivery location', style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(_DeliveryAddress address, int index) {
    final isSelected = _selectedAddressIndex == index;
    final isDark = context.isDark;
    return GestureDetector(
      onTap: () => setState(() { _selectedAddressIndex = index; _showAddressError = false; }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkGreen.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.darkGreen : AppColors.darkGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(address.icon, color: isSelected ? Colors.white : AppColors.darkGreen, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(address.label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: context.primaryColor, borderRadius: BorderRadius.circular(10)),
                          child: Text('Selected', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: isDark ? Colors.black : Colors.white)),
                        ),
                      ],
                    ],
                  ),
                  Text(address.address, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary)),
                  Text(address.city, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.darkGreen : AppColors.surfaceVariant,
              ),
              child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
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

    final isDark = context.isDark;
    final primaryCol = isDark ? AppColors.limeAccent : AppColors.darkGreen;
    final surfaceCol = isDark ? AppColors.darkSurface : Colors.white;
    final surfaceVarCol = isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF5F0E8);
    final textPrimCol = isDark ? Colors.white : AppColors.textPrimary;
    final textSecCol = isDark ? Colors.white60 : AppColors.textSecondary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
          decoration: BoxDecoration(color: surfaceCol, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: borderCol, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Add New Address', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimCol)),
              const SizedBox(height: 20),
              Text('Label', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: textSecCol)),
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
                          color: isSelected ? primaryCol : surfaceCol,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? primaryCol : borderCol),
                        ),
                        child: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? (isDark ? Colors.black : Colors.white) : textPrimCol)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Street Address', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: textSecCol)),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                style: GoogleFonts.poppins(color: textPrimCol),
                decoration: InputDecoration(
                  hintText: 'Enter your street address',
                  hintStyle: GoogleFonts.poppins(fontSize: 14, color: textSecCol),
                  filled: true, fillColor: surfaceVarCol,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              Text('City / Region', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: textSecCol)),
              const SizedBox(height: 8),
              TextField(
                controller: cityController,
                style: GoogleFonts.poppins(color: textPrimCol),
                decoration: InputDecoration(
                  hintText: 'Enter city or region',
                  hintStyle: GoogleFonts.poppins(fontSize: 14, color: textSecCol),
                  filled: true, fillColor: surfaceVarCol,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () { addressController.text = '123 Current Location St'; cityController.text = 'Kampala (UG)'; },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: primaryCol.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.gps, size: 20, color: primaryCol),
                      const SizedBox(width: 8),
                      Text('Use Current Location', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: primaryCol)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (addressController.text.isNotEmpty && cityController.text.isNotEmpty) {
                      setState(() {
                        _savedAddresses.add(_DeliveryAddress(
                          label: selectedLabel, address: addressController.text, city: cityController.text,
                          icon: selectedLabel == 'Home' ? Iconsax.home_2 : selectedLabel == 'Office' ? Iconsax.building : Iconsax.location,
                        ));
                        _selectedAddressIndex = _savedAddresses.length - 1;
                        _showAddressError = false;
                      });
                      Navigator.pop(sheetContext);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryCol, foregroundColor: isDark ? Colors.black : Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text('Save Address', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        const SizedBox(height: 12),
        ...List.generate(_paymentMethods.length, (index) => _buildPaymentOption(_paymentMethods[index], index)),
      ],
    );
  }

  Widget _buildPaymentOption(_PaymentMethod method, int index) {
    final isSelected = _selectedPaymentIndex == index;
    final isDark = context.isDark;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? context.primaryColor : context.borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            _buildPaymentIcon(method),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                  if (method.detail.isNotEmpty) Text(method.detail, style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondaryColor)),
                ],
              ),
            ),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? context.primaryColor : Colors.transparent,
                border: Border.all(color: isSelected ? context.primaryColor : context.borderColor, width: 2),
              ),
              child: isSelected ? Icon(Icons.check, size: 14, color: isDark ? Colors.black : Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentIcon(_PaymentMethod method) {
    IconData icon;
    switch (method.icon) {
      case 'mastercard': icon = Iconsax.card; break;
      case 'paypal': icon = Iconsax.wallet; break;
      case 'mobile': icon = Iconsax.mobile; break;
      case 'bnpl': icon = Iconsax.calendar_tick; break;
      default: icon = Iconsax.card;
    }
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: method.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: method.color, size: 22),
    );
  }

  Widget _buildAddPaymentMethod() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.borderColor)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.add, size: 20, color: context.textSecondaryColor),
          const SizedBox(width: 8),
          Text('Add Payment Method', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: context.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Summary', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        const SizedBox(height: 16),
        _buildSummaryRow('Order Amount', widget.orderAmount),
        if (widget.promoDiscount > 0) _buildSummaryRow('Promo-code', -widget.promoDiscount, isDiscount: true),
        _buildSummaryRow('Delivery', widget.delivery),
        _buildSummaryRow('Tax', widget.tax),
        const SizedBox(height: 12),
        Container(height: 1, color: context.borderColor),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total Amount', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
            Row(
              children: [
                Text('\$ ', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: context.primaryColor)),
                Text(widget.totalAmount.toStringAsFixed(2), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: context.textPrimaryColor)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 14, color: context.textSecondaryColor)),
          Text('${isDiscount ? "-" : ""}\$ ${amount.abs().toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: isDiscount ? context.primaryColor : context.textPrimaryColor)),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SizedBox(
        width: double.infinity, height: 54,
        child: ElevatedButton(
          onPressed: () {
            if (_selectedAddressIndex == -1) { setState(() => _showAddressError = true); return; }
            _showSuccessDialog();
          },
          style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor, foregroundColor: isDark ? Colors.black : Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: Text('Pay Now', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    final isDark = context.isDark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: (isDark ? AppColors.limeAccent : AppColors.darkGreen).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Center(
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: isDark ? AppColors.limeAccent : AppColors.darkGreen, shape: BoxShape.circle),
                    child: Icon(Icons.check, color: isDark ? Colors.black : Colors.white, size: 32),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Order Successful!', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text("We're preparing your\norder. See updates in Delivery.", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.white60 : AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(backgroundColor: isDark ? AppColors.limeAccent : AppColors.darkGreen, foregroundColor: isDark ? Colors.black : Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('Go Home', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).popUntil((route) => route.isFirst),
                child: Text('Track your order', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white60 : AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethod {
  final String name;
  final String detail;
  final String icon;
  final Color color;
  _PaymentMethod({required this.name, required this.detail, required this.icon, required this.color});
}

class _DeliveryAddress {
  final String label;
  final String address;
  final String city;
  final IconData icon;
  _DeliveryAddress({required this.label, required this.address, required this.city, required this.icon});
}
