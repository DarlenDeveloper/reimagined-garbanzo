import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/search_service.dart';
import '../services/currency_service.dart';
import '../services/wishlist_service.dart';
import '../theme/colors.dart';
import 'store_profile_screen.dart';
import 'product_detail_screen.dart';
import 'main_screen.dart';
import 'discover_screen.dart';
import 'ai_shopping_assistant_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _searchService = SearchService();
  final _wishlistService = WishlistService();
  
  String searchQuery = '';
  int _selectedTab = 0; // 0 = Products, 1 = Stores
  List<String> searchSuggestions = [];
  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> storeResults = [];
  bool isLoadingSuggestions = false;
  bool isSearching = false;
  bool showResults = false;
  List<String> recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final searches = await _searchService.loadRecentSearches();
    setState(() => recentSearches = searches);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _getSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchSuggestions = [];
        showResults = false;
      });
      return;
    }

    setState(() => isLoadingSuggestions = true);

    // Get suggestions based on selected tab
    List<String> suggestions;
    if (_selectedTab == 0) {
      suggestions = await _searchService.getSearchSuggestions(query);
    } else {
      suggestions = await _searchService.getStoreSuggestions(query);
    }
    
    setState(() {
      searchSuggestions = suggestions;
      isLoadingSuggestions = false;
      showResults = false;
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    print('🔎 Performing search for: "$query" on tab: ${_selectedTab == 0 ? "Products" : "Stores"}');

    setState(() {
      isSearching = true;
      showResults = true;
    });

    if (_selectedTab == 0) {
      // Search products
      print('📱 Searching products...');
      final results = await _searchService.searchProducts(query);
      print('📱 Got ${results.length} product results');
      setState(() {
        searchResults = results;
        isSearching = false;
      });
    } else {
      // Search stores
      print('🏪 Searching stores...');
      final results = await _searchService.searchStores(query);
      print('🏪 Got ${results.length} store results');
      setState(() {
        storeResults = results;
        isSearching = false;
      });
    }

    await _searchService.saveRecentSearch(query);
    _loadRecentSearches();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard when tapping outside
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    height: 44,
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Search products, brands...',
                        hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
                        prefixIcon: Icon(Iconsax.search_normal, color: Colors.grey[500], size: 20),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Iconsax.close_circle, color: Colors.grey[500], size: 20),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() {
                                    searchQuery = '';
                                    showResults = false;
                                    searchSuggestions = [];
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                      onChanged: (value) {
                        setState(() => searchQuery = value);
                        _getSuggestions(value);
                      },
                      onSubmitted: (query) {
                        if (query.isNotEmpty) {
                          _performSearch(query);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AIShoppingAssistantScreen(),
                  );
                },
                child: SizedBox(
                  height: 56,
                  width: 56,
                  child: Image.asset(
                    'assets/images/shoppingassistantlogo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          titleSpacing: 0,
        ),
        body: Column(
          children: [
            // Tabs
            if (showResults) _buildTabs(),
            // Content
            Expanded(
              child: showResults 
                  ? _buildSearchResults() 
                  : (searchQuery.isEmpty ? _buildEmptyState() : _buildSuggestions()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildTab('Products', 0),
          const SizedBox(width: 16),
          _buildTab('Stores', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        print('🔄 Switching to tab: $label (index: $index)');
        setState(() => _selectedTab = index);
        if (searchQuery.isNotEmpty && showResults) {
          print('🔄 Re-searching with query: "$searchQuery"');
          _performSearch(searchQuery);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFfb2a0a) : Colors.transparent, // Main red
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        if (recentSearches.isNotEmpty) ...[
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Searches', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                    GestureDetector(
                      onTap: () async {
                        await _searchService.clearRecentSearches();
                        _loadRecentSearches();
                      },
                      child: Text('Clear all', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...recentSearches.map((search) => _buildRecentSearchItem(search)),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
        ],
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Popular Categories', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _buildCategoryGrid(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    if (isLoadingSuggestions) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFfb2a0a))); // Main red
    }

    if (searchSuggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.search_status, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No suggestions', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Press Enter to search', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: searchSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = searchSuggestions[index];
        return ListTile(
          leading: Icon(Iconsax.search_normal, color: Colors.grey[400], size: 20),
          title: Text(suggestion, style: GoogleFonts.poppins(fontSize: 14)),
          trailing: Icon(Iconsax.arrow_right_3, color: Colors.grey[400], size: 16),
          onTap: () {
            _controller.text = suggestion;
            setState(() => searchQuery = suggestion);
            _performSearch(suggestion);
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (isSearching) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFfb2a0a))); // Main red
    }

    final results = _selectedTab == 0 ? searchResults : storeResults;

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.search_status, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No results found', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Try a different search term', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey[50],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            '${results.length} results for "$searchQuery"',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: _selectedTab == 0 ? _buildProductGrid() : _buildStoreList(),
        ),
      ],
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final product = searchResults[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildStoreList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: storeResults.length,
      itemBuilder: (context, index) {
        final store = storeResults[index];
        return _buildStoreCard(store);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['name'] ?? 'Product';
    final price = (product['price'] ?? 0).toDouble();
    final currency = product['currency'] ?? 'UGX';
    final productId = product['id'];
    final storeId = product['storeId'];
    final storeName = product['storeName'] ?? 'Store';
    final primaryImageUrl = product['primaryImageUrl'];
    final isFeatured = product['isFeatured'] ?? false;
    
    final currencyData = CurrencyService.currencies[currency];
    final symbol = currencyData?.symbol ?? currency;
    
    // Format price with k/M suffix and space
    String formattedPrice;
    if (price >= 1000000) {
      formattedPrice = '$symbol ${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      formattedPrice = '$symbol ${(price / 1000).toStringAsFixed(0)}k';
    } else {
      formattedPrice = '$symbol ${price.toStringAsFixed(0)}';
    }

    return GestureDetector(
      onTap: () {
        if (productId != null && storeId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productId: productId,
                productName: name,
                storeName: storeName,
                storeId: storeId,
              ),
            ),
          );
        }
      },
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
                    child: primaryImageUrl != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: CachedNetworkImage(
                              imageUrl: primaryImageUrl,
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
                  if (isFeatured)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFfb2a0a), // Main red
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
                      onTap: () async {
                        if (productId == null || storeId == null) {
                          print('❌ Cannot add to wishlist: productId=$productId, storeId=$storeId');
                          return;
                        }
                        
                        final userId = FirebaseAuth.instance.currentUser?.uid;
                        if (userId == null) {
                          print('❌ User not logged in');
                          return;
                        }
                        
                        try {
                          await _wishlistService.toggleWishlist(
                            userId: userId,
                            productId: productId,
                            storeId: storeId,
                            productName: name,
                            price: price,
                            currency: currency,
                            productImage: primaryImageUrl,
                            storeName: storeName,
                          );
                          
                          // Show feedback
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added to wishlist'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        } catch (e) {
                          print('❌ Wishlist error: $e');
                        }
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Iconsax.heart,
                          size: 14,
                          color: Colors.black,
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
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedPrice,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
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

  Widget _buildRecentSearchItem(String search) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Iconsax.clock, color: Colors.grey[400], size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                _controller.text = search;
                setState(() => searchQuery = search);
                _performSearch(search);
              },
              behavior: HitTestBehavior.opaque,
              child: Text(search, style: GoogleFonts.poppins(fontSize: 14)),
            ),
          ),
          GestureDetector(
            onTap: () async {
              await _searchService.removeRecentSearch(search);
              _loadRecentSearches();
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Iconsax.close_circle, color: Colors.grey[400], size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'name': 'Apparel', 'id': 'apparel', 'image': 'assets/images/categories/apparel.jpg'},
      {'name': 'Electronics', 'id': 'electronics', 'image': 'assets/images/categories/electronics.jpg'},
      {'name': 'Automotive', 'id': 'automotive', 'image': 'assets/images/categories/automotive.jpg'},
      {'name': 'Home', 'id': 'home_living', 'image': 'assets/images/categories/home.jpeg'},
      {'name': 'Beauty', 'id': 'beauty', 'image': 'assets/images/categories/beauty.jpg'},
      {'name': 'Baby & Kids', 'id': 'baby_kids', 'image': 'assets/images/categories/baby_kids.jpg'},
      {'name': 'Sports', 'id': 'sports', 'image': 'assets/images/categories/sports.jpg'},
      {'name': 'Books', 'id': 'books', 'image': 'assets/images/categories/books.jpg'},
      {'name': 'Art', 'id': 'art', 'image': 'assets/images/categories/art.jpg'},
      {'name': 'Grocery', 'id': 'grocery', 'image': 'assets/images/categories/grocery.jpg'},
      {'name': 'Other', 'id': 'other', 'image': 'assets/images/categories/other.jpg'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return _buildCategoryCard(categories[index]);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, String> category) {
    return GestureDetector(
      onTap: () {
        final categoryId = category['id']!;
        // Pop and then navigate using Navigator result
        Navigator.pop(context, {'action': 'selectCategory', 'categoryId': categoryId});
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Category image
              Image.asset(
                category['image']!,
                fit: BoxFit.cover,
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              // Category name
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  category['name']!,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String name) {
    return GestureDetector(
      onTap: () {
        _controller.text = name;
        setState(() => searchQuery = name);
        _performSearch(name);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    final name = store['name'] ?? 'Store';
    final description = store['description'] ?? '';
    final logoUrl = store['logoUrl'] ?? '';
    final verificationStatus = store['verificationStatus'] as String?;
    final isVerified = verificationStatus == 'verified';
    final rating = (store['rating'] ?? 0).toDouble();
    final followerCount = store['followerCount'] ?? 0;
    final storeId = store['id'];

    return GestureDetector(
      onTap: () {
        if (storeId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoreProfileScreen(
                storeId: storeId,
                storeName: name,
                storeAvatar: name.isNotEmpty ? name[0] : 'S',
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            // Store Logo
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: logoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: logoUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (context, url, error) => const Icon(Icons.store, size: 30),
                      ),
                    )
                  : const Icon(Icons.store, size: 30),
            ),
            const SizedBox(width: 12),
            // Store Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Color(0xFFfb2a0a), shape: BoxShape.circle), // Main red
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        '$followerCount followers',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
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
