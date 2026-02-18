import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/currency_service.dart';
import '../services/product_questions_service.dart';
import '../services/messages_service.dart';
import '../services/wishlist_service.dart';
import '../services/cart_service.dart';
import 'store_profile_screen.dart';
import 'main_screen.dart';

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
  final ProductQuestionsService _questionsService = ProductQuestionsService();
  final WishlistService _wishlistService = WishlistService();
  final CartService _cartService = CartService();
  
  Product? _product;
  bool _isLoading = true;
  String? _error;
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  int _questionCount = 0;
  String _userCurrency = 'UGX';
  
  // Selected variant values
  final Map<String, dynamic> _selectedValues = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserCurrency();
    _loadProduct();
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
            _loadQuestionCount();
            _checkIfInWishlist();
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

  Future<void> _checkIfInWishlist() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || _product == null) return;
    
    final isInWishlist = await _wishlistService.isInWishlist(
      userId: userId,
      productId: widget.productId,
    );
    
    if (mounted) {
      setState(() => _isFavorite = isInWishlist);
    }
  }

  Future<void> _toggleWishlist() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please sign in to save products', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_product == null) return;
    
    // Optimistic UI update - update immediately
    final willBeAdded = !_isFavorite;
    setState(() => _isFavorite = willBeAdded);
    
    // Show immediate feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            willBeAdded ? 'Added to wishlist' : 'Removed from wishlist',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.black,
          duration: const Duration(seconds: 1),
        ),
      );
    }
    
    // Process in background
    try {
      await _wishlistService.toggleWishlist(
        userId: userId,
        productId: widget.productId,
        storeId: widget.storeId,
        productName: _product!.name,
        productImage: _product!.primaryImageUrl,
        price: _product!.price,
        currency: _product!.currency,
        storeName: _product!.storeName,
        isInStock: _product!.isInStock,
      );
    } catch (e) {
      // Revert UI on error
      if (mounted) {
        setState(() => _isFavorite = !willBeAdded);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update wishlist', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadQuestionCount() async {
    if (_product == null) return;
    final count = await _questionsService.getQuestionCount(
      storeId: widget.storeId,
      productId: widget.productId,
    );
    if (mounted) {
      setState(() => _questionCount = count);
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
            onPressed: _toggleWishlist,
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
              Tab(text: 'Questions $_questionCount'),
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
    final convertedPrice = _currencyService.convertPrice(product.price, product.currency, _userCurrency);
    final formattedPrice = _currencyService.formatPrice(convertedPrice, _userCurrency);
    
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
                      const Spacer(),
                      const Icon(Iconsax.arrow_right_3, size: 16, color: Colors.grey),
                    ],
                  ),
                  Text(
                    'Tap to view store',
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
              final value = _formatValue(entry.value, entry.key);
              
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
    // Special case mappings
    final labelMap = {
      'expiryDate': 'Expiry Date',
      'weight': 'Weight',
      'halalCertified': 'Halal Certified',
      'organic': 'Organic',
      'storage': 'Storage',
      'type': 'Type',
    };
    
    if (labelMap.containsKey(key)) {
      return labelMap[key]!;
    }
    
    // Convert camelCase to Title Case
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ')
        .trim();
  }

  String _formatValue(dynamic value, String key) {
    // Handle boolean values
    if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    
    // Handle Timestamp for expiry date
    if (key == 'expiryDate' && value is Timestamp) {
      final date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    
    // Handle weight - add kg unit
    if (key == 'weight' && value != null) {
      return '$value kg';
    }
    
    // Handle lists
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
              _currencyService.formatPrice(
                _currencyService.convertPrice(product.compareAtPrice!, product.currency, _userCurrency),
                _userCurrency,
              ),
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
                ? () async {
                    print('🛒 Add to Cart button pressed!');
                    print('Product: ${product.name}, InStock: ${product.isInStock}');
                    try {
                      await _cartService.addToCart(
                        productId: widget.productId,
                        storeId: widget.storeId,
                        storeName: product.storeName,
                        productName: product.name,
                        productImage: product.images.isNotEmpty ? product.images.first.url : '',
                        price: product.price, // Store seller's original price
                        currency: product.currency,
                        quantity: 1,
                      );
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added to cart', style: GoogleFonts.poppins()),
                            backgroundColor: Colors.black,
                            behavior: SnackBarBehavior.floating,
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
        // Debug info
        if (!product.isInStock)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'DEBUG: Stock=${product.stock}, TrackInventory=${product.trackInventory}',
              style: TextStyle(color: Colors.red, fontSize: 10),
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
    _openChat();
  }

  Future<void> _openChat() async {
    final product = _product!;
    final userId = FirebaseAuth.instance.currentUser?.uid;
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.black)),
      );

      String userName = 'User';
      String? userPhotoUrl;
      
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        final userData = userDoc.data();
        if (userData != null && userData['name'] != null && (userData['name'] as String).isNotEmpty) {
          userName = userData['name'];
        }
        userPhotoUrl = userData?['photoUrl'] as String?;
      } catch (e) {
        print('Error fetching user: $e');
      }
      
      if (userName == 'User' && FirebaseAuth.instance.currentUser?.displayName != null) {
        userName = FirebaseAuth.instance.currentUser!.displayName!;
      }
      
      if (userName == 'User' && FirebaseAuth.instance.currentUser?.email != null) {
        userName = FirebaseAuth.instance.currentUser!.email!.split('@')[0];
      }

      final messagesService = MessagesService();
      final conversationId = await messagesService.getOrCreateConversation(
        storeId: product.storeId,
        storeName: product.storeName,
        storeLogoUrl: product.storeLogo,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
      );

      if (mounted) Navigator.pop(context);

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ChatScreen(
              conversationId: conversationId,
              storeName: product.storeName,
              storeLogoUrl: product.storeLogo,
              userId: userId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open chat', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    final user = FirebaseAuth.instance.currentUser;
    
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _questionsService.getProductQuestions(
              storeId: widget.storeId,
              productId: widget.productId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.black),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.message_question, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No questions yet',
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to ask a question',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                );
              }

              final questions = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  final createdAt = question['createdAt'] as Timestamp?;
                  final timeAgo = createdAt != null
                      ? _questionsService.getTimeAgo(createdAt)
                      : '';
                  final hasAnswer = question['answer'] != null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Iconsax.message_question, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    question['question'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${question['userName']} • $timeAgo',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        // Answer
                        if (hasAnswer) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Iconsax.message_text, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        question['answer'] ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Store',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        
        // Ask Question Button
        if (user != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showAskQuestionDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.message_add, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Ask a Question',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showAskQuestionDialog() {
    final questionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ask a Question', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: questionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Type your question here...',
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (questionController.text.trim().isEmpty) return;
              
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              
              await _questionsService.askQuestion(
                storeId: widget.storeId,
                productId: widget.productId,
                userId: user.uid,
                userName: user.displayName ?? 'User',
                userPhotoUrl: user.photoURL,
                question: questionController.text.trim(),
              );
              
              if (mounted) {
                Navigator.pop(context);
                _loadQuestionCount();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Question submitted', style: GoogleFonts.poppins()),
                    backgroundColor: Colors.black,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: Text('Submit', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
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
            Text(widget.storeName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black)),
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
                  onTap: () async {
                    if (_messageController.text.trim().isEmpty) return;
                    await _messagesService.sendMessage(
                      conversationId: widget.conversationId,
                      senderId: widget.userId,
                      text: _messageController.text.trim(),
                    );
                    _messageController.clear();
                  },
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
}
