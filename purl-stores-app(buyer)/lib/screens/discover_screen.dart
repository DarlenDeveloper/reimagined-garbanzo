import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/ad.dart';
import '../services/product_service.dart';
import '../services/currency_service.dart';
import '../services/messages_service.dart';
import '../services/wishlist_service.dart';
import '../services/cart_service.dart';
import '../services/ads_service.dart';
import 'search_screen.dart';
import 'product_detail_screen.dart';
import 'order_history_screen.dart';
import 'store_map_screen.dart';
import 'categories_screen.dart';
import 'store_profile_screen.dart';
import 'main_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProductService _productService = ProductService();
  final CurrencyService _currencyService = CurrencyService();
  final WishlistService _wishlistService = WishlistService();
  final CartService _cartService = CartService();
  final AdsService _adsService = AdsService();
  final ScrollController _scrollController = ScrollController();
  
  int _selectedCategoryIndex = 0;
  List<Product> _products = [];
  List<Ad> _ads = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  StreamSubscription<List<Product>>? _productsSubscription;
  Set<String> _wishlistedProductIds = {};
  String _userCurrency = 'UGX';
  
  // Filter states
  String _selectedPriceRange = 'All';
  String _selectedRating = 'All';
  String _selectedSort = 'Popular';

  static const int _pageSize = 10;

  // Category mapping to Firestore categoryIds - matches seller taxonomy
  final List<Map<String, String>> _categories = [
    {'name': 'All', 'id': ''},
    {'name': 'Apparel', 'id': 'apparel'},
    {'name': 'Electronics', 'id': 'electronics'},
    {'name': 'Automotive', 'id': 'automotive'},
    {'name': 'Home', 'id': 'home_living'},
    {'name': 'Beauty', 'id': 'beauty'},
    {'name': 'Baby & Kids', 'id': 'baby_kids'},
    {'name': 'Sports', 'id': 'sports'},
    {'name': 'Books', 'id': 'books'},
    {'name': 'Art', 'id': 'art'},
    {'name': 'Grocery', 'id': 'grocery'},
    {'name': 'Other', 'id': 'other'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _subscribeToProducts();
    _subscribeToAds();
    _loadWishlistStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always reload currency when dependencies change
    _loadUserCurrency();
  }

  void _loadUserCurrency() async {
    final currency = await _currencyService.getUserCurrency(forceRefresh: true);
    if (mounted && currency != _userCurrency) {
      setState(() => _userCurrency = currency);
    }
  }

  void _loadWishlistStatus() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Listen to wishlist changes
    _wishlistService.getWishlist(userId).listen((wishlistItems) {
      if (mounted) {
        setState(() {
          _wishlistedProductIds = wishlistItems.map((item) => item['productId'] as String).toSet();
        });
      }
    });
  }

  void _subscribeToAds() {
    _adsService.getActiveAdsStream(limit: 10).listen((ads) {
      print('📢 Ads loaded: ${ads.length} ads');
      for (var ad in ads) {
        print('  - ${ad.storeName}: ${ad.images.length} images, ${ad.viewsRemaining} views remaining');
      }
      if (mounted) {
        setState(() {
          _ads = ads;
        });
      }
    }, onError: (error) {
      print('❌ Error loading ads: $error');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _productsSubscription?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    
    setState(() => _isLoadingMore = true);
    
    // For now, we'll just increase the limit
    // In production, you'd use pagination with startAfter
    final categoryId = _categories[_selectedCategoryIndex]['id'];
    final newLimit = _products.length + _pageSize;
    
    _productsSubscription?.cancel();
    _productsSubscription = _productService
        .getDiscoverProductsStream(
          categoryId: categoryId!.isEmpty ? null : categoryId,
          limit: newLimit,
        )
        .listen(
      (products) {
        if (mounted) {
          setState(() {
            _hasMore = products.length > _products.length;
            _products = products;
            _isLoadingMore = false;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() => _isLoadingMore = false);
        }
      },
    );
  }

  void _subscribeToProducts() {
    _productsSubscription?.cancel();
    
    final categoryId = _categories[_selectedCategoryIndex]['id'];
    
    setState(() {
      _isLoading = true;
      _error = null;
      _hasMore = true;
    });

    _productsSubscription = _productService
        .getDiscoverProductsStream(
          categoryId: categoryId!.isEmpty ? null : categoryId,
          limit: _pageSize,
        )
        .listen(
      (products) {
        if (mounted) {
          setState(() {
            _products = products;
            _isLoading = false;
            _error = null;
            _hasMore = products.length >= _pageSize;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _error = 'Failed to load products';
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            if (_ads.isNotEmpty) ...[
              _buildAdsCard(),
              const SizedBox(height: 12),
            ],
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Text(
            'Discover',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          _buildHeaderIcon(
            Iconsax.map,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StoreMapScreen()),
            ),
          ),
          const SizedBox(width: 8),
          _buildHeaderIcon(Iconsax.receipt_text, _navigateToOrderHistory),
        ],
      ),
    );
  }

  Widget _buildAdsCard() {
    // Hide completely if no ads
    if (_ads.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _ads.length,
        itemBuilder: (context, index) {
          final ad = _ads[index];
          // Record view when ad is built
          _adsService.recordAdView(ad.id);
          
          return _AdCard(
            ad: ad,
            onShopNow: () {
              _adsService.recordAdClick(ad.id);
              _adsService.recordStoreVisit(ad.id);
              _openStoreProfile(ad.storeId, ad.storeName);
            },
            isLast: index == _ads.length - 1,
          );
        },
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: Colors.black),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SearchScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Icon(Iconsax.search_normal, size: 20, color: Colors.grey[500]),
              const SizedBox(width: 12),
              Text(
                'Search products...',
                style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
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
            onTap: () {
              if (_selectedCategoryIndex != index) {
                setState(() => _selectedCategoryIndex = index);
                _subscribeToProducts();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  _categories[index]['name']!,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

    if (_error != null) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.warning_2, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _subscribeToProducts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: Text('Retry', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.box, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No products found',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different category',
                style: GoogleFonts.poppins(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: () async {
          _subscribeToProducts();
        },
        color: Colors.black,
        child: GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.55,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _products.length + (_isLoadingMore ? 2 : 0),
          itemBuilder: (context, index) {
            // Show loading indicator at the bottom
            if (index >= _products.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: Colors.grey[400],
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            return _buildProductCard(_products[index]);
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    // Get currency fresh each time to handle updates
    return FutureBuilder<String>(
      future: _currencyService.getUserCurrency(forceRefresh: true),
      builder: (context, snapshot) {
        final userCurrency = snapshot.data ?? _userCurrency;
        final convertedPrice = _currencyService.convertPrice(product.price, product.currency, userCurrency);
        final formattedPrice = _currencyService.formatPrice(convertedPrice, userCurrency);
        
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productId: product.id,
                productName: product.name,
                storeName: product.storeName,
                storeId: product.storeId,
              ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              child: Stack(
                children: [
                  // Image
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: product.primaryImageUrl != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: CachedNetworkImage(
                              imageUrl: product.primaryImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: Icon(Iconsax.box, size: 50, color: Colors.grey[400]),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(Iconsax.box, size: 50, color: Colors.grey[400]),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(Iconsax.box, size: 50, color: Colors.grey[400]),
                          ),
                  ),
                  // Featured badge
                  if (product.isFeatured)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Top Item',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleWishlist(product),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _wishlistedProductIds.contains(product.id) 
                              ? Iconsax.heart5 
                              : Iconsax.heart,
                          size: 14,
                          color: _wishlistedProductIds.contains(product.id)
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  // Out of stock overlay
                  if (!product.isInStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(100),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store info row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _openStoreProfile(product.storeId, product.storeName),
                        child: product.storeLogo != null
                            ? CircleAvatar(
                                radius: 10,
                                backgroundImage: CachedNetworkImageProvider(product.storeLogo!),
                              )
                            : CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.grey[300],
                                child: Text(
                                  product.storeName.isNotEmpty ? product.storeName[0] : 'S',
                                  style: GoogleFonts.poppins(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openStoreProfile(product.storeId, product.storeName),
                          child: Text(
                            product.storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _messageStore(product.storeId, product.storeName),
                        child: const Icon(Iconsax.message, size: 14, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Product name
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Compare price (strikethrough)
                  if (product.compareAtPrice != null && product.compareAtPrice! > product.price)
                    Text(
                      _currencyService.formatPrice(
                        _currencyService.convertPrice(product.compareAtPrice!, product.currency, _userCurrency),
                        _userCurrency,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[500],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  const SizedBox(height: 6),
                  // Price button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: product.isInStock
                          ? () async {
                              print('🛒 Add to Cart button pressed!');
                              print('Product: ${product.name}, InStock: ${product.isInStock}');
                              try {
                                await _cartService.addToCart(
                                  productId: product.id,
                                  storeId: product.storeId,
                                  storeName: product.storeName,
                                  productName: product.name,
                                  productImage: product.primaryImageUrl ?? '',
                                  price: product.price,
                                  currency: product.currency,
                                  quantity: 1,
                                );
                                
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added to cart', style: GoogleFonts.poppins()),
                                      backgroundColor: Colors.black,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 3),
                                      action: SnackBarAction(
                                        label: 'View Cart',
                                        textColor: Colors.white,
                                        onPressed: () {
                                          MainScreen.navigateToCart(context);
                                        },
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print('❌ Error adding to cart: $e');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to add to cart', style: GoogleFonts.poppins()),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.shopping_bag, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            formattedPrice,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
      },
    );
  }

  void _navigateToOrderHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
    );
  }

  void _messageStore(String storeId, String storeName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreProfileScreen(
          storeId: storeId,
          storeName: storeName,
          storeAvatar: storeName.isNotEmpty ? storeName[0] : 'S',
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
          storeAvatar: storeName.isNotEmpty ? storeName[0] : 'S',
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(sheetContext).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedPriceRange = 'All';
                          _selectedRating = 'All';
                          _selectedSort = 'Popular';
                        });
                      },
                      child: Text(
                        'Reset',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSelectableFilterSection(
                        'Price Range',
                        ['All', 'Under 50K', '50K-100K', '100K-500K', '500K+'],
                        _selectedPriceRange,
                        (value) => setModalState(() => _selectedPriceRange = value),
                      ),
                      _buildSelectableFilterSection(
                        'Rating',
                        ['All', '4+ Stars', '3+ Stars', '2+ Stars'],
                        _selectedRating,
                        (value) => setModalState(() => _selectedRating = value),
                      ),
                      _buildSelectableFilterSection(
                        'Sort By',
                        ['Popular', 'Newest', 'Price: Low to High', 'Price: High to Low'],
                        _selectedSort,
                        (value) => setModalState(() => _selectedSort = value),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(sheetContext).padding.bottom + 12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Apply filters
                        _subscribeToProducts();
                      });
                      Navigator.pop(sheetContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Apply Filters',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableFilterSection(
    String title,
    List<String> options,
    String selectedValue,
    Function(String) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return GestureDetector(
              onTap: () => onSelect(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  option,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _toggleWishlist(Product product) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please sign in to save products', style: GoogleFonts.poppins()),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Optimistic UI update - update immediately
    final isCurrentlyInWishlist = _wishlistedProductIds.contains(product.id);
    final willBeAdded = !isCurrentlyInWishlist;
    
    setState(() {
      if (willBeAdded) {
        _wishlistedProductIds.add(product.id);
      } else {
        _wishlistedProductIds.remove(product.id);
      }
    });

    // Show immediate feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            willBeAdded ? 'Added to wishlist' : 'Removed from wishlist',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    // Process in background
    try {
      await _wishlistService.toggleWishlist(
        userId: userId,
        productId: product.id,
        storeId: product.storeId,
        productName: product.name,
        productImage: product.primaryImageUrl,
        price: product.price, // Store seller's original price
        currency: product.currency,
        storeName: product.storeName,
        isInStock: product.isInStock,
      );
    } catch (e) {
      // Revert UI on error
      if (mounted) {
        setState(() {
          if (willBeAdded) {
            _wishlistedProductIds.remove(product.id);
          } else {
            _wishlistedProductIds.add(product.id);
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update wishlist', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}


// Ad Card Widget with Image Carousel
class _AdCard extends StatefulWidget {
  final Ad ad;
  final VoidCallback onShopNow;
  final bool isLast;

  const _AdCard({
    required this.ad,
    required this.onShopNow,
    this.isLast = false,
  });

  @override
  State<_AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<_AdCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 40,
      margin: EdgeInsets.only(right: widget.isLast ? 0 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black,
      ),
      child: Stack(
        children: [
          // Image Carousel
          if (widget.ad.images.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: widget.ad.images.length,
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: widget.ad.images[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[900],
                        child: const Icon(Iconsax.image, size: 50, color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store info row
                Row(
                  children: [
                    // Store logo
                    if (widget.ad.storeLogo != null)
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: CachedNetworkImageProvider(widget.ad.storeLogo!),
                        backgroundColor: Colors.white,
                      )
                    else
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Text(
                          widget.ad.storeName.isNotEmpty ? widget.ad.storeName[0] : 'S',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.ad.storeName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),

                // Page indicators
                if (widget.ad.images.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.ad.images.length,
                      (index) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),

                // Shop button
                GestureDetector(
                  onTap: widget.onShopNow,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.shop, size: 18, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          'Visit Store',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
