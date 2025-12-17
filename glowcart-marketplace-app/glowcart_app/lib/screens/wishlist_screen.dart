import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final List<_WishlistItem> _items = [
    _WishlistItem(id: '1', name: 'Smart Watch Ultra', store: 'TechHub Store', price: 299.99, originalPrice: 399.99, image: '⌚', inStock: true),
    _WishlistItem(id: '2', name: 'Wireless Earbuds Pro', store: 'AudioMax', price: 149.99, originalPrice: 199.99, image: '🎧', inStock: true),
    _WishlistItem(id: '3', name: 'Leather Crossbody Bag', store: 'Urban Style Co', price: 89.99, originalPrice: 129.99, image: '👜', inStock: false),
    _WishlistItem(id: '4', name: 'Running Shoes X1', store: 'SportZone', price: 159.99, originalPrice: 199.99, image: '👟', inStock: true),
    _WishlistItem(id: '5', name: 'Minimalist Desk Lamp', store: 'Home Essentials', price: 49.99, originalPrice: 69.99, image: '💡', inStock: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBeige,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Wishlist', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Iconsax.trash, color: AppColors.textSecondary), onPressed: _clearAll),
        ],
      ),
      body: _items.isEmpty ? _buildEmptyState() : _buildWishlistGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.heart, size: 80, color: AppColors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Your wishlist is empty', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Save items you love for later', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildWishlistGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) => _buildWishlistCard(_items[index]),
    );
  }

  Widget _buildWishlistCard(_WishlistItem item) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(child: Text(item.image, style: const TextStyle(fontSize: 50))),
              ),
              Positioned(
                top: 8, right: 8,
                child: GestureDetector(
                  onTap: () => _removeItem(item.id),
                  child: Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Iconsax.heart5, size: 18, color: AppColors.error),
                  ),
                ),
              ),
              if (!item.inStock)
                Positioned(
                  bottom: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                    child: Text('Out of Stock', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(item.store, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('\$${item.price.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
                    const SizedBox(width: 6),
                    Text('\$${item.originalPrice.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary, decoration: TextDecoration.lineThrough)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity, height: 36,
                  child: ElevatedButton(
                    onPressed: item.inStock ? () => _addToCart(item) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.inStock ? AppColors.darkGreen : AppColors.textSecondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(item.inStock ? 'Add to Cart' : 'Notify Me', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _removeItem(String id) {
    setState(() => _items.removeWhere((item) => item.id == id));
  }

  void _addToCart(_WishlistItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} added to cart'), backgroundColor: AppColors.darkGreen),
    );
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Wishlist?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Remove all items from your wishlist?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary))),
          TextButton(onPressed: () { setState(() => _items.clear()); Navigator.pop(context); }, child: Text('Clear', style: GoogleFonts.poppins(color: AppColors.error))),
        ],
      ),
    );
  }
}

class _WishlistItem {
  final String id, name, store, image;
  final double price, originalPrice;
  final bool inStock;
  _WishlistItem({required this.id, required this.name, required this.store, required this.price, required this.originalPrice, required this.image, required this.inStock});
}
