import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/currency_service.dart';
import 'chat_detail_screen.dart';
import 'store_profile_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String storeId;
  final String? productName;
  final String? storeName;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.storeId,
    this.productName,
    this.storeName,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProductService _productService = ProductService();
  final CurrencyService _currencyService = CurrencyService();
  
  Product? _product;
  bool _isLoading = true;
  String? _error;
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  
  // Selected variant values
  final Map<String, dynamic> _selectedValues = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProduct();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    try {
      final product = await _productService.getProductById(
        widget.storeId,
        widget.productId,
      );
      
      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
          
          // Initialize selected values from specs
          if (product != null) {
            _initializeSelectedValues(product);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load product';
          _isLoading = false;
        });
      }
    }
  }

  void _initializeSelectedValues(Product product) {
    // Pre-select first option for color, size, etc.
    final specs = product.specs;
    
    if (specs['color'] != null) {
      if (specs['color'] is List && (specs['color'] as List).isNotEmpty) {
        _selectedValues['color'] = (specs['color'] as List).first;
      } else if (specs['color'] is String) {
        _selectedValues['color'] = specs['color'];
      }
    }
    
    if (specs['size'] != null) {
      _selectedValues['size'] = specs['size'];
    }
    
    if (specs['sizeUS'] != null) {
      _selectedValues['sizeUS'] = specs['sizeUS'];
    }
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
        title: Text(
          'Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Iconsax.heart5 : Iconsax.heart,
              color: _isFavorite ? Colors.red : Colors.black,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _error != null
              ? _buildErrorState()
              : _product == null
                  ? _buildNotFoundState()
                  : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(_error!, style: GoogleFonts.poppins(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadProduct();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: Text('Retry', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.box, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Product not found', style: GoogleFonts.poppins(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Tabs
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            indicatorWeight: 2,
            labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
            tabs: [
              const Tab(text: 'Details'),
              Tab(text: 'Reviews ${_product!.reviewCount}'),
              const Tab(text: 'Questions'),
            ],
          ),
        ),
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
    );
  }

  Widget _buildDetailsTab() {
    final product = _product!;
    final formattedPrice = _currencyService.formatPrice(product.price, product.currency);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Images
          _buildImageGallery(),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Info
                _buildStoreInfo(),
                const SizedBox(height: 16),
                
                // Product Name
                Text(
                  product.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Description
                if (product.description.isNotEmpty)
                  Text(
                    product.description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Dynamic Specs
                _buildDynamicSpecs(),
                
                const SizedBox(height: 24),
                
                // Price and Add to Cart
                _buildPriceSection(formattedPrice),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    final product = _product!;
    final images = product.images;
    
    return Stack(
      children: [
        // Main Image
        Container(
          height: 300,
          width: double.infinity,
          color: Colors.grey[100],
          child: images.isNotEmpty
              ? PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (index) => setState(() => _currentImageIndex = index),
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: images[index].url,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Center(
                        child: Icon(Iconsax.box, size: 80, color: Colors.grey[400]),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Icon(Iconsax.box, size: 80, color: Colors.grey[400]),
                      ),
                    );
                  },
                )
              : Center(
                  child: Icon(Iconsax.box, size: 80, color: Colors.grey[400]),
                ),
        ),
        
        // Featured Badge
        if (product.isFeatured)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black,
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
        
        // Image indicators
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => Container(
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index ? Colors.black : Colors.grey[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStoreInfo() {
    final product = _product!;
    
    return GestureDetector(
      onTap: () => _openStoreProfile(product.storeId, product.storeName),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            product.storeLogo != null
                ? CircleAvatar(
                    radius: 20,
                    backgroundImage: CachedNetworkImageProvider(product.storeLogo!),
                  )
                : CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.black,
                    child: Text(
                      product.storeName.isNotEmpty ? product.storeName[0] : 'S',
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
                        product.storeName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 8, color: Colors.white),
                      ),
                      const Spacer(),
                      const Icon(Iconsax.arrow_right_3, size: 16, color: Colors.grey),
                    ],
                  ),
                  Text(
                    'Verified Seller • Tap to view store',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _messageStore(product.storeName),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black,
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

  Widget _buildDynamicSpecs() {
    final product = _product!;
    final specs = product.specs;
    
    if (specs.isEmpty) return const SizedBox.shrink();
    
    final List<Widget> specWidgets = [];
    
    // Color selection (if available)
    if (specs['color'] != null) {
      specWidgets.add(_buildColorSelector(specs['color']));
      specWidgets.add(const SizedBox(height: 20));
    }
    
    // Size selection (if available)
    if (specs['size'] != null) {
      specWidgets.add(_buildSizeSelector('Size', specs['size'], 'size'));
      specWidgets.add(const SizedBox(height: 20));
    }
    
    // Shoe size US (if available)
    if (specs['sizeUS'] != null) {
      specWidgets.add(_buildSizeSelector('Size (US)', specs['sizeUS'], 'sizeUS'));
      specWidgets.add(const SizedBox(height: 20));
    }
    
    // Other specs as info rows
    final displaySpecs = <String, dynamic>{};
    specs.forEach((key, value) {
      // Skip already displayed specs
      if (['color', 'size', 'sizeUS'].contains(key)) return;
      // Skip empty values
      if (value == null || (value is String && value.isEmpty)) return;
      if (value is List && value.isEmpty) return;
      
      displaySpecs[key] = value;
    });
    
    if (displaySpecs.isNotEmpty) {
      specWidgets.add(_buildSpecsInfo(displaySpecs));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: specWidgets,
    );
  }

  Widget _buildColorSelector(dynamic colorValue) {
    List<String> colors = [];
    
    if (colorValue is List) {
      colors = colorValue.map((e) => e.toString()).toList();
    } else if (colorValue is String) {
      colors = [colorValue];
    }
    
    if (colors.isEmpty) return const SizedBox.shrink();
    
    final selectedColor = _selectedValues['color'] ?? colors.first;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Color',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            Text(
              selectedColor,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((color) {
            final isSelected = selectedColor == color;
            final colorCode = _getColorCode(color);
            
            return GestureDetector(
              onTap: () => setState(() => _selectedValues['color'] = color),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                ),
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorCode,
                      shape: BoxShape.circle,
                      border: colorCode == Colors.white 
                          ? Border.all(color: Colors.grey[300]!) 
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getColorCode(String colorName) {
    final colorMap = {
      'black': Colors.black,
      'white': Colors.white,
      'gray': Colors.grey,
      'grey': Colors.grey,
      'silver': const Color(0xFFC0C0C0),
      'red': Colors.red,
      'blue': Colors.blue,
      'navy': const Color(0xFF000080),
      'green': Colors.green,
      'yellow': Colors.yellow,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'pink': Colors.pink,
      'brown': Colors.brown,
      'beige': const Color(0xFFF5F5DC),
      'gold': const Color(0xFFFFD700),
      'rose gold': const Color(0xFFB76E79),
      'multi-color': Colors.grey,
    };
    
    return colorMap[colorName.toLowerCase()] ?? Colors.grey;
  }

  Widget _buildSizeSelector(String label, dynamic sizeValue, String key) {
    List<String> sizes = [];
    
    if (sizeValue is List) {
      sizes = sizeValue.map((e) => e.toString()).toList();
    } else if (sizeValue is String) {
      sizes = [sizeValue];
    }
    
    if (sizes.isEmpty) return const SizedBox.shrink();
    
    // If only one size, just show it as info
    if (sizes.length == 1) {
      return _buildInfoRow(label, sizes.first);
    }
    
    final selectedSize = _selectedValues[key] ?? sizes.first;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            Text(
              selectedSize,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: sizes.map((size) {
            final isSelected = selectedSize == size;
            
            return GestureDetector(
              onTap: () => setState(() => _selectedValues[key] = size),
              child: Container(
                constraints: const BoxConstraints(minWidth: 48),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey[300]!,
                  ),
                ),
                child: Center(
                  child: Text(
                    size,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpecsInfo(Map<String, dynamic> specs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specifications',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: specs.entries.map((entry) {
              final label = _formatLabel(entry.key);
              final value = _formatValue(entry.value);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
        ),
      ],
    );
  }

  String _formatLabel(String key) {
    // Convert camelCase to Title Case
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ')
        .trim();
  }

  String _formatValue(dynamic value) {
    if (value is List) {
      return value.join(', ');
    }
    return value.toString();
  }

  Widget _buildPriceSection(String formattedPrice) {
    final product = _product!;
    
    return Row(
      children: [
        // Compare price (strikethrough)
        if (product.compareAtPrice != null && product.compareAtPrice! > product.price)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              _currencyService.formatPrice(product.compareAtPrice!, product.currency),
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[500],
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
        
        // Add to cart button with price
        Expanded(
          child: ElevatedButton(
            onPressed: product.isInStock
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added to cart', style: GoogleFonts.poppins()),
                        backgroundColor: Colors.black,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.shopping_bag, size: 20),
                const SizedBox(width: 8),
                Text(
                  product.isInStock ? formattedPrice : 'Out of Stock',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        
        // Rating
        if (product.rating > 0) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  product.rating.toStringAsFixed(1),
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                const Icon(Iconsax.star1, size: 16, color: Color(0xFFFFD700)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _messageStore(String storeName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          userName: storeName,
          userAvatar: storeName.isNotEmpty ? storeName[0] : 'S',
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

  Widget _buildReviewsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.message_text, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '${_product?.reviewCount ?? 0} Reviews',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.message_question, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Questions',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
