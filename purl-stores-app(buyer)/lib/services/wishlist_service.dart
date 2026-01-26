import 'package:cloud_firestore/cloud_firestore.dart';

/// WishlistService manages user's saved/favorite products
/// 
/// FIRESTORE STRUCTURE:
/// /users/{userId}/wishlist/{productId}
/// ├── productId: string
/// ├── storeId: string
/// ├── productName: string
/// ├── productImage: string
/// ├── price: number
/// ├── currency: string
/// ├── storeName: string
/// ├── isInStock: boolean
/// ├── addedAt: timestamp
class WishlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add product to wishlist
  Future<void> addToWishlist({
    required String userId,
    required String productId,
    required String storeId,
    required String productName,
    String? productImage,
    required double price,
    required String currency,
    required String storeName,
    bool isInStock = true,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(productId)
        .set({
      'productId': productId,
      'storeId': storeId,
      'productName': productName,
      'productImage': productImage ?? '',
      'price': price,
      'currency': currency,
      'storeName': storeName,
      'isInStock': isInStock,
      'addedAt': Timestamp.now(),
    });
  }

  /// Remove product from wishlist
  Future<void> removeFromWishlist({
    required String userId,
    required String productId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(productId)
        .delete();
  }

  /// Check if product is in wishlist
  Future<bool> isInWishlist({
    required String userId,
    required String productId,
  }) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(productId)
        .get();
    
    return doc.exists;
  }

  /// Get user's wishlist
  Stream<List<Map<String, dynamic>>> getWishlist(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Get wishlist count
  Future<int> getWishlistCount(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .count()
        .get();
    
    return snapshot.count ?? 0;
  }

  /// Toggle wishlist (add if not exists, remove if exists)
  Future<bool> toggleWishlist({
    required String userId,
    required String productId,
    required String storeId,
    required String productName,
    String? productImage,
    required double price,
    required String currency,
    required String storeName,
    bool isInStock = true,
  }) async {
    final isInList = await isInWishlist(userId: userId, productId: productId);
    
    if (isInList) {
      await removeFromWishlist(userId: userId, productId: productId);
      return false; // Removed
    } else {
      await addToWishlist(
        userId: userId,
        productId: productId,
        storeId: storeId,
        productName: productName,
        productImage: productImage,
        price: price,
        currency: currency,
        storeName: storeName,
        isInStock: isInStock,
      );
      return true; // Added
    }
  }

  /// Clear entire wishlist
  Future<void> clearWishlist(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .get();
    
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  /// Remove out of stock items from wishlist
  Future<void> removeOutOfStockItems(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .where('isInStock', isEqualTo: false)
        .get();
    
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  /// Update product stock status in wishlist
  Future<void> updateProductStock({
    required String productId,
    required bool isInStock,
  }) async {
    // Update in all users' wishlists
    final usersSnapshot = await _firestore.collection('users').get();
    
    final batch = _firestore.batch();
    for (final userDoc in usersSnapshot.docs) {
      final wishlistDoc = userDoc.reference.collection('wishlist').doc(productId);
      final exists = await wishlistDoc.get();
      
      if (exists.exists) {
        batch.update(wishlistDoc, {'isInStock': isInStock});
      }
    }
    
    await batch.commit();
  }
}
