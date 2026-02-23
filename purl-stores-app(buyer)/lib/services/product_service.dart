import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product.dart';
import '../models/store.dart';

/// ProductService for buyer app
/// Fetches products from all stores for discovery/browsing
class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache store info to avoid repeated lookups
  final Map<String, Store> _storeCache = {};
  
  // Cache verification status separately for faster access
  final Map<String, String?> _verificationCache = {};
  
  // Persistent cache
  SharedPreferences? _prefs;
  bool _cacheInitialized = false;

  /// Initialize cache from SharedPreferences
  Future<void> _initCache() async {
    if (_cacheInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    final cachedData = _prefs?.getString('product_service_verification_cache');
    if (cachedData != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(cachedData);
        decoded.forEach((key, value) {
          _verificationCache[key] = value as String?;
        });
        print('📦 ProductService: Loaded ${_verificationCache.length} verification statuses from cache');
      } catch (e) {
        print('Error loading ProductService cache: $e');
      }
    }
    _cacheInitialized = true;
  }
  
  /// Save cache to SharedPreferences
  Future<void> _saveCache() async {
    try {
      final cacheData = json.encode(_verificationCache);
      await _prefs?.setString('product_service_verification_cache', cacheData);
      print('💾 ProductService: Saved ${_verificationCache.length} verification statuses to cache');
    } catch (e) {
      print('Error saving ProductService cache: $e');
    }
  }

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

  /// Get store document (for verification status) with caching
  Future<String?> _getVerificationStatus(String storeId) async {
    // Initialize cache if needed
    await _initCache();
    
    // Return cached value if available
    if (_verificationCache.containsKey(storeId)) {
      print('✅ ProductService: Using cached verification for $storeId: ${_verificationCache[storeId]}');
      return _verificationCache[storeId];
    }
    
    print('🔄 ProductService: Fetching verification status for $storeId');
    try {
      final doc = await _firestore.collection('stores').doc(storeId).get();
      if (doc.exists) {
        final verificationStatus = doc.data()?['verificationStatus'] as String?;
        // Cache the verification status
        _verificationCache[storeId] = verificationStatus;
        print('✅ ProductService: Cached verification for $storeId: $verificationStatus');
        
        // Persist to SharedPreferences
        _saveCache();
        
        return verificationStatus;
      }
    } catch (e) {
      print('❌ ProductService: Error fetching verification for $storeId: $e');
    }
    
    // Cache null to avoid repeated failed lookups
    _verificationCache[storeId] = null;
    _saveCache();
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
        try {
          // Extract storeId from document path: stores/{storeId}/products/{productId}
          final pathSegments = doc.reference.path.split('/');
          if (pathSegments.length >= 2) {
            final storeId = pathSegments[1];
            
            // Get store and verification status (both use caching)
            final store = await _getStore(storeId);
            final verificationStatus = await _getVerificationStatus(storeId);
            
            if (store != null) {
              products.add(Product.fromFirestore(
                doc,
                storeId,
                store.name,
                store.logoUrl,
                verificationStatus,
              ));
            }
          }
        } catch (e) {
          print('Error processing product: $e');
          // Continue with next product
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
      final verificationStatus = await _getVerificationStatus(storeId);
      
      return snapshot.docs.map((doc) => Product.fromFirestore(
        doc,
        storeId,
        store?.name ?? 'Unknown Store',
        store?.logoUrl,
        verificationStatus,
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
      final verificationStatus = await _getVerificationStatus(storeId);
      return Product.fromFirestore(
        doc,
        storeId,
        store?.name ?? 'Unknown Store',
        store?.logoUrl,
        verificationStatus,
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
          final verificationStatus = await _getVerificationStatus(storeId);
          
          if (store != null) {
            products.add(Product.fromFirestore(
              doc,
              storeId,
              store.name,
              store.logoUrl,
              verificationStatus,
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
        try {
          final pathSegments = doc.reference.path.split('/');
          if (pathSegments.length >= 2) {
            final storeId = pathSegments[1];
            
            // Get store and verification status (both use caching)
            final store = await _getStore(storeId);
            final verificationStatus = await _getVerificationStatus(storeId);
            
            if (store != null) {
              products.add(Product.fromFirestore(
                doc,
                storeId,
                store.name,
                store.logoUrl,
                verificationStatus,
              ));
            }
          }
        } catch (e) {
          print('Error processing featured product: $e');
          // Continue with next product
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
    _verificationCache.clear();
    _prefs?.remove('product_service_verification_cache');
    print('🗑️ ProductService: Cache cleared');
  }
}
