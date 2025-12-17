import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';
import 'product_detail_screen.dart';
import 'chat_detail_screen.dart';

class StoreProfileScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  final String storeAvatar;

  const StoreProfileScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    required this.storeAvatar,
  });

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;

  final _storeInfo = _StoreInfo(
    name: 'Glow Electronics',
    bio: 'Your one-stop shop for premium electronics and gadgets. Quality products, fast delivery! 🚀',
    category: 'Electronics & Gadgets',
    rating: 4.8,
    reviewCount: 2847,
    followers: 12500,
    products: 156,
    joinedDate: 'Jan 2023',
    location: '123 Tech Street, Silicon Valley, CA',
    responseTime: '< 1 hour',
    isVerified: true,
  );

  final List<_StoreProduct> _products = [
    _StoreProduct(id: '1', name: 'iPhone 15 Pro Max', price: 1199.00, originalPrice: 1299.00, image: '', rating: 4.9, sold: 234),
    _StoreProduct(id: '2', name: 'AirPods Pro 2nd Gen', price: 249.00, image: '', rating: 4.8, sold: 567),
    _StoreProduct(id: '3', name: 'MacBook Air M3', price: 1099.00, originalPrice: 1199.00, image: '', rating: 4.9, sold: 123),
    _StoreProduct(id: '4', name: 'Apple Watch Ultra 2', price: 799.00, image: '', rating: 4.7, sold: 89),
    _StoreProduct(id: '5', name: 'iPad Pro 12.9"', price: 1099.00, image: '', rating: 4.8, sold: 156),
    _StoreProduct(id: '6', name: 'Samsung Galaxy S24', price: 899.00, originalPrice: 999.00, image: '', rating: 4.6, sold: 312),
  ];

  final List<_StorePost> _posts = [
    _StorePost(id: '1', image: '', caption: 'New arrivals! Check out our latest collection 🔥', likes: 234, comments: 45),
    _StorePost(id: '2', image: '', caption: 'Flash sale this weekend! Up to 50% off', likes: 567, comments: 89),
    _StorePost(id: '3', image: '', caption: 'Customer favorite - iPhone 15 Pro Max', likes: 123, comments: 23),
  ];

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
      backgroundColor: AppColors.backgroundBeige,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.backgroundBeige,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 40, height: 40,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Iconsax.more, color: AppColors.textPrimary, size: 20),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(child: _buildStoreHeader()),
          SliverToBoxAdapter(child: _buildStoreStats()),
          SliverToBoxAdapter(child: _buildActionButtons()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.darkGreen,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.darkGreen,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'Products'),
                  Tab(text: 'Posts'),
                  Tab(text: 'About'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProductsTab(),
            _buildPostsTab(),
            _buildAboutTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Circular profile picture
          Stack(
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppColors.darkGreen, Color(0xFF2D5A45)]),
                  ),
                  child: Center(child: Text(widget.storeAvatar, style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white))),
                ),
              ),
              // Share button on profile picture
              Positioned(
                right: 0, bottom: 0,
                child: GestureDetector(
                  onTap: () => _shareStore(),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.darkGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Iconsax.share, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Store name and info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_storeInfo.name, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              if (_storeInfo.isVerified) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: AppColors.darkGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(_storeInfo.category, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.star1, size: 16, color: Color(0xFFFFB800)),
              const SizedBox(width: 4),
              Text('${_storeInfo.rating}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(' (${_storeInfo.reviewCount} reviews)', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _shareStore() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share link copied!', style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: AppColors.darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildStoreStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            _buildStatItem('${_formatNumber(_storeInfo.followers)}', 'Followers'),
            _buildStatDivider(),
            _buildStatItem('${_storeInfo.products}', 'Products'),
            _buildStatDivider(),
            _buildStatItem(_storeInfo.responseTime, 'Response'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 36, color: AppColors.surfaceVariant);
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => setState(() => _isFollowing = !_isFollowing),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isFollowing ? Colors.white : AppColors.darkGreen,
                  borderRadius: BorderRadius.circular(14),
                  border: _isFollowing ? Border.all(color: AppColors.darkGreen) : null,
                ),
                child: Center(
                  child: Text(
                    _isFollowing ? 'Following' : 'Follow',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _isFollowing ? AppColors.darkGreen : Colors.white),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(userName: widget.storeName, userAvatar: widget.storeAvatar))),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.surfaceVariant)),
                child: const Icon(Iconsax.message, size: 20, color: AppColors.darkGreen),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _showLocationSheet(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.surfaceVariant)),
                child: const Icon(Iconsax.location, size: 20, color: AppColors.darkGreen),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildProductsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) => _buildProductCard(_products[index]),
    );
  }

  Widget _buildProductCard(_StoreProduct product) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(
        productId: product.id,
        productName: product.name,
        storeName: widget.storeName,
        storeId: widget.storeId,
      ))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Center(child: Icon(Iconsax.box, size: 40, color: Colors.grey.shade400)),
                  ),
                  if (product.originalPrice != null)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          '-${((1 - product.price / product.originalPrice!) * 100).toInt()}%',
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
                      child: const Icon(Iconsax.heart, size: 16, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Iconsax.star1, size: 12, color: Color(0xFFFFB800)),
                        const SizedBox(width: 2),
                        Text('${product.rating}', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(width: 6),
                        Text('${product.sold} sold', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('\$${product.price.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
                        if (product.originalPrice != null) ...[
                          const SizedBox(width: 6),
                          Text('\$${product.originalPrice!.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary, decoration: TextDecoration.lineThrough)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
      itemCount: _posts.length,
      itemBuilder: (context, index) => _buildPostTile(_posts[index]),
    );
  }

  Widget _buildPostTile(_StorePost post) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(4)),
        child: Stack(
          children: [
            Center(child: Icon(Iconsax.image, size: 24, color: Colors.grey.shade400)),
            Positioned(
              bottom: 4, left: 4,
              child: Row(
                children: [
                  const Icon(Iconsax.heart5, size: 12, color: Colors.white),
                  const SizedBox(width: 2),
                  Text('${post.likes}', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAboutSection('About', _storeInfo.bio, Iconsax.info_circle),
          const SizedBox(height: 20),
          _buildAboutSection('Location', _storeInfo.location, Iconsax.location),
          const SizedBox(height: 20),
          _buildAboutSection('Member Since', _storeInfo.joinedDate, Iconsax.calendar),
          const SizedBox(height: 20),
          _buildAboutSection('Response Time', _storeInfo.responseTime, Iconsax.timer_1),
          const SizedBox(height: 24),
          _buildStoreHighlights(),
          const SizedBox(height: 24),
          _buildReviewsSummary(),
        ],
      ),
    );
  }

  Widget _buildAboutSection(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.darkGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: AppColors.darkGreen),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(content, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreHighlights() {
    final highlights = [
      _Highlight(icon: Iconsax.verify, label: 'Verified Seller'),
      _Highlight(icon: Iconsax.truck_fast, label: 'Fast Shipping'),
      _Highlight(icon: Iconsax.shield_tick, label: 'Buyer Protection'),
      _Highlight(icon: Iconsax.refresh, label: 'Easy Returns'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Store Highlights', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: highlights.map((h) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(h.icon, size: 18, color: AppColors.darkGreen),
                const SizedBox(width: 8),
                Text(h.label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildReviewsSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Customer Reviews', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const Spacer(),
              Text('See all', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.darkGreen)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                children: [
                  Text('${_storeInfo.rating}', style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Row(children: List.generate(5, (i) => Icon(i < _storeInfo.rating.floor() ? Iconsax.star1 : Iconsax.star, size: 16, color: const Color(0xFFFFB800)))),
                  const SizedBox(height: 4),
                  Text('${_storeInfo.reviewCount} reviews', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(5, 0.75),
                    _buildRatingBar(4, 0.15),
                    _buildRatingBar(3, 0.06),
                    _buildRatingBar(2, 0.03),
                    _buildRatingBar(1, 0.01),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$stars', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(3)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(decoration: BoxDecoration(color: const Color(0xFFFFB800), borderRadius: BorderRadius.circular(3))),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showLocationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text('Store Location', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.map, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('Map View', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Iconsax.maximize_4, size: 20, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: AppColors.darkGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Iconsax.location, size: 22, color: AppColors.darkGreen),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_storeInfo.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              Text(_storeInfo.location, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Iconsax.routing_2, size: 20),
                      label: Text('Get Directions', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: AppColors.backgroundBeige, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class _StoreInfo {
  final String name, bio, category, location, responseTime, joinedDate;
  final double rating;
  final int reviewCount, followers, products;
  final bool isVerified;

  _StoreInfo({
    required this.name,
    required this.bio,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.followers,
    required this.products,
    required this.joinedDate,
    required this.location,
    required this.responseTime,
    required this.isVerified,
  });
}

class _StoreProduct {
  final String id, name, image;
  final double price, rating;
  final double? originalPrice;
  final int sold;

  _StoreProduct({required this.id, required this.name, required this.price, this.originalPrice, required this.image, required this.rating, required this.sold});
}

class _StorePost {
  final String id, image, caption;
  final int likes, comments;

  _StorePost({required this.id, required this.image, required this.caption, required this.likes, required this.comments});
}

class _Highlight {
  final IconData icon;
  final String label;

  _Highlight({required this.icon, required this.label});
}
