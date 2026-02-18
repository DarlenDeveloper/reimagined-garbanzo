import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/followers_service.dart';
import '../services/messages_service.dart';
import '../services/currency_service.dart';
import 'product_detail_screen.dart';
import 'chat_detail_screen.dart';

class StoreProfileScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  final String storeAvatar;

  const StoreProfileScreen({super.key, required this.storeId, required this.storeName, required this.storeAvatar});

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FollowersService _followersService = FollowersService();
  final MessagesService _messagesService = MessagesService();
  final CurrencyService _currencyService = CurrencyService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isFollowing = false;
  bool _isLoading = true;
  String _userCurrency = 'UGX';
  
  Map<String, dynamic>? _storeData;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _posts = [];
  int _followerCount = 0;

  final _storeInfo = _StoreInfo(
    name: 'Glow Electronics',
    bio: 'Your one-stop shop for premium electronics and gadgets. Quality products, fast delivery!',
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

  final List<_StoreProduct> _products_dummy = [
    _StoreProduct(id: '1', name: 'iPhone 15 Pro Max', price: 1199.00, originalPrice: 1299.00, rating: 4.9, sold: 234),
    _StoreProduct(id: '2', name: 'AirPods Pro 2nd Gen', price: 249.00, rating: 4.8, sold: 567),
    _StoreProduct(id: '3', name: 'MacBook Air M3', price: 1099.00, originalPrice: 1199.00, rating: 4.9, sold: 123),
    _StoreProduct(id: '4', name: 'Apple Watch Ultra 2', price: 799.00, rating: 4.7, sold: 89),
    _StoreProduct(id: '5', name: 'iPad Pro 12.9"', price: 1099.00, rating: 4.8, sold: 156),
    _StoreProduct(id: '6', name: 'Samsung Galaxy S24', price: 899.00, originalPrice: 999.00, rating: 4.6, sold: 312),
  ];

  final List<_StorePost> _posts_dummy = [
    _StorePost(id: '1', caption: 'New arrivals! Check out our latest collection', likes: 234, comments: 45),
    _StorePost(id: '2', caption: 'Flash sale this weekend! Up to 50% off', likes: 567, comments: 89),
    _StorePost(id: '3', caption: 'Customer favorite - iPhone 15 Pro Max', likes: 123, comments: 23),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserCurrency();
    _loadStoreData();
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

  Future<void> _loadStoreData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load store info
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .get();
      
      if (storeDoc.exists) {
        _storeData = storeDoc.data();
      }
      
      // Load products
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('products')
          .where('isActive', isEqualTo: true)
          .limit(20)
          .get();
      
      _products = productsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Load posts
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      
      _posts = postsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Load follower count
      _followerCount = await _followersService.getFollowerCount(widget.storeId);
      
      // Check if following
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        _isFollowing = await _followersService.isFollowing(userId, widget.storeId);
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isFollowing = !_isFollowing);

    try {
      if (_isFollowing) {
        await _followersService.followStore(userId, widget.storeId);
        setState(() => _followerCount++);
      } else {
        await _followersService.unfollowStore(userId, widget.storeId);
        setState(() => _followerCount--);
      }
    } catch (e) {
      // Revert on error
      setState(() => _isFollowing = !_isFollowing);
    }
  }

  Future<void> _openChat() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please sign in to send messages', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.black)),
      );

      // Get user data - try multiple sources
      String userName = 'User';
      String? userPhotoUrl;
      
      // First try: Firestore user document
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        final userData = userDoc.data();
        if (userData != null && userData['name'] != null && (userData['name'] as String).isNotEmpty) {
          userName = userData['name'];
        }
        userPhotoUrl = userData?['photoUrl'] as String?;
      } catch (e) {
        print('Error fetching user from Firestore: $e');
      }
      
      // Second try: Firebase Auth displayName
      if (userName == 'User' && _auth.currentUser?.displayName != null && _auth.currentUser!.displayName!.isNotEmpty) {
        userName = _auth.currentUser!.displayName!;
      }
      
      // Third try: Firebase Auth email (use part before @)
      if (userName == 'User' && _auth.currentUser?.email != null) {
        userName = _auth.currentUser!.email!.split('@')[0];
      }

      // Get or create conversation
      final conversationId = await _messagesService.getOrCreateConversation(
        storeId: widget.storeId,
        storeName: _storeData?['name'] ?? widget.storeName,
        storeLogoUrl: _storeData?['logoUrl'],
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
      );

      // Close loading
      if (mounted) Navigator.pop(context);

      // Navigate to chat
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ChatScreen(
              conversationId: conversationId,
              storeName: _storeData?['name'] ?? widget.storeName,
              storeLogoUrl: _storeData?['logoUrl'],
              userId: userId,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open chat: ${e.toString()}', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('Error opening chat: $e');
    }
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: const Icon(Iconsax.arrow_left, color: Colors.black),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 40, height: 40,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Iconsax.more, color: Colors.black, size: 20),
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
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey[500],
                indicatorColor: Colors.black,
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.grey[200],
                labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                tabs: const [Tab(text: 'Products'), Tab(text: 'Posts'), Tab(text: 'About')],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [_buildProductsTab(), _buildPostsTab(), _buildAboutTab()],
        ),
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                padding: const EdgeInsets.all(4),
                child: _storeData?['logoUrl'] != null && (_storeData!['logoUrl'] as String).isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          _storeData!['logoUrl'],
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200]),
                            child: Icon(Iconsax.shop, size: 40, color: Colors.grey[600]),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200]),
                        child: Icon(Iconsax.shop, size: 40, color: Colors.grey[600]),
                      ),
              ),
              Positioned(
                right: 0, bottom: 0,
                child: GestureDetector(
                  onTap: () => _shareStore(),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Iconsax.share, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_storeData?['name'] ?? widget.storeName, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
              if (_storeData?['isVerified'] == true) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(_storeData?['category'] ?? 'Store', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.star1, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 4),
              Text('${(_storeData?['rating'] ?? 4.5).toStringAsFixed(1)}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
              Text(' (${_storeData?['reviewCount'] ?? 0} reviews)', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _shareStore() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share link copied!', style: GoogleFonts.poppins(fontSize: 13)), backgroundColor: Colors.black, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)));
  }

  Widget _buildStoreStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            _buildStatItem('${_formatNumber(_followerCount)}', 'Followers'),
            Container(width: 1, height: 36, color: Colors.grey[300]),
            _buildStatItem('${_products.length}', 'Products'),
            Container(width: 1, height: 36, color: Colors.grey[300]),
            _buildStatItem(_storeData?['responseTime'] ?? '< 1 hour', 'Response'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _toggleFollow(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isFollowing ? Colors.grey[100] : Colors.black,
                  borderRadius: BorderRadius.circular(14),
                  border: _isFollowing ? Border.all(color: Colors.grey[300]!) : null,
                ),
                child: Center(child: Text(_isFollowing ? 'Following' : 'Follow', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _isFollowing ? Colors.black : Colors.white))),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _openChat(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
                child: const Icon(Iconsax.message, size: 20, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _showLocationSheet(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
                child: const Icon(Iconsax.location, size: 20, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }
    
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.box, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No products yet', style: GoogleFonts.poppins(color: Colors.grey[600])),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: _products.length,
      itemBuilder: (context, index) => _buildProductCard(_products[index]),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final productId = product['id'] as String;
    final name = product['name'] ?? 'Product';
    final price = (product['price'] ?? 0).toDouble();
    final productCurrency = product['currency'] as String? ?? 'USD';
    final originalPrice = product['originalPrice'] != null ? (product['originalPrice'] as num).toDouble() : null;
    final rating = (product['rating'] ?? 4.5).toDouble();
    
    // Convert prices to user currency
    final convertedPrice = _currencyService.convertPrice(price, productCurrency, _userCurrency);
    final convertedOriginalPrice = originalPrice != null 
        ? _currencyService.convertPrice(originalPrice, productCurrency, _userCurrency)
        : null;
    
    // Handle images array - get first image URL
    String? imageUrl;
    final images = product['images'] as List?;
    if (images != null && images.isNotEmpty) {
      final firstImage = images[0] as Map<String, dynamic>;
      imageUrl = firstImage['url'] as String?;
    }
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: productId, productName: name, storeName: widget.storeName, storeId: widget.storeId))),
      child: Container(
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(child: Icon(Iconsax.box, size: 40, color: Colors.grey[400])),
                            ),
                          )
                        : Center(child: Icon(Iconsax.box, size: 40, color: Colors.grey[400])),
                  ),
                  if (convertedOriginalPrice != null && convertedOriginalPrice > convertedPrice)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                        child: Text('-${((1 - convertedPrice / convertedOriginalPrice) * 100).toInt()}%', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Iconsax.heart, size: 16, color: Colors.grey[500]),
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
                    Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black)),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Iconsax.star1, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text('${rating.toStringAsFixed(1)}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(_currencyService.formatPrice(convertedPrice, _userCurrency), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black)),
                        if (convertedOriginalPrice != null && convertedOriginalPrice > convertedPrice) ...[
                          const SizedBox(width: 6),
                          Text(_currencyService.formatPrice(convertedOriginalPrice, _userCurrency), style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500], decoration: TextDecoration.lineThrough)),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }
    
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.document, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No posts yet', style: GoogleFonts.poppins(color: Colors.grey[600])),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
      itemCount: _posts.length,
      itemBuilder: (context, index) => _buildPostTile(_posts[index]),
    );
  }

  Widget _buildPostTile(Map<String, dynamic> post) {
    final likes = post['likes'] ?? 0;
    final mediaList = post['mediaUrls'] as List?;
    final thumbnailUrl = (mediaList != null && mediaList.isNotEmpty) 
        ? (mediaList[0] as Map<String, dynamic>)['thumbnailUrl'] as String?
        : null;
    
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
        child: Stack(
          children: [
            if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  thumbnailUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(child: Icon(Iconsax.image, size: 24, color: Colors.grey[400])),
                ),
              )
            else
              Center(child: Icon(Iconsax.image, size: 24, color: Colors.grey[400])),
            Positioned(
              bottom: 4, left: 4,
              child: Row(
                children: [
                  const Icon(Iconsax.heart5, size: 12, color: Colors.white),
                  const SizedBox(width: 2),
                  Text('$likes', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }
    
    final bio = _storeData?['bio'] ?? 'No description available';
    final locationData = _storeData?['location'];
    final location = locationData is GeoPoint 
        ? 'GPS: ${locationData.latitude.toStringAsFixed(4)}, ${locationData.longitude.toStringAsFixed(4)}'
        : (locationData is String ? locationData : 'Location not specified');
    final createdAt = _storeData?['createdAt'] as Timestamp?;
    final joinedDate = createdAt != null 
        ? '${_getMonthName(createdAt.toDate().month)} ${createdAt.toDate().year}'
        : 'Recently joined';
    final responseTime = _storeData?['responseTime'] ?? '< 1 hour';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAboutSection('About', bio, Iconsax.info_circle),
          const SizedBox(height: 16),
          _buildAboutSection('Location', location, Iconsax.location),
          const SizedBox(height: 16),
          _buildAboutSection('Member Since', joinedDate, Iconsax.calendar),
          const SizedBox(height: 16),
          _buildAboutSection('Response Time', responseTime, Iconsax.timer_1),
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
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: Colors.black),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(content, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
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
        Text('Store Highlights', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: highlights.map((h) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(h.icon, size: 18, color: Colors.black),
                const SizedBox(width: 8),
                Text(h.label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black)),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildReviewsSummary() {
    final rating = (_storeData?['rating'] ?? 4.5).toDouble();
    final reviewCount = _storeData?['reviewCount'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Customer Reviews', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
              const Spacer(),
              Text('See all', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                children: [
                  Text('${rating.toStringAsFixed(1)}', style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w700, color: Colors.black)),
                  Row(children: List.generate(5, (i) => Icon(i < rating.floor() ? Iconsax.star1 : Iconsax.star, size: 16, color: Colors.grey[700]))),
                  const SizedBox(height: 4),
                  Text('$reviewCount reviews', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
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
          Text('$stars', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(3))),
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
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text('Store Location', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                  const Spacer(),
                  GestureDetector(onTap: () => Navigator.pop(ctx), child: Icon(Icons.close, color: Colors.grey[500])),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.map, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('Map View', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500])),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Iconsax.location, size: 22, color: Colors.black),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_storeData?['name'] ?? widget.storeName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                              Text(
                                () {
                                  final loc = _storeData?['location'];
                                  if (loc is GeoPoint) {
                                    return 'GPS Location';
                                  } else if (loc is String) {
                                    return loc;
                                  }
                                  return 'Location not specified';
                                }(),
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                              ),
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
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

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: Colors.white, child: tabBar);

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

  _StoreInfo({required this.name, required this.bio, required this.category, required this.rating, required this.reviewCount, required this.followers, required this.products, required this.joinedDate, required this.location, required this.responseTime, required this.isVerified});
}

class _StoreProduct {
  final String id, name;
  final double price, rating;
  final double? originalPrice;
  final int sold;

  _StoreProduct({required this.id, required this.name, required this.price, this.originalPrice, required this.rating, required this.sold});
}

class _StorePost {
  final String id, caption;
  final int likes, comments;

  _StorePost({required this.id, required this.caption, required this.likes, required this.comments});
}

class _ChatScreen extends StatefulWidget {
  final String conversationId;
  final String storeName;
  final String? storeLogoUrl;
  final String userId;

  const _ChatScreen({
    required this.conversationId,
    required this.storeName,
    this.storeLogoUrl,
    required this.userId,
  });

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final MessagesService _messagesService = MessagesService();

  @override
  void initState() {
    super.initState();
    // Mark as read when opening
    _messagesService.markAsRead(
      conversationId: widget.conversationId,
      userId: widget.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              backgroundImage: widget.storeLogoUrl != null && widget.storeLogoUrl!.isNotEmpty
                  ? NetworkImage(widget.storeLogoUrl!)
                  : null,
              child: widget.storeLogoUrl == null || widget.storeLogoUrl!.isEmpty
                  ? Icon(Iconsax.shop, size: 18, color: Colors.grey[600])
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.storeName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black)),
                Text('Store', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.message, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No messages yet', style: GoogleFonts.poppins(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text('Start the conversation', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13)),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == widget.userId;
                    final createdAt = message['createdAt'] as Timestamp?;
                    final time = createdAt != null ? _messagesService.getMessageTime(createdAt) : '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.black : Colors.grey[100],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                              ),
                              child: Text(message['text'] ?? '', style: GoogleFonts.poppins(fontSize: 14, color: isMe ? Colors.white : Colors.black)),
                            ),
                            const SizedBox(height: 4),
                            Text(time, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Iconsax.send_1, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await _messagesService.sendMessage(
      conversationId: widget.conversationId,
      senderId: widget.userId,
      text: _messageController.text.trim(),
    );

    _messageController.clear();
  }
}

class _Highlight {
  final IconData icon;
  final String label;

  _Highlight({required this.icon, required this.label});
}
