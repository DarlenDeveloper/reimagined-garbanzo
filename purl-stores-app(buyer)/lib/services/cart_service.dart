import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// CartService manages the shopping cart for buyers
/// 
/// FIRESTORE STRUCTURE:
/// /users/{userId}/cart/{cartItemId}
/// ├── productId: string
/// ├── storeId: string
/// ├── storeName: string
/// ├── productName: string
/// ├── productImage: string
/// ├── price: number
/// ├── currency: string
/// ├── quantity: number
/// ├── addedAt: timestamp
/// ├── updatedAt: timestamp
class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's cart items stream
  Stream<List<CartItemData>> getCartItemsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CartItemData.fromFirestore(doc))
            .toList());
  }

  /// Get cart items grouped by store
  Stream<Map<String, List<CartItemData>>> getCartItemsByStoreStream() {
    return getCartItemsStream().map((items) {
      final Map<String, List<CartItemData>> groupedItems = {};
      for (var item in items) {
        if (!groupedItems.containsKey(item.storeId)) {
          groupedItems[item.storeId] = [];
        }
        groupedItems[item.storeId]!.add(item);
      }
      return groupedItems;
    });
  }

  /// Add product to cart
  Future<void> addToCart({
    required String productId,
    required String storeId,
    required String storeName,
    required String productName,
    String? productImage,
    required double price,
    required String currency,
    int quantity = 1,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('❌ Cart Error: User not authenticated');
      throw Exception('User not authenticated');
    }

    print('✅ Adding to cart: $productName for user $userId');

    final cartRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cart');

    try {
      // Check if product already exists in cart
      final existingItem = await cartRef
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      if (existingItem.docs.isNotEmpty) {
        // Update quantity if already in cart
        final doc = existingItem.docs.first;
        final currentQty = doc.data()['quantity'] as int;
        print('📦 Product exists, updating quantity: $currentQty -> ${currentQty + quantity}');
        await doc.reference.update({
          'quantity': currentQty + quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Cart updated successfully');
      } else {
        // Add new item to cart
        print('📦 Adding new item to cart');
        await cartRef.add({
          'productId': productId,
          'storeId': storeId,
          'storeName': storeName,
          'productName': productName,
          'productImage': productImage ?? '',
          'price': price,
          'currency': currency,
          'quantity': quantity,
          'addedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Item added to cart successfully');
      }
    } catch (e) {
      print('❌ Cart Error: $e');
      rethrow;
    }
  }

  /// Update cart item quantity
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    if (quantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(cartItemId)
        .update({
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove item from cart
  Future<void> removeFromCart(String cartItemId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(cartItemId)
        .delete();
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final cartItems = await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .get();

    final batch = _firestore.batch();
    for (var doc in cartItems.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Clear cart items for a specific store (used after order creation)
  Future<void> clearStoreCart(String storeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final storeItems = await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .where('storeId', isEqualTo: storeId)
        .get();

    final batch = _firestore.batch();
    for (var doc in storeItems.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Get cart item count
  Future<int> getCartItemCount() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .get();

    return snapshot.docs.fold<int>(
      0,
      (sum, doc) => sum + (doc.data()['quantity'] as int? ?? 1),
    );
  }

  /// Calculate cart totals
  /// Delivery fees calculated separately based on location
  CartTotals calculateTotals(List<CartItemData> items, {double deliveryFee = 0}) {
    double subtotal = 0;
    for (var item in items) {
      subtotal += item.itemTotal;
    }

    double total = subtotal + deliveryFee;

    return CartTotals(
      subtotal: subtotal,
      shipping: deliveryFee,
      total: total,
    );
  }

  /// Calculate totals per store
  Map<String, CartTotals> calculateTotalsByStore(
      Map<String, List<CartItemData>> itemsByStore) {
    final Map<String, CartTotals> totals = {};
    
    itemsByStore.forEach((storeId, items) {
      totals[storeId] = calculateTotals(items);
    });

    return totals;
  }

  /// Fix cart items with missing store names
  Future<void> fixMissingStoreNames() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final cartSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      for (var doc in cartSnapshot.docs) {
        final data = doc.data();
        final storeName = data['storeName'] as String?;
        final storeId = data['storeId'] as String?;

        // If storeName is missing or empty, fetch it from the store
        if ((storeName == null || storeName.isEmpty) && storeId != null && storeId.isNotEmpty) {
          try {
            final storeDoc = await _firestore
                .collection('stores')
                .doc(storeId)
                .get();

            if (storeDoc.exists) {
              final storeData = storeDoc.data();
              final fetchedStoreName = storeData?['name'] as String? ?? 'Unknown Store';
              
              // Update the cart item with the store name
              await doc.reference.update({
                'storeName': fetchedStoreName,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              
              print('✅ Fixed cart item ${doc.id} with store name: $fetchedStoreName');
            }
          } catch (e) {
            print('❌ Error fetching store name for ${doc.id}: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error fixing cart items: $e');
    }
  }
}

/// Cart item data model
class CartItemData {
  final String id;
  final String productId;
  final String storeId;
  final String storeName;
  final String productName;
  final String productImage;
  final double price;
  final String currency;
  final int quantity;
  final DateTime addedAt;

  CartItemData({
    required this.id,
    required this.productId,
    required this.storeId,
    required this.storeName,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.currency,
    required this.quantity,
    required this.addedAt,
  });

  factory CartItemData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CartItemData(
      id: doc.id,
      productId: data['productId'] ?? '',
      storeId: data['storeId'] ?? '',
      storeName: data['storeName'] ?? 'Unknown Store',
      productName: data['productName'] ?? '',
      productImage: data['productImage'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'KES',
      quantity: data['quantity'] ?? 1,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  double get itemTotal => price * quantity;
}

/// Cart totals model
class CartTotals {
  final double subtotal;
  final double shipping;
  final double total;

  CartTotals({
    required this.subtotal,
    required this.shipping,
    required this.total,
  });
}
