import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';
import 'checkout_screen.dart';
import 'order_history_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final TextEditingController _promoController = TextEditingController();
  bool _promoApplied = false;
  String _appliedPromo = '';

  final List<_CartItem> _cartItems = [
    _CartItem(
      id: '1',
      name: 'Smart Watch WH22-6 Fitness Tracker',
      variant: '44mm / Gray',
      price: 154.97,
      quantity: 1,
      image: 'watch',
      storeName: 'TechZone',
      rating: 4.9,
      reviews: 1265,
    ),
    _CartItem(
      id: '2',
      name: 'Premium Boxing Gloves Pro',
      variant: '12oz / White',
      price: 48.99,
      quantity: 2,
      image: 'gloves',
      storeName: 'SportsPro',
      rating: 4.8,
      reviews: 892,
    ),
  ];

  double get orderAmount => _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get promoDiscount => _promoApplied ? 2.20 : 0;
  double get delivery => 6.00;
  double get tax => 2.00;
  double get totalAmount => orderAmount - promoDiscount + delivery + tax;

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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._cartItems.map((item) => _buildCartItem(item)),
                    const SizedBox(height: 20),
                    _buildPromoCode(),
                    const SizedBox(height: 24),
                    _buildOrderSummary(),
                  ],
                ),
              ),
            ),
            _buildBottomButton(),
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
          Text(
            'My Cart',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: context.textPrimaryColor,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              // Navigate to order history
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.receipt_2, size: 16, color: context.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'Orders',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(_CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: context.surfaceVariantColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                item.image == 'watch' ? Iconsax.watch : Iconsax.box,
                size: 40,
                color: context.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Iconsax.clock, size: 12, color: context.textSecondaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '15-20 min',
                      style: GoogleFonts.poppins(fontSize: 11, color: context.textSecondaryColor),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Iconsax.star1, size: 12, color: Color(0xFFFFB800)),
                    const SizedBox(width: 4),
                    Text(
                      '${item.rating}',
                      style: GoogleFonts.poppins(fontSize: 11, color: context.textSecondaryColor),
                    ),
                    Text(
                      ' (${item.reviews})',
                      style: GoogleFonts.poppins(fontSize: 11, color: context.textSecondaryColor.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '\$',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    Text(
                      item.price.toStringAsFixed(2),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    _buildQuantitySelector(item),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(_CartItem item) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceVariantColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (item.quantity > 1) {
                setState(() => item.quantity--);
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: context.surfaceColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.remove, size: 16, color: context.textPrimaryColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${item.quantity}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => item.quantity++),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: context.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, size: 16, color: context.isDark ? Colors.black : Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCode() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _promoController,
              enabled: !_promoApplied,
              style: GoogleFonts.poppins(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: _promoApplied ? _appliedPromo : 'Enter promo code',
                hintStyle: GoogleFonts.poppins(
                  color: _promoApplied ? context.textPrimaryColor : context.textSecondaryColor,
                  fontSize: 14,
                  fontWeight: _promoApplied ? FontWeight.w500 : FontWeight.w400,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (_promoApplied)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Promo-code Confirmed',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.isDark ? Colors.black : Colors.white,
              ),
            ),
          )
        else
          GestureDetector(
            onTap: _applyPromo,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: context.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Apply',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.isDark ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _applyPromo() {
    if (_promoController.text.isNotEmpty) {
      setState(() {
        _promoApplied = true;
        _appliedPromo = _promoController.text.toUpperCase();
      });
    }
  }

  Widget _buildOrderSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildSummaryRow('Order Amount', orderAmount),
        if (_promoApplied) _buildSummaryRow('Promo-code', -promoDiscount, isDiscount: true),
        _buildSummaryRow('Delivery', delivery),
        _buildSummaryRow('Tax', tax),
        const SizedBox(height: 12),
        Container(height: 1, color: context.borderColor),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Amount',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
            Row(
              children: [
                Text(
                  '\$ ',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.primaryColor,
                  ),
                ),
                Text(
                  totalAmount.toStringAsFixed(2),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
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
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: context.textSecondaryColor,
            ),
          ),
          Text(
            '${isDiscount ? "-" : ""}\$ ${amount.abs().toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDiscount ? context.primaryColor : context.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckoutScreen(
                  orderAmount: orderAmount,
                  promoDiscount: promoDiscount,
                  delivery: delivery,
                  tax: tax,
                  totalAmount: totalAmount,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: context.primaryColor,
            foregroundColor: context.isDark ? Colors.black : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            'Proceed Transactions',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _CartItem {
  final String id;
  final String name;
  final String variant;
  final double price;
  int quantity;
  final String image;
  final String storeName;
  final double rating;
  final int reviews;

  _CartItem({
    required this.id,
    required this.name,
    required this.variant,
    required this.price,
    required this.quantity,
    required this.image,
    required this.storeName,
    required this.rating,
    required this.reviews,
  });
}
