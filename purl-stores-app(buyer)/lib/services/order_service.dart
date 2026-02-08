import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_service.dart';

/// OrderService manages order creation and tracking
/// 
/// FIRESTORE STRUCTURE:
/// /stores/{storeId}/orders/{orderId}
/// ├── orderNumber: string (e.g., "ORD-20260127-1234")
/// ├── userId: string
/// ├── userName: string
/// ├── userEmail: string
/// ├── userPhone: string
/// ├── items: array [{productId, productName, productImage, price, quantity, itemTotal}]
/// ├── subtotal: number
/// ├── shipping: number
/// ├── total: number
/// ├── status: string ("pending" | "shipped" | "delivered" | "refunded")
/// ├── paymentStatus: string ("pending" | "paid" | "failed" | "refunded")
/// ├── paymentMethod: string (dummy for now)
/// ├── deliveryAddress: map {label, street, city}
/// ├── deliveryLocation: geopoint (for pickup point)
/// ├── contactDetails: map {name, phone, email}
/// ├── createdAt: timestamp
/// ├── updatedAt: timestamp
///
/// /users/{userId}/orders/{orderId}
/// ├── orderId: string (reference to store order)
/// ├── storeId: string
/// ├── storeName: string
/// ├── orderNumber: string
/// ├── total: number
/// ├── status: string
/// ├── createdAt: timestamp
class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create orders from cart (one order per store)
  Future<List<String>> createOrdersFromCart({
    required Map<String, List<CartItemData>> itemsByStore,
    required Map<String, CartTotals> totalsByStore,
    required DeliveryAddress deliveryAddress,
    required ContactDetails contactDetails,
    required GeoPoint? deliveryLocation,
    String paymentMethod = 'Dummy Payment',
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final user = _auth.currentUser!;
    final List<String> orderIds = [];

    // Create one order per store
    for (var entry in itemsByStore.entries) {
      final storeId = entry.key;
      final items = entry.value;
      final totals = totalsByStore[storeId]!;

      // Generate order number
      final orderNumber = _generateOrderNumber();

      // Calculate markup percentage based on currency
      double getMarkupPercentage(double price, String currency) {
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

      // Prepare order items (with final prices including markup)
      final orderItems = items.map((item) {
        final markup = getMarkupPercentage(item.price, item.currency);
        final finalPrice = item.price + (item.price * markup);
        return {
          'productId': item.productId,
          'productName': item.productName,
          'productImage': item.productImage,
          'sellerPrice': item.price, // Original seller price
          'price': finalPrice, // Final price with markup
          'currency': item.currency,
          'quantity': item.quantity,
          'itemTotal': finalPrice * item.quantity,
        };
      }).toList();

      // Create order in store's orders collection
      final orderRef = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('orders')
          .add({
        'orderNumber': orderNumber,
        'userId': userId,
        'userName': user.displayName ?? contactDetails.name,
        'userEmail': user.email ?? contactDetails.email,
        'userPhone': contactDetails.phone,
        'items': orderItems,
        'subtotal': totals.subtotal,
        'shipping': totals.shipping,
        'total': totals.total,
        'status': 'pending',
        'paymentStatus': 'paid', // Dummy payment - always paid
        'paymentMethod': paymentMethod,
        'deliveryAddress': {
          'label': deliveryAddress.label,
          'street': deliveryAddress.street,
          'city': deliveryAddress.city,
        },
        'deliveryLocation': deliveryLocation,
        'contactDetails': {
          'name': contactDetails.name,
          'phone': contactDetails.phone,
          'email': contactDetails.email,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create order reference in user's orders collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderRef.id)
          .set({
        'orderId': orderRef.id,
        'storeId': storeId,
        'storeName': items.first.storeName,
        'orderNumber': orderNumber,
        'total': totals.total,
        'status': 'pending',
        'itemCount': items.length,
        'createdAt': FieldValue.serverTimestamp(),
      });

      orderIds.add(orderRef.id);
      
      // Send notification to store owner about new order
      await _sendNewOrderNotification(storeId, orderNumber, totals.total);
    }

    return orderIds;
  }

  /// Send notification to store owner about new order
  Future<void> _sendNewOrderNotification(
    String storeId,
    String orderNumber,
    double total,
  ) async {
    try {
      final startTime = DateTime.now();
      
      // Get store's FCM token
      final storeDoc = await _firestore.collection('stores').doc(storeId).get();
      final fcmToken = storeDoc.data()?['fcmToken'] as String?;
      
      if (fcmToken == null) {
        print('⚠️ No FCM token found for store $storeId');
        return;
      }

      // TODO: Deploy Cloud Function to europe-west1 region for optimal East Africa latency
      // For now, save to Firestore (Cloud Function will pick it up)
      // Future optimization: Call Cloud Function directly for <300ms latency
      
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('notifications')
          .add({
        'title': '🎉 New Order!',
        'body': 'Order $orderNumber - Total: \$$total',
        'type': 'new_order',
        'orderId': orderNumber,
        'amount': total,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'fcmToken': fcmToken, // For Cloud Function to send FCM
      });

      final latency = DateTime.now().difference(startTime).inMilliseconds;
      print('✅ New order notification queued (${latency}ms)');
    } catch (e) {
      print('❌ Error sending new order notification: $e');
      // Don't throw - notification failure shouldn't break order creation
    }
  }

  /// Get user's orders stream
  Stream<List<UserOrderData>> getUserOrdersStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserOrderData.fromFirestore(doc))
            .toList());
  }

  /// Get specific order details from store
  Future<StoreOrderData?> getOrderDetails(String storeId, String orderId) async {
    try {
      final doc = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('orders')
          .doc(orderId)
          .get();

      if (doc.exists) {
        return StoreOrderData.fromFirestore(doc, storeId);
      }
    } catch (e) {
      print('Error fetching order details: $e');
    }
    return null;
  }

  /// Generate unique order number
  String _generateOrderNumber() {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour}${now.minute}${now.second}';
    return 'ORD-$dateStr-$timeStr';
  }
}

