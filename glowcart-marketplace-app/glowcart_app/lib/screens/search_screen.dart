import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import '../data/dummy_data.dart';
import '../widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String searchQuery = '';
  final recentSearches = ['Headphones', 'Smart Watch', 'Sneakers', 'Jacket'];

  List get searchResults => searchQuery.isEmpty
      ? []
      : DummyData.products.where((p) =>
          p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.vendorName.toLowerCase().contains(searchQuery.toLowerCase())
        ).toList();

  @override
  void dispose() {
    _controller.dispose();
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
                        setState(() => searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => setState(() => searchQuery = value),
          ),
        ),
      ),
      body: searchQuery.isEmpty ? _buildEmptyState() : _buildSearchResults(),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        // Recent Searches
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Searches', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                  GestureDetector(
                    onTap: () {},
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
        // Popular Categories
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Popular Categories', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DummyData.categories.take(6).map((cat) => _buildCategoryChip(cat.name)).toList(),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey[200]),
        // Trending Searches
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trending', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
              const SizedBox(height: 12),
              _buildTrendingItem('1', 'Summer Collection'),
              _buildTrendingItem('2', 'Wireless Earbuds'),
              _buildTrendingItem('3', 'Running Shoes'),
              _buildTrendingItem('4', 'Skincare Sets'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearchItem(String search) {
    return GestureDetector(
      onTap: () {
        _controller.text = search;
        setState(() => searchQuery = search);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(Iconsax.clock, color: Colors.grey[400], size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(search, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black))),
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
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black)),
      ),
    );
  }

  Widget _buildTrendingItem(String rank, String text) {
    return GestureDetector(
      onTap: () {
        _controller.text = text;
        setState(() => searchQuery = text);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
              child: Center(child: Text(rank, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black))),
            Icon(Iconsax.trend_up, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.search_status, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No results found', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
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
            '${searchResults.length} results for "$searchQuery"',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: GridView.builder(
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
              return ProductCard(
                product: product,
                onTap: () => context.push('/product/${product.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}
