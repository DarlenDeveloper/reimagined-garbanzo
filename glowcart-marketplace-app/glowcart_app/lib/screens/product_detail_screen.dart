import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';
import 'chat_detail_screen.dart';
import 'store_profile_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String? productId;
  final String? productName;
  final String? storeName;
  final String? storeId;

  const ProductDetailScreen({
    super.key,
    this.productId,
    this.productName,
    this.storeName,
    this.storeId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedColorIndex = 0;
  int _selectedSizeIndex = 1;
  bool _isFavorite = false;

  final List<Color> _colors = [
    const Color(0xFF1E3A5F),
    const Color(0xFFE5E5E5),
    const Color(0xFF2D2D2D),
  ];

  final List<String> _sizes = ['6.5', '7', '7.5', '8', '8.5'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Iconsax.heart5 : Iconsax.heart,
              color: _isFavorite ? AppColors.darkGreen : AppColors.textPrimary,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.darkGreen,
              indicatorWeight: 2,
              labelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Details'),
                Tab(text: 'Reviews 84'),
                Tab(text: 'Questions 6'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildReviewsTab(),
                _buildQuestionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Stack(
            children: [
              Container(
                height: 280,
                width: double.infinity,
                color: const Color(0xFFF5F5F5),
                child: Center(
                  child: Icon(
                    Iconsax.box,
                    size: 100,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              // Top Item Badge
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.darkGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Top Item',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Checkmark
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.darkGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Info with Message Icon
                _buildStoreInfo(),
                const SizedBox(height: 12),
                // Product Name
                Text(
                  widget.productName ?? "Men's Sneakers AeroStep",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  'Lightweight and stylish sneakers for everyday wear. Available in three colors: white, red, and black.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 20),

                // Color Selection
                Text(
                  'Color',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'White',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(
                    _colors.length,
                    (index) => GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = index),
                      child: Container(
                        width: 56,
                        height: 56,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F0E8),
                          borderRadius: BorderRadius.circular(12),
                          border: _selectedColorIndex == index
                              ? Border.all(color: AppColors.darkGreen, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _colors[index],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Size Selection
                Row(
                  children: [
                    Text(
                      'Size',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _sizes[_selectedSizeIndex],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(
                    _sizes.length,
                    (index) => GestureDetector(
                      onTap: () => setState(() => _selectedSizeIndex = index),
                      child: Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: _selectedSizeIndex == index
                              ? AppColors.darkGreen
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedSizeIndex == index
                                ? AppColors.darkGreen
                                : AppColors.border,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _sizes[index],
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _selectedSizeIndex == index
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Reviews Preview
                Text(
                  'Reviews',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // User Avatar
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.darkGreen,
                      child: Text(
                        'J',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Jan',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '\$139.99',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Price Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.darkGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Iconsax.shopping_bag, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            '\$119.99',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '5/5',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Icon(Iconsax.star1, size: 14, color: Color(0xFFFFD700)),
                  ],
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfo() {
    final storeName = widget.storeName ?? 'TechZone';
    final storeId = widget.storeId ?? 'store-1';
    return GestureDetector(
      onTap: () => _openStoreProfile(storeId, storeName),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0E8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.darkGreen,
              child: Text(
                storeName[0],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        storeName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.limeAccent : AppColors.darkGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, size: 8, color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white),
                      ),
                      const Spacer(),
                      const Icon(Iconsax.arrow_right_3, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                  Text(
                    'Verified Seller • Tap to view store',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _messageStore(storeName),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.darkGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.message, size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _messageStore(String storeName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          userName: storeName,
          userAvatar: storeName[0],
        ),
      ),
    );
  }

  void _openStoreProfile(String storeId, String storeName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreProfileScreen(
          storeId: storeId,
          storeName: storeName,
          storeAvatar: storeName[0],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Center(
      child: Text(
        '84 Reviews',
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildQuestionsTab() {
    return Center(
      child: Text(
        '6 Questions',
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