/// Delivery address model
class DeliveryAddress {
  final String label;
  final String street;
  final String city;

  DeliveryAddress({
    required this.label,
    required this.street,
    required this.city,
  });
}

/// Contact details model
class ContactDetails {
  final String name;
  final String phone;
  final String email;

  ContactDetails({
    required this.name,
    required this.phone,
    required this.email,
  });
}

/// User order data (from user's orders collection)
class UserOrderData {
  final String id;
  final String orderId;
  final String storeId;
  final String storeName;
  final String orderNumber;
  final double total;
  final String status;
  final int itemCount;
  final DateTime createdAt;

  UserOrderData({
    required this.id,
    required this.orderId,
    required this.storeId,
    required this.storeName,
    required this.orderNumber,
    required this.total,
    required this.status,
    required this.itemCount,
    required this.createdAt,
  });

  factory UserOrderData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserOrderData(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      storeId: data['storeId'] ?? '',
      storeName: data['storeName'] ?? '',
      orderNumber: data['orderNumber'] ?? '',
      total: (data['total'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      itemCount: data['itemCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
}

/// Store order data (from store's orders collection)
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
  });

  factory StoreOrderData.fromFirestore(DocumentSnapshot doc, String storeId) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List<dynamic>?) ?? [];
    
    return StoreOrderData(
      id: doc.id,
      storeId: storeId,
      orderNumber: data['orderNumber'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
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
    );
  }
}

/// Order item model
class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final String currency;
  final int quantity;
  final double itemTotal;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
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
      price: (map['price'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'KES',
      quantity: map['quantity'] ?? 1,
      itemTotal: (map['itemTotal'] ?? 0).toDouble(),
    );
  }
}
