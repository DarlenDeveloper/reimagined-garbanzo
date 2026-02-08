import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

/// ProductService handles all product-related Firestore operations.
/// 
/// FIRESTORE STRUCTURE:
/// /stores/{storeId}/products/{productId}
/// 
/// Products are stored as a subcollection under stores for:
/// - Efficient queries (get all products for a store)
/// - Security rules (store owners can only access their products)
/// - Scalability (products are partitioned by store)
/// 
/// USAGE:
/// ```dart
/// final productService = ProductService();
/// 
/// // Create a product
/// final productId = await productService.createProduct(
///   storeId: 'store123',
///   name: 'iPhone 15',
///   price: 150000,
///   categoryId: 'electronics',
///   subcategoryId: 'cell_phones',
///   productTypeId: 'smartphones',
///   specs: {'brand': 'Apple', 'storage': '256GB'},
/// );
/// 
/// // Get all products for a store
/// final products = await productService.getProducts('store123');
/// 
/// // Update a product
/// await productService.updateProduct('store123', 'product123', {'price': 145000});
/// 
/// // Delete a product (soft delete)
/// await productService.deleteProduct('store123', 'product123');
/// ```
class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get reference to products collection for a store
  CollectionReference<Map<String, dynamic>> _productsRef(String storeId) {
    return _firestore.collection('stores').doc(storeId).collection('products');
  }

  /// Verify current user has access to the store
  Future<bool> _verifyStoreAccess(String storeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final store = await _firestore.collection('stores').doc(storeId).get();
    if (!store.exists) return false;

    final authorizedUsers = List<String>.from(store.data()?['authorizedUsers'] ?? []);
    return authorizedUsers.contains(uid);
  }

  // ============ CREATE ============

  /// Create a new product in the store.
  /// 
  /// Returns the newly created product's document ID.
  /// Throws exception if user doesn't have store access.
  Future<String> createProduct({
    required String storeId,
    required String name,
    required double price,
    required String categoryId,
    String? subcategoryId,
    String? productTypeId,
    String? condition,
    String description = '',
    String currency = 'KES',
    double? compareAtPrice,
    List<ProductImage> images = const [],
    List<ProductVariant> variants = const [],
    Map<String, dynamic> specs = const {},
    List<String> tags = const [],
    int stock = 0,
    int lowStockThreshold = 5,
    bool trackInventory = true,
    bool isActive = true,
    bool isPublished = false,
    bool isFeatured = false,
  }) async {
    // Verify access
    if (!await _verifyStoreAccess(storeId)) {
      throw Exception('Access denied: User does not have access to this store');
    }

    // Build category path
    String? categoryPath;
    if (subcategoryId != null && productTypeId != null) {
      categoryPath = '$categoryId/$subcategoryId/$productTypeId';
    } else if (subcategoryId != null) {
      categoryPath = '$categoryId/$subcategoryId';
    } else {
      categoryPath = categoryId;
    }

    // Create product document
    final productData = {
      'name': name,
      'slug': _generateSlug(name),
      'description': description,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'productTypeId': productTypeId,
      'categoryPath': categoryPath,
      'condition': condition,
      'price': price,
      'compareAtPrice': compareAtPrice,
      'currency': currency,
      'images': images.map((e) => e.toMap()).toList(),
      'variants': variants.map((e) => e.toMap()).toList(),
      'specs': specs,
      'tags': tags,
      'stock': stock,
      'lowStockThreshold': lowStockThreshold,
      'trackInventory': trackInventory,
      'isActive': isActive,
      'isPublished': isPublished,
      'isFeatured': isFeatured,
      'rating': 0.0,
      'reviewCount': 0,
      'totalSold': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _productsRef(storeId).add(productData);
    return docRef.id;
  }

  // ============ READ ============

  /// Get a single product by ID.
  /// Returns null if product doesn't exist.
  Future<Product?> getProductById(String storeId, String productId) async {
    final doc = await _productsRef(storeId).doc(productId).get();
    if (!doc.exists) return null;
    return Product.fromFirestore(doc, storeId);
  }

  /// Get all products for a store with optional filtering and pagination.
  /// 
  /// Parameters:
  /// - [storeId]: The store to fetch products from
  /// - [isActive]: Filter by active status (null = all)
  /// - [categoryId]: Filter by category
  /// - [limit]: Max number of products to return
  /// - [startAfter]: Document snapshot for pagination
  /// - [orderBy]: Field to order by ('createdAt', 'name', 'price', 'stock')
  /// - [descending]: Order direction
  Future<List<Product>> getProducts(
    String storeId, {
    bool? isActive,
    String? categoryId,
    int limit = 50,
    DocumentSnapshot? startAfter,
    String orderBy = 'createdAt',
    bool descending = true,
  }) async {
    Query<Map<String, dynamic>> query = _productsRef(storeId);

    // Apply filters
    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    // Apply ordering
    query = query.orderBy(orderBy, descending: descending);

    // Apply pagination
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    // Apply limit
    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc, storeId)).toList();
  }

  /// Get products stream for real-time updates.
  /// Useful for displaying live product list in UI.
  Stream<List<Product>> getProductsStream(
    String storeId, {
    bool? isActive,
    String? categoryId,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _productsRef(storeId);

    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc, storeId)).toList();
    });
  }

  /// Get low stock products (stock <= threshold).
  Future<List<Product>> getLowStockProducts(String storeId) async {
    // First get all products that track inventory
    final snapshot = await _productsRef(storeId)
        .where('trackInventory', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .get();

    // Filter in memory for low stock (Firestore doesn't support <= with dynamic field)
    return snapshot.docs
        .map((doc) => Product.fromFirestore(doc, storeId))
        .where((p) => p.stock <= p.lowStockThreshold)
        .toList();
  }

  /// Get out of stock products.
  Future<List<Product>> getOutOfStockProducts(String storeId) async {
    final snapshot = await _productsRef(storeId)
        .where('trackInventory', isEqualTo: true)
        .where('stock', isEqualTo: 0)
        .get();

    return snapshot.docs.map((doc) => Product.fromFirestore(doc, storeId)).toList();
  }

  /// Search products by name (basic search).
  /// For advanced search, consider using Algolia or similar.
  Future<List<Product>> searchProducts(
    String storeId,
    String query, {
    int limit = 20,
  }) async {
    if (query.isEmpty) return [];

    // Firestore doesn't support full-text search, so we use prefix matching
    final queryLower = query.toLowerCase();
    final snapshot = await _productsRef(storeId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .startAt([queryLower])
        .endAt(['$queryLower\uf8ff'])
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => Product.fromFirestore(doc, storeId)).toList();
  }

  /// Get product count for a store.
  Future<int> getProductCount(String storeId, {bool? isActive}) async {
    Query<Map<String, dynamic>> query = _productsRef(storeId);
    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }


  // ============ UPDATE ============

  /// Update a product with the given fields.
  /// Only the fields provided in [updates] will be modified.
  /// 
  /// Example:
  /// ```dart
  /// await productService.updateProduct('store123', 'product123', {
  ///   'price': 145000,
  ///   'stock': 50,
  ///   'isActive': true,
  /// });
  /// ```
  /// 
  /// NOTE: Low inventory notifications are automatically triggered by Cloud Function
  /// when stock falls below threshold (no manual trigger needed here).
  Future<void> updateProduct(
    String storeId,
    String productId,
    Map<String, dynamic> updates,
  ) async {
    // Verify access
    if (!await _verifyStoreAccess(storeId)) {
      throw Exception('Access denied: User does not have access to this store');
    }

    // Always update the updatedAt timestamp
    updates['updatedAt'] = FieldValue.serverTimestamp();

    // If name is being updated, regenerate slug
    if (updates.containsKey('name')) {
      updates['slug'] = _generateSlug(updates['name'] as String);
    }

    // If category fields are updated, rebuild categoryPath
    if (updates.containsKey('categoryId') || 
        updates.containsKey('subcategoryId') || 
        updates.containsKey('productTypeId')) {
      // Get current product to merge with updates
      final current = await getProductById(storeId, productId);
      if (current != null) {
        final categoryId = updates['categoryId'] as String? ?? current.categoryId;
        final subcategoryId = updates['subcategoryId'] as String? ?? current.subcategoryId;
        final productTypeId = updates['productTypeId'] as String? ?? current.productTypeId;
        
        if (subcategoryId != null && productTypeId != null) {
          updates['categoryPath'] = '$categoryId/$subcategoryId/$productTypeId';
        } else if (subcategoryId != null) {
          updates['categoryPath'] = '$categoryId/$subcategoryId';
        } else {
          updates['categoryPath'] = categoryId;
        }
      }
    }

    // Add storeId to updates so Cloud Function can access it
    updates['storeId'] = storeId;

    await _productsRef(storeId).doc(productId).update(updates);
    
    // Cloud Function onProductStockUpdate will automatically:
    // - Detect when stock <= lowStockThreshold
    // - Send low inventory notification to seller
    // - Save notification to Firestore
  }

  /// Update product from a Product object.
  /// Useful when you have a modified Product instance.
  Future<void> updateProductFromModel(Product product) async {
    final updates = product.toMap();
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _productsRef(product.storeId).doc(product.id).update(updates);
  }

  /// Toggle product active status.
  Future<void> toggleProductActive(String storeId, String productId) async {
    final product = await getProductById(storeId, productId);
    if (product == null) throw Exception('Product not found');

    await updateProduct(storeId, productId, {'isActive': !product.isActive});
  }

  /// Toggle product published status.
  Future<void> toggleProductPublished(String storeId, String productId) async {
    final product = await getProductById(storeId, productId);
    if (product == null) throw Exception('Product not found');

    final updates = <String, dynamic>{
      'isPublished': !product.isPublished,
    };

    // Set publishedAt timestamp when publishing
    if (!product.isPublished) {
      updates['publishedAt'] = FieldValue.serverTimestamp();
    }

    await updateProduct(storeId, productId, updates);
  }

  /// Toggle product featured status.
  Future<void> toggleProductFeatured(String storeId, String productId) async {
    final product = await getProductById(storeId, productId);
    if (product == null) throw Exception('Product not found');

    await updateProduct(storeId, productId, {'isFeatured': !product.isFeatured});
  }

  /// Update product stock.
  Future<void> updateStock(String storeId, String productId, int newStock) async {
    if (newStock < 0) throw Exception('Stock cannot be negative');
    await updateProduct(storeId, productId, {'stock': newStock});
  }

  /// Increment or decrement stock.
  /// Use negative value to decrement.
  Future<void> adjustStock(String storeId, String productId, int adjustment) async {
    await _productsRef(storeId).doc(productId).update({
      'stock': FieldValue.increment(adjustment),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Bulk update stock for multiple products.
  /// 
  /// Example:
  /// ```dart
  /// await productService.bulkUpdateStock('store123', {
  ///   'product1': 50,
  ///   'product2': 100,
  ///   'product3': 0,
  /// });
  /// ```
  Future<void> bulkUpdateStock(
    String storeId,
    Map<String, int> stockUpdates,
  ) async {
    if (!await _verifyStoreAccess(storeId)) {
      throw Exception('Access denied: User does not have access to this store');
    }

    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();

    for (final entry in stockUpdates.entries) {
      final docRef = _productsRef(storeId).doc(entry.key);
      batch.update(docRef, {
        'stock': entry.value,
        'updatedAt': timestamp,
      });
    }

    await batch.commit();
  }

  /// Update product images.
  Future<void> updateImages(
    String storeId,
    String productId,
    List<ProductImage> images,
  ) async {
    await updateProduct(storeId, productId, {
      'images': images.map((e) => e.toMap()).toList(),
    });
  }

  /// Add a single image to product.
  Future<void> addImage(
    String storeId,
    String productId,
    ProductImage image,
  ) async {
    await _productsRef(storeId).doc(productId).update({
      'images': FieldValue.arrayUnion([image.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update product specs (category-specific attributes).
  Future<void> updateSpecs(
    String storeId,
    String productId,
    Map<String, dynamic> specs,
  ) async {
    await updateProduct(storeId, productId, {'specs': specs});
  }

  // ============ DELETE ============

  /// Soft delete a product (sets isActive to false).
  /// Products are never hard-deleted to preserve order history.
  Future<void> deleteProduct(String storeId, String productId) async {
    if (!await _verifyStoreAccess(storeId)) {
      throw Exception('Access denied: User does not have access to this store');
    }

    await updateProduct(storeId, productId, {
      'isActive': false,
      'isPublished': false,
    });
  }

  /// Hard delete a product (permanently removes from Firestore).
  /// USE WITH CAUTION - this will break any order references.
  /// Only use for products that were never sold.
  Future<void> hardDeleteProduct(String storeId, String productId) async {
    if (!await _verifyStoreAccess(storeId)) {
      throw Exception('Access denied: User does not have access to this store');
    }

    // Check if product has any sales
    final product = await getProductById(storeId, productId);
    if (product != null && product.totalSold > 0) {
      throw Exception('Cannot hard delete a product that has been sold. Use soft delete instead.');
    }

    await _productsRef(storeId).doc(productId).delete();
  }

  // ============ DUPLICATE ============

  /// Duplicate a product with a new name.
  /// Returns the new product's ID.
  Future<String> duplicateProduct(
    String storeId,
    String productId, {
    String? newName,
  }) async {
    final original = await getProductById(storeId, productId);
    if (original == null) throw Exception('Product not found');

    final name = newName ?? '${original.name} (Copy)';

    return createProduct(
      storeId: storeId,
      name: name,
      price: original.price,
      categoryId: original.categoryId,
      subcategoryId: original.subcategoryId,
      productTypeId: original.productTypeId,
      condition: original.condition,
      description: original.description,
      currency: original.currency,
      compareAtPrice: original.compareAtPrice,
      images: original.images,
      variants: original.variants,
      specs: Map<String, dynamic>.from(original.specs),
      tags: List<String>.from(original.tags),
      stock: 0, // Reset stock for duplicate
      lowStockThreshold: original.lowStockThreshold,
      trackInventory: original.trackInventory,
      isActive: false, // Start as inactive
      isPublished: false,
      isFeatured: false,
    );
  }

  // ============ HELPERS ============

  /// Generate URL-friendly slug from name.
  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }
}
