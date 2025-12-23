import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'product_detail_screen.dart';
import 'chat_detail_screen.dart';
import 'order_history_screen.dart';
import 'store_map_screen.dart';
import 'categories_screen.dart';
import 'store_profile_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 2;

  final List<String> _categories = ['Wellness', 'Art', 'Sport', 'Home', 'Music', 'Tech'];

  final List<_Product> _products = [
    _Product(id: '1', name: 'Smart Watch WH22-6 Fitness Tracker', price: 154.97, isTopItem: true, inCart: true, storeName: 'TechZone', storeId: 'store-1'),
    _Product(id: '2', name: 'Club Kit 1 Recurve Archery Set', price: 48.99, isTopItem: false, inCart: false, storeName: 'SportsPro', storeId: 'store-2'),
    _Product(id: '3', name: 'Nike Air Vapormax Plus Light Blue', price: 154.97, originalPrice: 220.00, isTopItem: false, inCart: false, storeName: 'SneakerHub', storeId: 'store-3'),
    _Product(id: '4', name: 'Pullover Hoodie - Unisex Casual', price: 65.00, isTopItem: true, inCart: true, storeName: 'UrbanStyle', storeId: 'store-4'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildCategories(),
            const SizedBox(height: 16),
            _buildProductsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Text('Discover', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
          const Spacer(),
          _buildHeaderIcon(Iconsax.category, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen()))),
          const SizedBox(width: 8),
          _buildHeaderIcon(Iconsax.map, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreMapScreen()))),
          const SizedBox(width: 8),
          _buildHeaderIcon(Iconsax.receipt_text, _navigateToOrderHistory),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 20, color: Colors.black),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: Icon(Iconsax.search_normal, size: 20, color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Iconsax.setting_4, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: isSelected ? Colors.black : Colors.grey[100], borderRadius: BorderRadius.circular(20)),
              child: Center(
                child: Text(_categories[index], style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : Colors.black)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsGrid() {
    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.55, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: _products.length,
        itemBuilder: (context, index) => _buildProductCard(_products[index]),
      ),
    );
  }

  Widget _buildProductCard(_Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: product.id, productName: product.name, storeName: product.storeName, storeId: product.storeId))),
      child: Container(
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                    child: Center(child: Icon(Iconsax.box, size: 50, color: Colors.grey[400])),
                  ),
                  if (product.isTopItem)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
                        child: Text('Top Item', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Iconsax.heart, size: 14, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _openStoreProfile(product.storeId, product.storeName),
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.grey[300],
                          child: Text(product.storeName[0], style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.black)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openStoreProfile(product.storeId, product.storeName),
                          child: Text(product.storeName, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey[600])),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _messageStore(product.storeId, product.storeName),
                        child: const Icon(Iconsax.message, size: 14, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black, height: 1.3)),
                  const SizedBox(height: 4),
                  if (product.originalPrice != null)
                    Text('\$${product.originalPrice!.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500], decoration: TextDecoration.lineThrough)),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: product.inCart
                        ? OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: const BorderSide(color: Colors.black)),
                            child: Text('In cart', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black)),
                          )
                        : ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Iconsax.shopping_bag, size: 14),
                                const SizedBox(width: 4),
                                Text('\$${product.price.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
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

  void _navigateToOrderHistory() => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderHistoryScreen()));
  void _messageStore(String storeId, String storeName) => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(userName: storeName, userAvatar: storeName[0])));
  void _openStoreProfile(String storeId, String storeName) => Navigator.push(context, MaterialPageRoute(builder: (context) => StoreProfileScreen(storeId: storeId, storeName: storeName, storeAvatar: storeName[0])));

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(sheetContext).size.height * 0.6,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filters', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                  TextButton(onPressed: () {}, child: Text('Reset', style: GoogleFonts.poppins(fontSize: 14, color: Colors.black))),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterSection('Price Range', ['\$0-\$50', '\$50-\$100', '\$100-\$200', '\$200+']),
                    _buildFilterSection('Rating', ['4+ Stars', '3+ Stars', '2+ Stars', 'All']),
                    _buildFilterSection('Sort By', ['Popular', 'Newest', 'Price: Low to High', 'Price: High to Low']),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(sheetContext).padding.bottom + 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text('Apply Filters', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
            child: Text(option, style: GoogleFonts.poppins(fontSize: 13, color: Colors.black)),
          )).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _Product {
  final String id;
  final String name;
  final double price;
  final double? originalPrice;
  final bool isTopItem;
  final bool inCart;
  final String storeName;
  final String storeId;

  _Product({required this.id, required this.name, required this.price, this.originalPrice, this.isTopItem = false, this.inCart = false, required this.storeName, required this.storeId});
}
