import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../data/dummy_data.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool isFavorite = false;
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = DummyData.products.firstWhere((p) => p.id == widget.productId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? AppColors.favoriteActive : null,
            ),
            onPressed: () => setState(() => isFavorite = !isFavorite),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Text(
                  '\$${(product.price * quantity).toStringAsFixed(2)}',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text('Add to Cart'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        children: [
          // Image
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Container(
                  color: AppColors.surfaceVariant,
                  child: Center(
                    child: Text(
                      product.name.substring(0, 2).toUpperCase(),
                      style: TextStyle(fontSize: 64, color: AppColors.primary.withOpacity(0.2)),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(product.category, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ),
          // Info
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.vendorName, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: AppColors.warning, size: 18),
                    const SizedBox(width: 4),
                    Text('${product.rating}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(' (${product.reviewCount} reviews)', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Quantity
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() { if (quantity > 1) quantity--; }),
                      icon: const Icon(Icons.remove),
                      style: IconButton.styleFrom(backgroundColor: AppColors.surfaceVariant),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    IconButton(
                      onPressed: () => setState(() => quantity++),
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(backgroundColor: AppColors.accent),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('About this product', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(product.description, style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Specs
          if (product.specs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Specifications', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...product.specs.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: TextStyle(color: AppColors.textSecondary)),
                        Text(e.value, style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
