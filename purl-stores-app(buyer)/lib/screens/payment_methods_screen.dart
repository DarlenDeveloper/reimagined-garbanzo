import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  int _selectedIndex = 0;
  final List<_PaymentMethod> _methods = [
    _PaymentMethod(id: '1', type: 'card', name: 'Mastercard', detail: '•••• 4532', expiry: '12/26', isDefault: true),
    _PaymentMethod(id: '2', type: 'card', name: 'Visa', detail: '•••• 8891', expiry: '08/25', isDefault: false),
    _PaymentMethod(id: '3', type: 'paypal', name: 'PayPal', detail: 'john.doe@email.com', expiry: '', isDefault: false),
    _PaymentMethod(id: '4', type: 'mobile', name: 'Mobile Money', detail: '+1 234 567 8900', expiry: '', isDefault: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBeige,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Payment Methods', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _methods.length,
        itemBuilder: (context, index) => _buildPaymentCard(_methods[index], index),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _addNewMethod,
            icon: const Icon(Iconsax.add),
            label: Text('Add Payment Method', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(_PaymentMethod method, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: _getMethodColor(method.type).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(_getMethodIcon(method.type), color: _getMethodColor(method.type), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(method.name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      if (method.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.darkGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text('Default', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.darkGreen)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(method.detail, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
                  if (method.expiry.isNotEmpty) Text('Expires ${method.expiry}', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? AppColors.darkGreen : AppColors.surfaceVariant),
              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMethodIcon(String type) {
    switch (type) {
      case 'card': return Iconsax.card;
      case 'paypal': return Iconsax.wallet_3;
      case 'mobile': return Iconsax.mobile;
      default: return Iconsax.card;
    }
  }

  Color _getMethodColor(String type) {
    switch (type) {
      case 'card': return const Color(0xFFEB001B);
      case 'paypal': return const Color(0xFF003087);
      case 'mobile': return const Color(0xFFFFB800);
      default: return AppColors.darkGreen;
    }
  }

  void _addNewMethod() {}
}

class _PaymentMethod {
  final String id, type, name, detail, expiry;
  final bool isDefault;
  _PaymentMethod({required this.id, required this.type, required this.name, required this.detail, required this.expiry, required this.isDefault});
}
