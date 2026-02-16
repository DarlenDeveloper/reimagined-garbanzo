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

  /// Calculate cart totals (with markup applied)
  /// Delivery is FREE - handled by Purl
  CartTotals calculateTotals(List<CartItemData> items) {
    double subtotal = 0;
    for (var item in items) {
      // Apply markup to each item
      subtotal += item.finalItemTotal;
    }

    // Delivery is FREE - Purl handles delivery costs
    double shipping = 0;
    double total = subtotal + shipping;

    return CartTotals(
      subtotal: subtotal,
      shipping: shipping,
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
      storeName: data['storeName'] ?? '',
      productName: data['productName'] ?? '',
      productImage: data['productImage'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'KES',
      quantity: data['quantity'] ?? 1,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  double get itemTotal => price * quantity;

  /// Calculate markup percentage based on price and currency
  static double _getMarkupPercentage(double price, String currency) {
    switch (currency.toUpperCase()) {
      case 'UGX':
        if (price >= 500001) return 0.03;
        if (price >= 260001) return 0.04;
        if (price >= 125001) return 0.06;
        if (price >= 100001) return 0.09;
        if (price >= 75001) return 0.11;
        if (price >= 50001) return 0.14;
        if (price >= 25000) return 0.168;
        return 0.168;
      case 'KES':
        if (price >= 17422) return 0.03;
        if (price >= 9059) return 0.04;
        if (price >= 4355) return 0.06;
        if (price >= 3484) return 0.09;
        if (price >= 2613) return 0.11;
        if (price >= 1742) return 0.14;
        if (price >= 871) return 0.168;
        return 0.168;
      case 'TZS':
        if (price >= 337838) return 0.03;
        if (price >= 175676) return 0.04;
        if (price >= 84459) return 0.06;
        if (price >= 67568) return 0.09;
        if (price >= 50676) return 0.11;
        if (price >= 33784) return 0.14;
        if (price >= 16892) return 0.168;
        return 0.168;
      case 'USD':
        if (price >= 135) return 0.03;
        if (price >= 70) return 0.04;
        if (price >= 34) return 0.06;
        if (price >= 27) return 0.09;
        if (price >= 20) return 0.11;
        if (price >= 14) return 0.14;
        if (price >= 7) return 0.168;
        return 0.168;
      case 'EUR':
        if (price >= 124) return 0.03;
        if (price >= 65) return 0.04;
        if (price >= 31) return 0.06;
        if (price >= 25) return 0.09;
        if (price >= 19) return 0.11;
        if (price >= 12) return 0.14;
        if (price >= 6) return 0.168;
        return 0.168;
      case 'GBP':
        if (price >= 107) return 0.03;
        if (price >= 56) return 0.04;
        if (price >= 27) return 0.06;
        if (price >= 21) return 0.09;
        if (price >= 16) return 0.11;
        if (price >= 11) return 0.14;
        if (price >= 5) return 0.168;
        return 0.168;
      default:
        if (price >= 500001) return 0.03;
        if (price >= 260001) return 0.04;
        if (price >= 125001) return 0.06;
        if (price >= 100001) return 0.09;
        if (price >= 75001) return 0.11;
        if (price >= 50001) return 0.14;
        if (price >= 25000) return 0.168;
        return 0.168;
    }
  }

  /// Get final price with markup
  double get finalPrice {
    final markup = _getMarkupPercentage(price, currency);
    return price + (price * markup);
  }

  /// Get final item total with markup
  double get finalItemTotal => finalPrice * quantity;
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
