import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../data/dummy_data.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String selectedPayment = 'card';
  final subtotal = 879.97;
  final shipping = 0.0;
  final tax = 70.40;
  double get total => subtotal + shipping + tax;

  void _showOrderPlaced() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.check_circle, color: AppColors.success, size: 48),
        title: const Text('Order Placed!'),
        content: const Text('Your order has been placed successfully. You will receive a confirmation email shortly.', textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
            },
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = DummyData.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: TextStyle(color: AppColors.textSecondary)),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showOrderPlaced,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Place Order'),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Shipping Address
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Text('Shipping Address', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      TextButton(onPressed: () {}, child: Text('Change', style: TextStyle(color: AppColors.primary))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(user.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  if (user.addresses.isNotEmpty) ...[
                    Text(user.addresses.first.street, style: TextStyle(color: AppColors.textSecondary)),
                    Text('${user.addresses.first.city}, ${user.addresses.first.state} ${user.addresses.first.postalCode}', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                  if (user.phone != null) Text(user.phone!, style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Payment Method
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.payment_outlined, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PaymentOption(
                    icon: Icons.credit_card_outlined,
                    title: 'Credit/Debit Card',
                    subtitle: '**** **** **** 4242',
                    isSelected: selectedPayment == 'card',
                    onTap: () => setState(() => selectedPayment = 'card'),
                  ),
                  const SizedBox(height: 8),
                  _PaymentOption(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Mobile Money',
                    subtitle: 'MTN, Airtel, etc.',
                    isSelected: selectedPayment == 'mobile',
                    onTap: () => setState(() => selectedPayment = 'mobile'),
                  ),
                  const SizedBox(height: 8),
                  _PaymentOption(
                    icon: Icons.local_atm_outlined,
                    title: 'Cash on Delivery',
                    subtitle: 'Pay when you receive',
                    isSelected: selectedPayment == 'cod',
                    onTap: () => setState(() => selectedPayment = 'cod'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Order Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_outlined, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow('Subtotal (3 items)', '\$${subtotal.toStringAsFixed(2)}'),
                  _SummaryRow('Shipping', shipping == 0 ? 'FREE' : '\$${shipping.toStringAsFixed(2)}', valueColor: shipping == 0 ? AppColors.success : null),
                  _SummaryRow('Tax', '\$${tax.toStringAsFixed(2)}'),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('\$${total.toStringAsFixed(2)}', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: TextStyle(color: valueColor)),
        ],
      ),
    );
  }
}
