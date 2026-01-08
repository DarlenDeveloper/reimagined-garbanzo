import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/store.dart';

/// ProductService for buyer app
/// Fetches products from all stores for discovery/browsing
class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache store info to avoid repeated lookups
  final Map<String, Store> _storeCache = {};

  /// Get store info (with caching)
  Future<Store?> _getStore(String storeId) async {
    if (_storeCache.containsKey(storeId)) {
      return _storeCache[storeId];
    }

    try {
      final doc = await _firestore.collection('stores').doc(storeId).get();
      if (doc.exists) {
        final store = Store.fromFirestore(doc);
        _storeCache[storeId] = store;
        return store;
      }
    } catch (e) {
      // Ignore errors, return null
    }
    return null;
  }

  /// Get all active products from all stores
  /// Uses collection group query to fetch across all store subcollections
  Stream<List<Product>> getDiscoverProductsStream({
    String? categoryId,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collectionGroup('products')
        .where('isActive', isEqualTo: true);

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().asyncMap((snapshot) async {
      final products = <Product>[];
      
      for (final doc in snapshot.docs) {
        // Extract storeId from document path: stores/{storeId}/products/{productId}
        final pathSegments = doc.reference.path.split('/');
        if (pathSegments.length >= 2) {
          final storeId = pathSegments[1];
          final store = await _getStore(storeId);
          
          if (store != null) {
            products.add(Product.fromFirestore(
              doc,
              storeId,
              store.name,
              store.logoUrl,
            ));
          }
        }
      }
      
      return products;
    });
  }

  /// Get products for a specific store
  Stream<List<Product>> getStoreProductsStream(
    String storeId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      final store = await _getStore(storeId);
      
      return snapshot.docs.map((doc) => Product.fromFirestore(
        doc,
        storeId,
        store?.name ?? 'Unknown Store',
        store?.logoUrl,
      )).toList();
    });
  }

  /// Get a single product by ID
  Future<Product?> getProductById(String storeId, String productId) async {
    try {
      final doc = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .doc(productId)
          .get();

      if (!doc.exists) return null;

      final store = await _getStore(storeId);
      return Product.fromFirestore(
        doc,
        storeId,
        store?.name ?? 'Unknown Store',
        store?.logoUrl,
      );
    } catch (e) {
      return null;
    }
  }

  /// Search products across all stores
  Future<List<Product>> searchProducts(String query, {int limit = 20}) async {
    if (query.isEmpty) return [];

    // Firestore doesn't support full-text search, so we use prefix matching
    final queryLower = query.toLowerCase();
    
    try {
      final snapshot = await _firestore
          .collectionGroup('products')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .startAt([queryLower])
          .endAt(['$queryLower\uf8ff'])
          .limit(limit)
          .get();

      final products = <Product>[];
      
      for (final doc in snapshot.docs) {
        final pathSegments = doc.reference.path.split('/');
        if (pathSegments.length >= 2) {
          final storeId = pathSegments[1];
          final store = await _getStore(storeId);
          
          if (store != null) {
            products.add(Product.fromFirestore(
              doc,
              storeId,
              store.name,
              store.logoUrl,
            ));
          }
        }
      }
      
      return products;
    } catch (e) {
      return [];
    }
  }

  /// Get featured products
  Stream<List<Product>> getFeaturedProductsStream({int limit = 10}) {
    return _firestore
        .collectionGroup('products')
        .where('isActive', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      final products = <Product>[];
      
      for (final doc in snapshot.docs) {
        final pathSegments = doc.reference.path.split('/');
        if (pathSegments.length >= 2) {
          final storeId = pathSegments[1];
          final store = await _getStore(storeId);
          
          if (store != null) {
            products.add(Product.fromFirestore(
              doc,
              storeId,
              store.name,
              store.logoUrl,
            ));
          }
        }
      }
      
      return products;
    });
  }

  /// Get store by ID
  Future<Store?> getStoreById(String storeId) async {
    return _getStore(storeId);
  }

  /// Clear store cache (call when needed)
  void clearCache() {
    _storeCache.clear();
  }
}
