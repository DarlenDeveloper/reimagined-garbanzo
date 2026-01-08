import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../data/category_taxonomy.dart';
import '../models/product.dart';
import '../services/currency_service.dart';
import '../services/product_service.dart';
import '../services/store_service.dart';
import '../services/image_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _currencyService = CurrencyService();
  final _productService = ProductService();
  final _storeService = StoreService();

  String? _storeId;
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<Product>>? _productsSubscription;

  @override
  void initState() {
    super.initState();
    _currencyService.init();
    _initializeStore();
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeStore() async {
    try {
      final storeId = await _storeService.getUserStoreId();
      if (storeId == null) {
        setState(() {
          _error = 'No store found. Please create a store first.';
          _isLoading = false;
        });
        return;
      }

      setState(() => _storeId = storeId);
      
      // Initialize currency service with store ID
      await _currencyService.init(storeId);
      
      _subscribeToProducts();
    } catch (e) {
      setState(() {
        _error = 'Failed to load store: $e';
        _isLoading = false;
      });
    }
  }

  void _subscribeToProducts() {
    if (_storeId == null) return;

    _productsSubscription?.cancel();
    _productsSubscription = _productService
        .getProductsStream(_storeId!, limit: 100)
        .listen(
      (products) {
        if (mounted) {
          setState(() {
            _products = products;
            _isLoading = false;
            _error = null;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _error = 'Failed to load products: $e';
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _refreshProducts() async {
    if (_storeId == null) return;
    setState(() => _isLoading = true);
    _subscribeToProducts();
  }

  void _showAddProductSheet() {
    if (_storeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Store not loaded', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddProductSheet(
        storeId: _storeId!,
        productService: _productService,
        currencyService: _currencyService,
      ),
    );
  }

  void _showProductDetails(Product product) {
    final category = CategoryTaxonomy.getCategoryById(product.categoryId);
    final formattedPrice = _currencyService.formatPrice(product.price);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    image: product.primaryImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(product.primaryImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: product.primaryImageUrl == null
                      ? Center(
                          child: Icon(
                            category?.icon ?? Iconsax.box,
                            size: 28,
                            color: Colors.black,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        formattedPrice,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stock info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoItem('Stock', '${product.stock}'),
                  _infoItem('Sold', '${product.totalSold}'),
                  _infoItem('Status', product.isActive ? 'Active' : 'Inactive'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _actionButton(Iconsax.edit, 'Edit', () {
                    Navigator.pop(context);
                    _showEditProductSheet(product);
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(Iconsax.copy, 'Duplicate', () async {
                    Navigator.pop(context);
                    await _duplicateProduct(product);
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    Iconsax.trash,
                    'Delete',
                    () async {
                      Navigator.pop(context);
                      await _deleteProduct(product);
                    },
                    isDestructive: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Future<void> _duplicateProduct(Product product) async {
    try {
      await _productService.duplicateProduct(_storeId!, product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product duplicated', style: GoogleFonts.poppins()),
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to duplicate: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete "${product.name}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _productService.deleteProduct(_storeId!, product.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product deleted', style: GoogleFonts.poppins()),
              backgroundColor: Colors.black,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e', style: GoogleFonts.poppins()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showEditProductSheet(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProductSheet(
        storeId: _storeId!,
        product: product,
        productService: _productService,
        currencyService: _currencyService,
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withAlpha(25) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isDestructive ? Colors.red : Colors.black, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDestructive ? Colors.red : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductSheet,
        backgroundColor: Colors.black,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Products',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Iconsax.search_normal, color: Colors.black, size: 22),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Iconsax.filter, color: Colors.black, size: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.warning_2, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _refreshProducts,
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
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshProducts,
      color: Colors.black,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _products.length,
        itemBuilder: (context, index) => _ProductItem(
          product: _products[index],
          onTap: () => _showProductDetails(_products[index]),
          currencyService: _currencyService,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.box, size: 48, color: Colors.grey[400]),
            ),
            const SizedBox(height: 32),
            Text(
              'Add your products',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'To start selling on Purl, add your products or import from another platform.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _showAddProductSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Add your products',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============ PRODUCT ITEM ============
class _ProductItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final CurrencyService currencyService;

  const _ProductItem({
    required this.product,
    required this.onTap,
    required this.currencyService,
  });

  @override
  Widget build(BuildContext context) {
    final category = CategoryTaxonomy.getCategoryById(product.categoryId);
    final status = product.stockStatus;
    final statusColor = status == 'In Stock'
        ? Colors.black
        : status == 'Low Stock'
            ? Colors.orange[700]!
            : Colors.grey[500]!;
    final formattedPrice = currencyService.formatPrice(product.price);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                image: product.primaryImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(product.primaryImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.primaryImageUrl == null
                  ? Center(
                      child: Icon(
                        category?.icon ?? Iconsax.box,
                        size: 24,
                        color: Colors.black,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$formattedPrice • ${product.stock} in stock',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                product.isActive ? status : 'Inactive',
                style: GoogleFonts.poppins(
                  color: product.isActive ? statusColor : Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============ ADD PRODUCT SHEET ============
class _AddProductSheet extends StatefulWidget {
  final String storeId;
  final ProductService productService;
  final CurrencyService currencyService;

  const _AddProductSheet({
    required this.storeId,
    required this.productService,
    required this.currencyService,
  });

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  // Form controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Image picker
  final _imageService = ImageService();
  final List<XFile> _selectedImages = [];
  bool _isUploadingImages = false;

  // Category selection state
  Category? _selectedCategory;
  Subcategory? _selectedSubcategory;
  ProductType? _selectedProductType;
  String? _selectedCondition;

  // Dynamic attributes storage
  final Map<String, dynamic> _attributes = {};

  // Multi-select state for attributes
  final Map<String, List<String>> _multiSelectValues = {};

  int _currentStep = 0; // 0: Category, 1: Details, 2: Attributes
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _resetSelections({bool keepCategory = false}) {
    setState(() {
      if (!keepCategory) {
        _selectedCategory = null;
      }
      _selectedSubcategory = null;
      _selectedProductType = null;
      _selectedCondition = null;
      _attributes.clear();
      _multiSelectValues.clear();
    });
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in required fields', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate required attributes
    if (_selectedProductType != null) {
      for (final attr in _selectedProductType!.attributes.where((a) => a.required)) {
        if (attr.type == AttributeType.multiSelect) {
          if (_multiSelectValues[attr.name]?.isEmpty ?? true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please fill in ${attr.label}', style: GoogleFonts.poppins()),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        } else if (_attributes[attr.name] == null || _attributes[attr.name].toString().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please fill in ${attr.label}', style: GoogleFonts.poppins()),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    setState(() => _isSaving = true);

    try {
      // Merge attributes and multi-select values
      final specs = <String, dynamic>{};
      specs.addAll(_attributes);
      specs.addAll(_multiSelectValues);

      // First create the product to get the ID
      final productId = await widget.productService.createProduct(
        storeId: widget.storeId,
        name: _nameController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0,
        categoryId: _selectedCategory?.id ?? 'other',
        subcategoryId: _selectedSubcategory?.id,
        productTypeId: _selectedProductType?.id,
        condition: _selectedCondition,
        description: _descriptionController.text.trim(),
        currency: widget.currencyService.currentCurrency,
        specs: specs,
        stock: int.tryParse(_stockController.text) ?? 0,
        isActive: true,
      );

      // Upload images if any were selected
      if (_selectedImages.isNotEmpty) {
        setState(() => _isUploadingImages = true);
        
        try {
          final uploadedImages = await _imageService.uploadProductImages(
            storeId: widget.storeId,
            productId: productId,
            files: _selectedImages,
          );

          // Update product with image URLs
          if (uploadedImages.isNotEmpty) {
            await widget.productService.updateImages(
              widget.storeId,
              productId,
              uploadedImages,
            );
          }
        } catch (imageError) {
          // Product was created but images failed - show warning but don't fail
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Product created but images failed to upload', style: GoogleFonts.poppins()),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product added', style: GoogleFonts.poppins()),
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add product: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingImages = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          _buildStepIndicator(),
          Expanded(child: _buildCurrentStep()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        if (_currentStep > 0) {
                          setState(() => _currentStep--);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                child: Text(
                  _currentStep > 0 ? 'Back' : 'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              ),
              Text(
                'Add Product',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        if (_currentStep < 2) {
                          if (_currentStep == 0 && _selectedProductType == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please select a product type', style: GoogleFonts.poppins()),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          setState(() => _currentStep++);
                        } else {
                          _saveProduct();
                        }
                      },
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        _currentStep < 2 ? 'Next' : 'Save',
                        style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _stepDot(0, 'Category'),
          _stepLine(0),
          _stepDot(1, 'Details'),
          _stepLine(1),
          _stepDot(2, 'Attributes'),
        ],
      ),
    );
  }

  Widget _stepDot(int step, String label) {
    final isActive = _currentStep >= step;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isActive ? Colors.black : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isActive && _currentStep > step
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      '${step + 1}',
                      style: GoogleFonts.poppins(
                        color: isActive ? Colors.white : Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isActive ? Colors.black : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepLine(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: isActive ? Colors.black : Colors.grey[200],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildCategoryStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildAttributesStep();
      default:
        return const SizedBox();
    }
  }


  // ============ STEP 1: CATEGORY SELECTION ============
  Widget _buildCategoryStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Select Category', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _buildCategoryGrid(),
        if (_selectedCategory != null) ...[
          const SizedBox(height: 24),
          Text('Select Subcategory', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildSubcategoryList(),
        ],
        if (_selectedSubcategory != null) ...[
          const SizedBox(height: 24),
          Text('Select Product Type', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildProductTypeList(),
        ],
        if (_selectedProductType != null) ...[
          const SizedBox(height: 24),
          Text('Select Condition', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildConditionChips(),
        ],
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: CategoryTaxonomy.categories.length,
      itemBuilder: (context, index) {
        final category = CategoryTaxonomy.categories[index];
        final isSelected = _selectedCategory?.id == category.id;
        return GestureDetector(
          onTap: () {
            _resetSelections();
            setState(() => _selectedCategory = category);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? null : Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon, size: 28, color: isSelected ? Colors.white : Colors.black),
                const SizedBox(height: 8),
                Text(
                  category.name.split(' ').first,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubcategoryList() {
    return Column(
      children: _selectedCategory!.subcategories.map((sub) {
        final isSelected = _selectedSubcategory?.id == sub.id;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSubcategory = sub;
              _selectedProductType = null;
              _selectedCondition = null;
              _attributes.clear();
              _multiSelectValues.clear();
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    sub.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: isSelected ? Colors.white : Colors.grey[400]),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProductTypeList() {
    return Column(
      children: _selectedSubcategory!.productTypes.map((type) {
        final isSelected = _selectedProductType?.id == type.id;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedProductType = type;
              _selectedCondition = type.allowedConditions.first;
              _attributes.clear();
              _multiSelectValues.clear();
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        '${type.attributes.where((a) => a.required).length} required fields',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isSelected ? Colors.white70 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, color: isSelected ? Colors.white : Colors.transparent),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConditionChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedProductType!.allowedConditions.map((condition) {
        final isSelected = _selectedCondition == condition;
        return GestureDetector(
          onTap: () => setState(() => _selectedCondition = condition),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              condition,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============ STEP 2: PRODUCT DETAILS ============
  Widget _buildDetailsStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Category summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(_selectedCategory?.icon ?? Iconsax.box, size: 24, color: Colors.black),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedProductType?.name ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    Text(
                      '${_selectedCategory?.name} › ${_selectedSubcategory?.name}',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  _selectedCondition ?? '',
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Product Name
        _buildTextField('Product Name *', _nameController, 'Enter product name'),
        const SizedBox(height: 16),

        // Price and Stock row
        Row(
          children: [
            Expanded(child: _buildTextField('Price (${widget.currencyService.currentCurrency}) *', _priceController, '0', keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('Stock Qty *', _stockController, '0', keyboardType: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 24),

        // Image upload placeholder
        Text('Product Images', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        _buildImagePicker(),
        const SizedBox(height: 24),

        // Description
        Text('Description', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: InputDecoration.collapsed(
              hintText: 'Describe your product...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            style: GoogleFonts.poppins(),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            style: GoogleFonts.poppins(),
          ),
        ),
      ],
    );
  }

  // ============ IMAGE PICKER ============
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 10 images allowed', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final remaining = 10 - _selectedImages.length;
      final images = await _imageService.pickMultipleImages(limit: remaining);
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected images grid
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length + (_selectedImages.length < 10 ? 1 : 0),
              itemBuilder: (context, index) {
                // Add button at the end
                if (index == _selectedImages.length) {
                  return _buildAddImageButton();
                }
                
                // Image preview
                return _buildImagePreview(index);
              },
            ),
          ),
        ] else ...[
          // Empty state - tap to add
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.gallery_add, size: 32, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to add images',
                    style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13),
                  ),
                  Text(
                    'Up to 10 images',
                    style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImagePreview(int index) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: FileImage(File(_selectedImages[index].path)),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Image number badge
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(150),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${index + 1}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Remove button
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.add, size: 24, color: Colors.grey[500]),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ============ STEP 3: DYNAMIC ATTRIBUTES ============
  Widget _buildAttributesStep() {
    if (_selectedProductType == null) {
      return Center(child: Text('No product type selected', style: GoogleFonts.poppins()));
    }

    final requiredAttrs = _selectedProductType!.attributes.where((a) => a.required).toList();
    final optionalAttrs = _selectedProductType!.attributes.where((a) => !a.required).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.withAlpha(20), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(Iconsax.info_circle, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Fill in the attributes to help buyers find your product',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Required attributes
        if (requiredAttrs.isNotEmpty) ...[
          Text('Required Fields', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...requiredAttrs.map((attr) => _buildAttributeField(attr)),
        ],

        // Optional attributes
        if (optionalAttrs.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Optional Fields',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          ...optionalAttrs.map((attr) => _buildAttributeField(attr)),
        ],

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildAttributeField(ProductAttribute attr) {
    Widget field;

    switch (attr.type) {
      case AttributeType.select:
        field = _buildSelectField(attr);
        break;
      case AttributeType.multiSelect:
        field = _buildMultiSelectField(attr);
        break;
      case AttributeType.text:
        field = _buildTextAttributeField(attr);
        break;
      case AttributeType.number:
        field = _buildTextAttributeField(attr, isNumber: true);
        break;
      case AttributeType.boolean:
        field = _buildBooleanField(attr);
        break;
      case AttributeType.date:
        field = _buildDateField(attr);
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: field,
    );
  }

  Widget _buildSelectField(ProductAttribute attr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${attr.label}${attr.required ? ' *' : ''}',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _attributes[attr.name] as String?,
              isExpanded: true,
              hint: Text('Select ${attr.label}', style: GoogleFonts.poppins(color: Colors.grey[400])),
              style: GoogleFonts.poppins(color: Colors.black),
              items: attr.options?.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
              onChanged: (v) => setState(() => _attributes[attr.name] = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectField(ProductAttribute attr) {
    final selected = _multiSelectValues[attr.name] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${attr.label}${attr.required ? ' *' : ''}',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showMultiSelectDialog(attr),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: selected.isEmpty
                      ? Text('Select ${attr.label}', style: GoogleFonts.poppins(color: Colors.grey[400]))
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: selected
                              .map((s) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
                                    child: Text(s, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white)),
                                  ))
                              .toList(),
                        ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showMultiSelectDialog(ProductAttribute attr) {
    final tempSelected = List<String>.from(_multiSelectValues[attr.name] ?? []);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select ${attr.label}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () {
                      setState(() => _multiSelectValues[attr.name] = tempSelected);
                      Navigator.pop(context);
                    },
                    child: Text('Done', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 300,
              child: ListView(
                children: attr.options?.map((opt) {
                      final isSelected = tempSelected.contains(opt);
                      return ListTile(
                        title: Text(opt, style: GoogleFonts.poppins()),
                        trailing: isSelected ? const Icon(Icons.check, color: Colors.black) : null,
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              tempSelected.remove(opt);
                            } else {
                              tempSelected.add(opt);
                            }
                          });
                        },
                      );
                    }).toList() ??
                    [],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextAttributeField(ProductAttribute attr, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${attr.label}${attr.required ? ' *' : ''}',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: TextField(
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: attr.hint ?? 'Enter ${attr.label}',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            style: GoogleFonts.poppins(),
            onChanged: (v) => _attributes[attr.name] = v,
          ),
        ),
      ],
    );
  }

  Widget _buildBooleanField(ProductAttribute attr) {
    final value = _attributes[attr.name] as bool? ?? false;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${attr.label}${attr.required ? ' *' : ''}',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Switch(
          value: value,
          activeTrackColor: Colors.black,
          onChanged: (v) => setState(() => _attributes[attr.name] = v),
        ),
      ],
    );
  }

  Widget _buildDateField(ProductAttribute attr) {
    final date = _attributes[attr.name] as DateTime?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${attr.label}${attr.required ? ' *' : ''}',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            );
            if (picked != null) {
              setState(() => _attributes[attr.name] = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null ? '${date.day}/${date.month}/${date.year}' : 'Select date',
                    style: GoogleFonts.poppins(color: date != null ? Colors.black : Colors.grey[400]),
                  ),
                ),
                Icon(Iconsax.calendar, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


// ============ EDIT PRODUCT SHEET ============
class _EditProductSheet extends StatefulWidget {
  final String storeId;
  final Product product;
  final ProductService productService;
  final CurrencyService currencyService;

  const _EditProductSheet({
    required this.storeId,
    required this.product,
    required this.productService,
    required this.currencyService,
  });

  @override
  State<_EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<_EditProductSheet> {
  final _imageService = ImageService();
  
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;
  
  final List<XFile> _newImages = [];
  List<ProductImage> _existingImages = [];
  List<String> _imagesToDelete = [];
  
  bool _isActive = true;
  bool _isSaving = false;
  bool _isUploadingImages = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _stockController = TextEditingController(text: widget.product.stock.toString());
    _descriptionController = TextEditingController(text: widget.product.description);
    _existingImages = List.from(widget.product.images);
    _isActive = widget.product.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final totalImages = _existingImages.length + _newImages.length;
    if (totalImages >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 10 images allowed', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final remaining = 10 - totalImages;
      final images = await _imageService.pickMultipleImages(limit: remaining);
      
      if (images.isNotEmpty) {
        setState(() {
          _newImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _imagesToDelete.add(_existingImages[index].url);
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in required fields', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Upload new images if any
      List<ProductImage> allImages = List.from(_existingImages);
      
      if (_newImages.isNotEmpty) {
        setState(() => _isUploadingImages = true);
        
        final uploadedImages = await _imageService.uploadProductImages(
          storeId: widget.storeId,
          productId: widget.product.id,
          files: _newImages,
        );
        
        // Adjust sort order for new images
        for (int i = 0; i < uploadedImages.length; i++) {
          allImages.add(ProductImage(
            url: uploadedImages[i].url,
            sortOrder: allImages.length,
          ));
        }
      }

      // Delete removed images from storage
      for (final url in _imagesToDelete) {
        await _imageService.deleteProductImage(
          storeId: widget.storeId,
          productId: widget.product.id,
          imageUrl: url,
        );
      }

      // Update product
      await widget.productService.updateProduct(
        widget.storeId,
        widget.product.id,
        {
          'name': _nameController.text.trim(),
          'price': double.tryParse(_priceController.text) ?? 0,
          'stock': int.tryParse(_stockController.text) ?? 0,
          'description': _descriptionController.text.trim(),
          'isActive': _isActive,
          'images': allImages.map((e) => e.toMap()).toList(),
        },
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product updated', style: GoogleFonts.poppins()),
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingImages = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = CategoryTaxonomy.getCategoryById(widget.product.categoryId);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Category info (read-only)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(category?.icon ?? Iconsax.box, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.productTypeId ?? widget.product.categoryId,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            if (widget.product.condition != null)
                              Text(
                                widget.product.condition!,
                                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Product Name
                _buildTextField('Product Name *', _nameController, 'Enter product name'),
                const SizedBox(height: 16),

                // Price and Stock
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Price (${widget.currencyService.currentCurrency}) *',
                        _priceController,
                        '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        'Stock Qty *',
                        _stockController,
                        '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Images
                Text(
                  'Product Images',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _buildImageEditor(),
                const SizedBox(height: 24),

                // Description
                Text(
                  'Description',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration.collapsed(
                      hintText: 'Describe your product...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                    ),
                    style: GoogleFonts.poppins(),
                  ),
                ),
                const SizedBox(height: 24),

                // Active toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Active',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            _isActive ? 'Visible to customers' : 'Hidden from store',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isActive,
                        activeTrackColor: Colors.black,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              ),
              Text(
                'Edit Product',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: _isSaving ? null : _saveProduct,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        'Save',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            style: GoogleFonts.poppins(),
          ),
        ),
      ],
    );
  }

  Widget _buildImageEditor() {
    final totalImages = _existingImages.length + _newImages.length;
    
    if (totalImages == 0) {
      return GestureDetector(
        onTap: _pickImages,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.gallery_add, size: 32, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Tap to add images',
                style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalImages + (totalImages < 10 ? 1 : 0),
        itemBuilder: (context, index) {
          // Add button at the end
          if (index == totalImages) {
            return GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.add, size: 24, color: Colors.grey[500]),
                    const SizedBox(height: 4),
                    Text('Add', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
            );
          }

          // Existing images
          if (index < _existingImages.length) {
            return _buildExistingImagePreview(index);
          }

          // New images
          final newIndex = index - _existingImages.length;
          return _buildNewImagePreview(newIndex);
        },
      ),
    );
  }

  Widget _buildExistingImagePreview(int index) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(_existingImages[index].url),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(150),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${index + 1}',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: () => _removeExistingImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewImagePreview(int index) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: FileImage(File(_newImages[index].path)),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(200),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'New',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: () => _removeNewImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
