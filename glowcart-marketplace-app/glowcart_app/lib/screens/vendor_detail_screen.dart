import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../data/dummy_data.dart';
import '../widgets/product_card.dart';

class VendorDetailScreen extends StatefulWidget {
  final String vendorId;
  const VendorDetailScreen({super.key, required this.vendorId});

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  late bool isFollowing;

  @override
  void initState() {
    super.initState();
    final vendor = DummyData.vendors.firstWhere((v) => v.id == widget.vendorId);
    isFollowing = vendor.isFollowing;
  }

  @override
  Widget build(BuildContext context) {
    final vendor = DummyData.vendors.firstWhere((v) => v.id == widget.vendorId);
    final vendorProducts = DummyData.products.where((p) => p.vendorId == widget.vendorId).toList();

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      vendor.name.substring(0, 2).toUpperCase(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(vendor.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (vendor.isVerified) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.verified, color: AppColors.primary, size: 20),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(vendor.location, style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(value: '${vendor.productCount}', label: 'Products'),
                    _StatItem(value: '${vendor.followerCount}', label: 'Followers'),
                    _StatItem(value: '${vendor.rating}', label: 'Rating'),
                  ],
                ),
                const SizedBox(height: 16),
                // Follow Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => isFollowing = !isFollowing),
                    icon: Icon(isFollowing ? Icons.check : Icons.person_add_outlined),
                    label: Text(isFollowing ? 'Following' : 'Follow'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing ? AppColors.surfaceVariant : AppColors.primary,
                      foregroundColor: isFollowing ? AppColors.textPrimary : AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // About
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('About', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(vendor.description, style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Products Header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Products', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${vendorProducts.length} items', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          // Products Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: vendorProducts.length,
              itemBuilder: (context, index) {
                final product = vendorProducts[index];
                return ProductCard(
                  product: product,
                  onTap: () => context.push('/product/${product.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
