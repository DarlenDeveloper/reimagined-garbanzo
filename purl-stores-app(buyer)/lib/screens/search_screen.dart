import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/search_service.dart';
import '../services/currency_service.dart';
import '../theme/colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _searchService = SearchService();
  
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

    final suggestions = await _searchService.getSearchSuggestions(query);
    
    setState(() {
      searchSuggestions = suggestions;
      isLoadingSuggestions = false;
      showResults = false;
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      isSearching = true;
      showResults = true;
    });

    if (_selectedTab == 0) {
      // Search products
      final results = await _searchService.searchProducts(query);
      setState(() {
        searchResults = results;
        isSearching = false;
      });
    } else {
      // Search stores
      final results = await _searchService.searchStores(query);
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        setState(() => _selectedTab = index);
        if (searchQuery.isNotEmpty && showResults) {
          _performSearch(searchQuery);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.black : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
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
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Popular Categories', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Apparel', 'Electronics', 'Automotive', 'Home', 'Beauty', 'Sports']
                    .map((cat) => _buildCategoryChip(cat))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    if (isLoadingSuggestions) {
      return const Center(child: CircularProgressIndicator(color: AppColors.black));
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
      return const Center(child: CircularProgressIndicator(color: AppColors.black));
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
    final images = product['images'] as List<dynamic>? ?? [];
    final imageUrl = images.isNotEmpty ? images[0] : '';
    final isFeatured = product['isFeatured'] ?? false;
    final rating = (product['rating'] ?? 0).toDouble();
    
    final currencyData = CurrencyService.currencies[currency];
    final symbol = currencyData?.symbol ?? currency;
    final formattedPrice = '$symbol ${price.toStringAsFixed(0)}';

    return GestureDetector(
      onTap: () {
        final productId = product['id'];
        final storeId = product['storeId'];
        if (productId != null && storeId != null) {
          context.push('/product/$storeId/$productId');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorWidget: (context, url, error) => const Icon(Icons.image, size: 40),
                          ),
                        )
                      : const Center(child: Icon(Icons.image, size: 40)),
                ),
                if (isFeatured)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Top Item', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1), style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(formattedPrice, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearchItem(String search) {
    return GestureDetector(
      onTap: () {
        _controller.text = search;
        setState(() => searchQuery = search);
        _performSearch(search);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(Iconsax.clock, color: Colors.grey[400], size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(search, style: GoogleFonts.poppins(fontSize: 14))),
            Icon(Iconsax.arrow_right_3, color: Colors.grey[400], size: 16),
          ],
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
    final logo = store['logo'] ?? '';
    final isVerified = store['isVerified'] ?? false;
    final rating = (store['rating'] ?? 0).toDouble();
    final followerCount = store['followerCount'] ?? 0;

    return GestureDetector(
      onTap: () {
        final storeId = store['id'];
        if (storeId != null) {
          context.push('/store/$storeId');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            // Store Logo
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: logo.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: logo,
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
                      if (isVerified)
                        const Icon(Icons.verified, size: 16, color: Colors.blue),
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
