import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/colors.dart';
import '../services/cart_service.dart';
import '../services/currency_service.dart';
import 'order_history_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final CurrencyService _currencyService = CurrencyService();
  final TextEditingController _promoController = TextEditingController();
  
  bool _promoApplied = false;
  String _appliedPromo = '';
  String _userCurrency = 'KES';

  @override
  void initState() {
    super.initState();
    _loadUserCurrency();
  }

  Future<void> _loadUserCurrency() async {
    final currency = await _currencyService.getUserCurrency();
    if (mounted) {
      setState(() => _userCurrency = currency);
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: StreamBuilder<Map<String, List<CartItemData>>>(
          stream: _cartService.getCartItemsByStoreStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final itemsByStore = snapshot.data ?? {};
            final allItems = itemsByStore.values.expand((items) => items).toList();

            if (allItems.isEmpty) {
              return _buildEmptyCart();
            }

            final totals = _cartService.calculateTotals(allItems);
            
            // Get user currency for conversion
            return FutureBuilder<String>(
              future: _currencyService.getUserCurrency(),
              builder: (context, currencySnapshot) {
                if (!currencySnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final userCurrency = currencySnapshot.data!;
                
                // Convert all amounts to user's currency
                double convertedSubtotal = 0;
                for (var item in allItems) {
                  final itemTotal = item.price * item.quantity;
                  convertedSubtotal += _currencyService.convertPrice(itemTotal, item.currency, userCurrency);
                }
                
                final promoDiscount = _promoApplied ? 2.20 : 0.0;
                final delivery = totals.shipping.toDouble();
                final tax = 2.00;
                final totalAmount = convertedSubtotal - promoDiscount + delivery + tax;

                return Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...allItems.map((item) => _buildCartItem(item)),
                            const SizedBox(height: 20),
                            _buildPromoCode(),
                            const SizedBox(height: 24),
                            _buildOrderSummary(convertedSubtotal, promoDiscount, delivery, tax, totalAmount, userCurrency),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomButton(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: context.textSecondaryColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: GoogleFonts.poppins(color: context.textSecondaryColor, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Add items to get started', style: GoogleFonts.poppins(color: context.textSecondaryColor.withValues(alpha: 0.7))),
        ],
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

  Widget _buildCartItem(CartItemData item) {
    return FutureBuilder<String>(
      future: _currencyService.formatPriceWithConversion(item.price, item.currency),
      builder: (context, priceSnapshot) {
        final formattedPrice = priceSnapshot.data ?? '${item.currency} ${item.price.toStringAsFixed(2)}';
        
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
                child: item.productImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: item.productImage,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: Icon(Iconsax.box, size: 40, color: context.primaryColor),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Icon(Iconsax.box, size: 40, color: context.primaryColor),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(Iconsax.box, size: 40, color: context.primaryColor),
                      ),
              ),
              const SizedBox(width: 12),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
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
                          '4.9',
                          style: GoogleFonts.poppins(fontSize: 11, color: context.textSecondaryColor),
                        ),
                        Text(
                          ' (1265)',
                          style: GoogleFonts.poppins(fontSize: 11, color: context.textSecondaryColor.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          formattedPrice,
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
      },
    );
  }

  Widget _buildQuantitySelector(CartItemData item) {
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
                _cartService.updateQuantity(item.id, item.quantity - 1);
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
            onTap: () => _cartService.updateQuantity(item.id, item.quantity + 1),
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

  Widget _buildOrderSummary(double orderAmount, double promoDiscount, double delivery, double tax, double totalAmount, String userCurrency) {
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
        _buildSummaryRow('Order Amount', orderAmount, userCurrency),
        if (_promoApplied) _buildSummaryRow('Promo-code', -promoDiscount, userCurrency, isDiscount: true),
        _buildSummaryRow('Delivery', delivery, userCurrency),
        _buildSummaryRow('Tax', tax, userCurrency),
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
            Text(
              _currencyService.formatPrice(totalAmount, userCurrency),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, String currency, {bool isDiscount = false}) {
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
            '${isDiscount ? "-" : ""}${_currencyService.formatPrice(amount.abs(), currency)}',
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
          onPressed: () => Navigator.pushNamed(context, '/checkout'),
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
