import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/store_service.dart';
import '../services/currency_service.dart';
import '../data/category_taxonomy.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _productService = ProductService();
  final _storeService = StoreService();
  final _currencyService = CurrencyService();

  String? _storeId;
  List<Product> _products = [];
  List<Product> _lowStockProducts = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<Product>>? _productsSubscription;
  String _filter = 'all'; // 'all', 'low', 'out'

  @override
  void initState() {
    super.initState();
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
        .getProductsStream(_storeId!, limit: 200)
        .listen(
      (products) {
        if (mounted) {
          setState(() {
            _products = products;
            _lowStockProducts = products.where((p) => 
              p.trackInventory && p.stock <= p.lowStockThreshold
            ).toList();
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

  List<Product> get _filteredProducts {
    switch (_filter) {
      case 'low':
        return _products.where((p) => 
          p.trackInventory && p.stock <= p.lowStockThreshold && p.stock > 0
        ).toList();
      case 'out':
        return _products.where((p) => p.trackInventory && p.stock == 0).toList();
      default:
        return _products;
    }
  }

  Future<void> _updateStock(Product product, int newStock) async {
    try {
      await _productService.updateStock(_storeId!, product.id, newStock);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock updated', style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFFfb2a0a),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update stock: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditStockDialog(Product product) {
    final controller = TextEditingController(text: product.stock.toString());
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
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
            Text(
              'Update Stock',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            
            // Quick adjust buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _quickAdjustButton('-10', () {
                  final current = int.tryParse(controller.text) ?? 0;
                  controller.text = (current - 10).clamp(0, 99999).toString();
                }),
                const SizedBox(width: 8),
                _quickAdjustButton('-1', () {
                  final current = int.tryParse(controller.text) ?? 0;
                  controller.text = (current - 1).clamp(0, 99999).toString();
                }),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _quickAdjustButton('+1', () {
                  final current = int.tryParse(controller.text) ?? 0;
                  controller.text = (current + 1).toString();
                }),
                const SizedBox(width: 8),
                _quickAdjustButton('+10', () {
                  final current = int.tryParse(controller.text) ?? 0;
                  controller.text = (current + 10).toString();
                }),
              ],
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final newStock = int.tryParse(controller.text) ?? 0;
                      Navigator.pop(context);
                      _updateStock(product, newStock);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFb71000),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Update',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _quickAdjustButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final outOfStockCount = _products.where((p) => p.trackInventory && p.stock == 0).length;
    
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
          'Inventory',
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.search_normal, color: Colors.black),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFfb2a0a)))
          : _error != null
              ? _buildErrorState()
              : _products.isEmpty
                  ? _buildEmptyState()
                  : _buildContent(outOfStockCount),
    );
  }

  Widget _buildErrorState() {
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
              onPressed: () {
                setState(() => _isLoading = true);
                _initializeStore();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFb71000),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Retry', style: GoogleFonts.poppins()),
            ),
          ],
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
            const SizedBox(height: 24),
            Text(
              'No products yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add products to manage inventory',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(int outOfStockCount) {
    return RefreshIndicator(
      onRefresh: () async {
        _subscribeToProducts();
      },
      color: const Color(0xFFfb2a0a),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Low stock alert
          if (_lowStockProducts.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.warning_2, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Low Stock Alert',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${_lowStockProducts.length} product${_lowStockProducts.length > 1 ? 's' : ''} need restocking',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _filter = 'low'),
                    child: Text(
                      'View',
                      style: GoogleFonts.poppins(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', 'all', _products.length),
                const SizedBox(width: 8),
                _filterChip('Low Stock', 'low', _lowStockProducts.length),
                const SizedBox(width: 8),
                _filterChip('Out of Stock', 'out', outOfStockCount),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Products list
          if (_filteredProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No products in this category',
                  style: GoogleFonts.poppins(color: Colors.grey[500]),
                ),
              ),
            )
          else
            ..._filteredProducts.map((product) => _InventoryItem(
              product: product,
              currencyService: _currencyService,
              onEdit: () => _showEditStockDialog(product),
            )),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, int count) {
    final isSelected = _filter == value;
    const double chipHeight = 40;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        height: chipHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFfb2a0a) : Colors.grey[100],
          borderRadius: BorderRadius.circular(chipHeight / 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withAlpha(50) : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============ INVENTORY ITEM ============
class _InventoryItem extends StatelessWidget {
  final Product product;
  final CurrencyService currencyService;
  final VoidCallback onEdit;

  const _InventoryItem({
    required this.product,
    required this.currencyService,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final category = CategoryTaxonomy.getCategoryById(product.categoryId);
    final isLowStock = product.trackInventory && product.stock <= product.lowStockThreshold && product.stock > 0;
    final isOutOfStock = product.trackInventory && product.stock == 0;

    Color stockColor;
    String stockText;
    if (isOutOfStock) {
      stockColor = Colors.red;
      stockText = 'Out of stock';
    } else if (isLowStock) {
      stockColor = Colors.orange;
      stockText = '${product.stock} left';
    } else {
      stockColor = Colors.green;
      stockText = '${product.stock} in stock';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Product image or icon
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
                Text(
                  currencyService.formatPrice(product.price),
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: stockColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              stockText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: stockColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Iconsax.edit_2, color: Colors.grey[600], size: 20),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}
