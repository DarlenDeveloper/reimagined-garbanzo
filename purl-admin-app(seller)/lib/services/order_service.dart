import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// OrderService for sellers to manage incoming orders
/// 
/// FIRESTORE STRUCTURE:
/// /stores/{storeId}/orders/{orderId}
/// ├── orderNumber: string
/// ├── userId: string (buyer)
/// ├── userName: string
/// ├── userEmail: string
/// ├── userPhone: string
/// ├── items: array
/// ├── subtotal: number
/// ├── shipping: number
/// ├── total: number
/// ├── status: string ("pending" | "shipped" | "delivered" | "refunded")
/// ├── paymentStatus: string
/// ├── deliveryAddress: map
/// ├── contactDetails: map
/// ├── createdAt: timestamp
/// ├── updatedAt: timestamp
class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Stream<List<StoreOrderData>>? _cachedStream;
  String? _cachedUserId;

  /// Get store's orders stream with offline persistence and caching
  Stream<List<StoreOrderData>> getStoreOrdersStream() {
    final userId = _auth.currentUser?.uid;
    
    // Return cached stream if user hasn't changed
    if (_cachedStream != null && _cachedUserId == userId) {
      return _cachedStream!;
    }
    
    // Create new stream
    _cachedUserId = userId;
    _cachedStream = _createOrdersStream().asBroadcastStream();
    return _cachedStream!;
  }
  
  Stream<List<StoreOrderData>> _createOrdersStream() async* {
    final userId = _auth.currentUser?.uid;
    
    if (userId == null) {
      yield [];
      return;
    }

    try {
      // First get the store ID (using authorizedUsers array)
      final storeSnapshot = await _firestore
          .collection('stores')
          .where('authorizedUsers', arrayContains: userId)
          .limit(1)
          .get(const GetOptions(source: Source.cache))
          .catchError((_) => _firestore
              .collection('stores')
              .where('authorizedUsers', arrayContains: userId)
              .limit(1)
              .get());

      if (storeSnapshot.docs.isEmpty) {
        yield [];
        return;
      }

      final storeId = storeSnapshot.docs.first.id;

      // Stream orders with offline persistence enabled
      yield* _firestore
          .collection('stores')
          .doc(storeId)
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => StoreOrderData.fromFirestore(doc, storeId))
                .toList();
          });
    } catch (e) {
      yield [];
    }
  }

  /// Get specific order details
  Future<StoreOrderData?> getOrderDetails(String orderId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final storeSnapshot = await _firestore
          .collection('stores')
          .where('authorizedUsers', arrayContains: userId)
          .limit(1)
          .get();

      if (storeSnapshot.docs.isEmpty) return null;

      final storeId = storeSnapshot.docs.first.id;
      final orderDoc = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('orders')
          .doc(orderId)
          .get();

      if (orderDoc.exists) {
        return StoreOrderData.fromFirestore(orderDoc, storeId);
      }
    } catch (e) {
      print('Error fetching order details: $e');
    }
    return null;
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final storeSnapshot = await _firestore
          .collection('stores')
          .where('authorizedUsers', arrayContains: userId)
          .limit(1)
          .get();

      if (storeSnapshot.docs.isEmpty) throw Exception('Store not found');

      final storeId = storeSnapshot.docs.first.id;
      
      // Update order in store's orders collection
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('orders')
          .doc(orderId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update in user's orders collection
      final orderDoc = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('orders')
          .doc(orderId)
          .get();

      if (orderDoc.exists) {
        final buyerUserId = orderDoc.data()?['userId'];
        if (buyerUserId != null) {
          await _firestore
              .collection('users')
              .doc(buyerUserId)
              .collection('orders')
              .doc(orderId)
              .update({
            'status': newStatus,
          });
        }
      }

      print('Order $orderId updated to $newStatus');
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  /// Get order counts by status
  Future<Map<String, int>> getOrderCounts() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {'all': 0, 'pending': 0, 'shipped': 0, 'delivered': 0};

    try {
      final storeSnapshot = await _firestore
          .collection('stores')
          .where('authorizedUsers', arrayContains: userId)
          .limit(1)
          .get();

      if (storeSnapshot.docs.isEmpty) {
        return {'all': 0, 'pending': 0, 'shipped': 0, 'delivered': 0};
      }

      final storeId = storeSnapshot.docs.first.id;
      final ordersSnapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('orders')
          .get();

      final orders = ordersSnapshot.docs;
      return {
        'all': orders.length,
        'pending': orders.where((o) => o.data()['status'] == 'pending').length,
        'shipped': orders.where((o) => o.data()['status'] == 'shipped').length,
        'delivered': orders.where((o) => o.data()['status'] == 'delivered').length,
      };
    } catch (e) {
      print('Error getting order counts: $e');
      return {'all': 0, 'pending': 0, 'shipped': 0, 'delivered': 0};
    }
  }
}

/// Store order data model
class StoreOrderData {
  final String id;
  final String storeId;
  final String orderNumber;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final List<OrderItem> items;
  final double subtotal;
  final double shipping;
  final double total;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final Map<String, dynamic> deliveryAddress;
  final Map<String, dynamic> contactDetails;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deliveredAt;
  final String? promoCode;
  final double? promoDiscount;
  final String? packageSize; // Add package size field

  StoreOrderData({
    required this.id,
    required this.storeId,
    required this.orderNumber,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.deliveryAddress,
    required this.contactDetails,
    required this.createdAt,
    required this.updatedAt,
    this.deliveredAt,
    this.promoCode,
    this.promoDiscount,
    this.packageSize, // Add to constructor
  });

  factory StoreOrderData.fromFirestore(DocumentSnapshot doc, String storeId) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List<dynamic>?) ?? [];
    
    // Extract first name only from userName
    final fullName = data['userName'] ?? '';
    final firstName = fullName.split(' ').first;
    
    return StoreOrderData(
      id: doc.id,
      storeId: storeId,
      orderNumber: data['orderNumber'] ?? '',
      userId: data['userId'] ?? '',
      userName: firstName,
      userEmail: data['userEmail'] ?? '',
      userPhone: data['userPhone'] ?? '',
      items: itemsList.map((item) => OrderItem.fromMap(item)).toList(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      shipping: (data['shipping'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      paymentMethod: data['paymentMethod'] ?? '',
      deliveryAddress: data['deliveryAddress'] ?? {},
      contactDetails: data['contactDetails'] ?? {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      promoCode: data['promoCode'] as String?,
      promoDiscount: (data['promoDiscount'] ?? 0).toDouble(),
      packageSize: data['packageSize'] as String?, // Read package size
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'refunded':
        return 'Refunded';
      default:
        return 'Unknown';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get itemsCount {
    final count = items.fold<int>(0, (sum, item) => sum + item.quantity);
    return '$count item${count != 1 ? 's' : ''}';
  }
}

/// Order item model
class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double sellerPrice;
  final double price;
  final String currency;
  final int quantity;
  final double itemTotal;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.sellerPrice,
    required this.price,
    required this.currency,
    required this.quantity,
    required this.itemTotal,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      sellerPrice: (map['sellerPrice'] ?? map['price'] ?? 0).toDouble(),
      price: (map['price'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'KES',
      quantity: map['quantity'] ?? 1,
      itemTotal: (map['itemTotal'] ?? 0).toDouble(),
    );
  }
}
