import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/wishlist_service.dart';
import '../services/currency_service.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final WishlistService _wishlistService = WishlistService();
  final CurrencyService _currencyService = CurrencyService();
  
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left, color: Color(0xFF1a1a1a)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Wishlist', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1a1a1a))),
          centerTitle: true,
        ),
        body: Center(
          child: Text('Please sign in to view wishlist', style: GoogleFonts.poppins(color: Colors.grey)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Color(0xFF1a1a1a)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Wishlist', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1a1a1a))),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.trash, color: Color(0xFFfb2a0a)),
            onPressed: _clearAll,
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _wishlistService.getWishlist(_userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFfb2a0a)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final items = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildWishlistCard(items[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.heart, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Your wishlist is empty', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1a1a1a))),
          const SizedBox(height: 8),
          Text('Save items you love for later', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildWishlistCard(Map<String, dynamic> item) {
    final productId = item['productId'] as String;
    final storeId = item['storeId'] as String;
    final productName = item['productName'] as String;
    final storeName = item['storeName'] as String;
    final price = (item['price'] as num).toDouble();
    final currency = item['currency'] as String;
    final productImage = item['productImage'] as String?;
    final isInStock = item['isInStock'] as bool? ?? true;
    
    final formattedPrice = _currencyService.formatPrice(price, currency);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              productId: productId,
              storeId: storeId,
              productName: productName,
              storeName: storeName,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: productImage != null && productImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: CachedNetworkImage(
                            imageUrl: productImage,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: Icon(Iconsax.box, size: 40, color: Colors.grey[400]),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(Iconsax.box, size: 40, color: Colors.grey[400]),
                            ),
                          ),
                        )
                      : Center(child: Icon(Iconsax.box, size: 40, color: Colors.grey[400])),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _removeItem(productId),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.heart5, size: 18, color: Color(0xFFfb2a0a)),
                    ),
                  ),
                ),
                if (!isInStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Out of Stock',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1a1a1a),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1a1a1a),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formattedPrice,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1a1a1a),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeItem(String productId) async {
    if (_userId == null) return;
    
    await _wishlistService.removeFromWishlist(
      userId: _userId!,
      productId: productId,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from wishlist', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFfb2a0a),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _clearAll() async {
    if (_userId == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Wishlist', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Remove all items from your wishlist?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear', style: GoogleFonts.poppins(color: const Color(0xFFfb2a0a))),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _wishlistService.clearWishlist(_userId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wishlist cleared', style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFFfb2a0a),
          ),
        );
      }
    }
  }
}
