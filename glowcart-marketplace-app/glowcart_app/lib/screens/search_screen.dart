import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search products, brands...',
            prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      setState(() => searchQuery = '');
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onChanged: (value) => setState(() => searchQuery = value),
        ),
      ),
      body: searchQuery.isEmpty
          ? ListView(
              children: [
                // Recent Searches
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.w600)),
                          TextButton(onPressed: () {}, child: Text('Clear all', style: TextStyle(color: AppColors.primary))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...recentSearches.map((search) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.history, color: AppColors.textSecondary, size: 20),
                        title: Text(search),
                        onTap: () {
                          _controller.text = search;
                          setState(() => searchQuery = search);
                        },
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Popular Categories
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Popular Categories', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: DummyData.categories.take(4).map((cat) => ActionChip(
                          label: Text(cat.name),
                          onPressed: () {
                            _controller.text = cat.name;
                            setState(() => searchQuery = cat.name);
                          },
                          backgroundColor: AppColors.surfaceVariant,
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('No results found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Try a different search term', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7))),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: AppColors.surface,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${searchResults.length} results for "$searchQuery"',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
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
                ),
    );
  }
}
