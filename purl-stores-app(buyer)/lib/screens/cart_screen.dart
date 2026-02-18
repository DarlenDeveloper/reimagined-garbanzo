import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../services/cart_service.dart';
import '../services/currency_service.dart';
import '../services/discount_service.dart';
import 'order_history_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final CurrencyService _currencyService = CurrencyService();
  final DiscountService _discountService = DiscountService();
  final TextEditingController _promoController = TextEditingController();
  
  bool _promoApplied = false;
  String _appliedPromo = '';
  Discount? _appliedDiscount;
  bool _isValidatingPromo = false;
  String _userCurrency = 'KES';
  
  // Cache the last known cart data to prevent flickering
  Map<String, List<CartItemData>>? _cachedCartData;

  @override
  void initState() {
    super.initState();
    _loadUserCurrency();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload currency when screen comes back into focus
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
            // Use cached data if available to prevent flickering
            final itemsByStore = snapshot.hasData ? snapshot.data! : (_cachedCartData ?? {});
            
            // Update cache when new data arrives
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              _cachedCartData = snapshot.data;
            }
            
            final allItems = itemsByStore.values.expand((items) => items).toList();

            if (allItems.isEmpty && snapshot.connectionState != ConnectionState.waiting) {
              return _buildEmptyCart();
            }
            
            if (allItems.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final totals = _cartService.calculateTotals(allItems);
            
            // Convert all amounts to user's currency (use cached currency)
            double convertedSubtotal = 0;
            for (var item in allItems) {
              final itemTotal = item.itemTotal;
              convertedSubtotal += _currencyService.convertPrice(itemTotal, item.currency, _userCurrency);
            }
            
            // Calculate discount
            double promoDiscount = 0.0;
            if (_promoApplied && _appliedDiscount != null) {
              promoDiscount = _appliedDiscount!.calculateDiscount(convertedSubtotal);
              // Ensure discount doesn't exceed subtotal
              if (promoDiscount > convertedSubtotal) {
                promoDiscount = convertedSubtotal;
              }
            }
            
            final delivery = totals.shipping.toDouble();
            final tax = 0.0;
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
                        _buildOrderSummary(convertedSubtotal, promoDiscount, delivery, tax, totalAmount, _userCurrency),
                      ],
                    ),
                  ),
                ),
                _buildBottomButton(),
              ],
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
        
        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.delete_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 4),
                Text(
                  'Delete',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'Remove Item',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  content: Text(
                    'Are you sure you want to remove "${item.productName}" from your cart?',
                    style: GoogleFonts.poppins(
                      color: context.textSecondaryColor,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        'Remove',
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) async {
            try {
              await _cartService.removeFromCart(item.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Removed from cart',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.black,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to remove item',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
          child: TextField(
            controller: _promoController,
            enabled: !_promoApplied,
            style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: _promoApplied ? _appliedPromo : 'Promo code',
              hintStyle: GoogleFonts.poppins(
                color: _promoApplied ? context.textPrimaryColor : Colors.grey.shade400,
                fontSize: 14,
                fontWeight: _promoApplied ? FontWeight.w500 : FontWeight.w400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              filled: false,
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
            onTap: _isValidatingPromo ? null : _applyPromo,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _isValidatingPromo ? Colors.grey : context.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isValidatingPromo
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
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

  void _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a promo code', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isValidatingPromo = true);

    try {
      // Get cart items to find store IDs
      final itemsByStore = await _cartService.getCartItemsByStoreStream().first;
      
      if (itemsByStore.isEmpty) {
        throw Exception('Cart is empty');
      }

      // For now, we'll validate against the first store in cart
      // In a multi-store cart, you'd need to handle this differently
      final storeId = itemsByStore.keys.first;
      
      final discount = await _discountService.validateDiscountCode(storeId, code);

      if (discount == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid or expired promo code', style: GoogleFonts.poppins()),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isValidatingPromo = false);
        return;
      }

      // Apply discount
      setState(() {
        _promoApplied = true;
        _appliedPromo = code.toUpperCase();
        _appliedDiscount = discount;
        _isValidatingPromo = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Promo code applied successfully!', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying promo code', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isValidatingPromo = false);
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
    final isFree = amount == 0;
    final isDelivery = label == 'Delivery';
    
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
          Row(
            children: [
              if (isDelivery && isFree) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade50, Colors.green.shade100],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300, width: 1),
                  ),
                  child: Text(
                    'ON US',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                isFree 
                    ? 'FREE' 
                    : '${isDiscount ? "-" : ""}${_currencyService.formatPrice(amount.abs(), currency)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isFree 
                      ? Colors.green 
                      : (isDiscount ? context.primaryColor : context.textPrimaryColor),
                ),
              ),
            ],
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
          onPressed: () => context.push('/checkout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.primaryColor,
            foregroundColor: context.isDark ? Colors.black : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
