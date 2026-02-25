import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' show cos, sqrt, asin;

/// DeliveryService handles delivery assignment and tracking
/// 
/// FIRESTORE STRUCTURE:
/// /deliveries/{deliveryId}
/// ├── orderId: string
/// ├── orderNumber: string
/// ├── storeId: string
/// ├── storeName: string
/// ├── storeLocation: GeoPoint (pickup)
/// ├── storeAddress: map
/// ├── storePhone: string
/// ├── buyerId: string
/// ├── buyerName: string
/// ├── buyerPhone: string
/// ├── buyerLocation: GeoPoint (dropoff)
/// ├── buyerAddress: map
/// ├── deliveryType: "self" | "purl_courier"
/// ├── packageSize: string ("standard" | "bulky")
/// ├── status: "searching" | "assigned" | "picked_up" | "in_transit" | "delivered" | "cancelled" | "no_courier_available"
/// ├── searchExpiresAt: timestamp (3 minutes from creation)
/// ├── assignedCourierId: string?
/// ├── assignedCourierName: string?
/// ├── assignedCourierPhone: string?
/// ├── vehiclePlateNumber: string? (for self-delivery)
/// ├── vehicleName: string? (for self-delivery)
/// ├── courierLocation: GeoPoint? (real-time updates)
/// ├── deliveryFee: number
/// ├── distance: number (km)
/// ├── routePolyline: string? (encoded polyline from Directions API)
/// ├── items: array (summary)
/// ├── totalAmount: number
/// ├── createdAt: timestamp
/// ├── assignedAt: timestamp?
/// ├── pickedUpAt: timestamp?
/// ├── deliveredAt: timestamp?
/// ├── cancelledAt: timestamp?
/// └── proofOfDelivery: map?
class DeliveryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a delivery request for Purl Courier (3-minute search window)
  Future<String> createDeliveryRequest({
    required String orderId,
    required String orderNumber,
    required GeoPoint storeLocation,
    required GeoPoint buyerLocation,
    required Map<String, dynamic> buyerAddress,
    required String buyerName,
    required String buyerPhone,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Get store info
    final storeQuery = await _firestore
        .collection('stores')
        .where('authorizedUsers', arrayContains: userId)
        .limit(1)
        .get();

    if (storeQuery.docs.isEmpty) {
      throw Exception('Store not found');
    }

    final storeDoc = storeQuery.docs.first;
    final storeData = storeDoc.data();
    final storeId = storeDoc.id;
    final storeName = storeData['name'] ?? 'Store';
    final storePhone = storeData['contact']?['phone'] ?? '';
    final storeAddress = storeData['address'] ?? {};

    // Calculate distance
    final distance = calculateDistance(storeLocation, buyerLocation);

    // Calculate delivery fee based on package type
    // Standard (motorcycle): 500 UGX/km, Bulky (car): 1000 UGX/km
    // Minimum 1000 UGX, rounded to nearest 500
    final rawFee = distance * 500.0; // Default to standard rate
    final feeAfterMinimum = rawFee < 1000.0 ? 1000.0 : rawFee;
    final deliveryFee = ((feeAfterMinimum / 500).round() * 500).toDouble();

    // Create delivery request
    final deliveryRef = await _firestore.collection('deliveries').add({
      'orderId': orderId,
      'orderNumber': orderNumber,
      'storeId': storeId,
      'storeName': storeName,
      'storeLocation': storeLocation,
      'storeAddress': storeAddress,
      'storePhone': storePhone,
      'buyerId': '', // Will be filled from order
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerLocation': buyerLocation,
      'buyerAddress': buyerAddress,
      'deliveryType': 'purl_courier',
      'status': 'searching',
      'searchExpiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 3)),
      ),
      'assignedCourierId': null,
      'assignedCourierName': null,
      'assignedCourierPhone': null,
      'courierLocation': null,
      'deliveryFee': deliveryFee,
      'distance': distance,
      'items': items,
      'totalAmount': totalAmount,
      'createdAt': FieldValue.serverTimestamp(),
      'assignedAt': null,
      'pickedUpAt': null,
      'deliveredAt': null,
      'cancelledAt': null,
      'proofOfDelivery': null,
    });

    print('✅ Delivery request created: ${deliveryRef.id}');
    print('📍 Distance: ${distance.toStringAsFixed(2)} km');
    print('💰 Delivery fee: UGX ${deliveryFee.toStringAsFixed(0)}');
    print('⏰ Search expires in 3 minutes');

    // TODO: Send notification to nearby couriers
    await _notifyNearbyCouriers(deliveryRef.id, storeLocation, deliveryFee);

    return deliveryRef.id;
  }

  /// Assign self-delivery (store runner)
  Future<void> assignSelfDelivery({
    required String orderId,
    required String orderNumber,
    required GeoPoint storeLocation,
    required GeoPoint buyerLocation,
    required Map<String, dynamic> buyerAddress,
    required String buyerName,
    required String buyerPhone,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
    required String runnerId,
    required String runnerName,
    required String runnerPhone,
    required String vehiclePlateNumber,
    required String vehicleName,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Get store info
    final storeQuery = await _firestore
        .collection('stores')
        .where('authorizedUsers', arrayContains: userId)
        .limit(1)
        .get();

    if (storeQuery.docs.isEmpty) {
      throw Exception('Store not found');
    }

    final storeDoc = storeQuery.docs.first;
    final storeData = storeDoc.data();
    final storeId = storeDoc.id;
    final storeName = storeData['name'] ?? 'Store';
    final storePhone = storeData['contact']?['phone'] ?? '';
    final storeAddress = storeData['address'] ?? {};

    // Calculate distance
    final distance = calculateDistance(storeLocation, buyerLocation);

    // Create delivery with self-delivery
    await _firestore.collection('deliveries').add({
      'orderId': orderId,
      'orderNumber': orderNumber,
      'storeId': storeId,
      'storeName': storeName,
      'storeLocation': storeLocation,
      'storeAddress': storeAddress,
      'storePhone': storePhone,
      'buyerId': '',
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerLocation': buyerLocation,
      'buyerAddress': buyerAddress,
      'deliveryType': 'self',
      'status': 'assigned',
      'searchExpiresAt': null,
      'assignedCourierId': runnerId,
      'assignedCourierName': runnerName,
      'assignedCourierPhone': runnerPhone,
      'vehiclePlateNumber': vehiclePlateNumber,
      'vehicleName': vehicleName,
      'courierLocation': null,
      'deliveryFee': 0, // No fee for self-delivery
      'distance': distance,
      'items': items,
      'totalAmount': totalAmount,
      'createdAt': FieldValue.serverTimestamp(),
      'assignedAt': FieldValue.serverTimestamp(),
      'pickedUpAt': null,
      'deliveredAt': null,
      'cancelledAt': null,
      'proofOfDelivery': null,
    });

    print('✅ Self-delivery assigned to: $runnerName');
    print('📍 Distance: ${distance.toStringAsFixed(2)} km');
  }

  /// Cancel delivery request
  Future<void> cancelDeliveryRequest(String deliveryId, {String reason = 'Cancelled by store'}) async {
    await _firestore.collection('deliveries').doc(deliveryId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancellationReason': reason,
    });

    print('❌ Delivery cancelled: $deliveryId');
  }

  /// Mark delivery as no courier available (after 3-minute timeout)
  Future<void> markNoCourierAvailable(String deliveryId) async {
    await _firestore.collection('deliveries').doc(deliveryId).update({
      'status': 'no_courier_available',
      'cancelledAt': FieldValue.serverTimestamp(),
    });

    print('⚠️ No courier available for delivery: $deliveryId');
  }

  /// Listen to delivery status changes
  Stream<DeliveryData?> listenToDelivery(String deliveryId) {
    return _firestore
        .collection('deliveries')
        .doc(deliveryId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return DeliveryData.fromFirestore(doc);
    });
  }

  /// Get delivery by order ID
  Future<DeliveryData?> getDeliveryByOrderId(String orderId) async {
    final query = await _firestore
        .collection('deliveries')
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return DeliveryData.fromFirestore(query.docs.first);
  }

  /// Get store's deliveries stream
  Stream<List<DeliveryData>> getStoreDeliveriesStream() async* {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      yield [];
      return;
    }

    // Get store ID
    final storeQuery = await _firestore
        .collection('stores')
        .where('authorizedUsers', arrayContains: userId)
        .limit(1)
        .get();

    if (storeQuery.docs.isEmpty) {
      yield [];
      return;
    }

    final storeId = storeQuery.docs.first.id;

    yield* _firestore
        .collection('deliveries')
        .where('storeId', isEqualTo: storeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryData.fromFirestore(doc))
            .toList());
  }

  /// Calculate distance between two GeoPoints (in kilometers)
  /// Uses Haversine formula
  double calculateDistance(GeoPoint point1, GeoPoint point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final lat1 = point1.latitude * (3.141592653589793 / 180);
    final lat2 = point2.latitude * (3.141592653589793 / 180);
    final dLat = lat2 - lat1;
    final dLon = (point2.longitude - point1.longitude) * (3.141592653589793 / 180);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  /// Notify nearby couriers about new delivery request
  Future<void> _notifyNearbyCouriers(
    String deliveryId,
    GeoPoint storeLocation,
    double deliveryFee,
  ) async {
    // TODO: Implement courier notification
    // This will query couriers within X km radius and send FCM notifications
    print('📢 Notifying nearby couriers...');
    
    // For now, just log
    // In production, this would:
    // 1. Query couriers within 10km radius using GeoPoint
    // 2. Filter by online status and verified status
    // 3. Send FCM notification to each courier
    // 4. Include delivery details and fee
  }

  /// Helper: sin function
  double sin(double x) {
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }
}

/// Delivery data model
class DeliveryData {
  final String id;
  final String orderId;
  final String orderNumber;
  final String storeId;
  final String storeName;
  final GeoPoint storeLocation;
  final Map<String, dynamic> storeAddress;
  final String storePhone;
  final String buyerName;
  final String buyerPhone;
  final GeoPoint buyerLocation;
  final Map<String, dynamic> buyerAddress;
  final String deliveryType; // "self" | "purl_courier"
  final String status;
  final Timestamp? searchExpiresAt;
  final String? assignedCourierId;
  final String? assignedCourierName;
  final String? assignedCourierPhone;
  final String? vehiclePlateNumber;
  final String? vehicleName;
  final GeoPoint? courierLocation;
  final double deliveryFee;
  final double distance;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final Timestamp createdAt;
  final Timestamp? assignedAt;
  final Timestamp? pickedUpAt;
  final Timestamp? deliveredAt;
  final Timestamp? cancelledAt;

  DeliveryData({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.storeId,
    required this.storeName,
    required this.storeLocation,
    required this.storeAddress,
    required this.storePhone,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerLocation,
    required this.buyerAddress,
    required this.deliveryType,
    required this.status,
    this.searchExpiresAt,
    this.assignedCourierId,
    this.assignedCourierName,
    this.assignedCourierPhone,
    this.vehiclePlateNumber,
    this.vehicleName,
    this.courierLocation,
    required this.deliveryFee,
    required this.distance,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
  });

  factory DeliveryData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeliveryData(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      orderNumber: data['orderNumber'] ?? '',
      storeId: data['storeId'] ?? '',
      storeName: data['storeName'] ?? '',
      storeLocation: data['storeLocation'] as GeoPoint,
      storeAddress: Map<String, dynamic>.from(data['storeAddress'] ?? {}),
      storePhone: data['storePhone'] ?? '',
      buyerName: data['buyerName'] ?? '',
      buyerPhone: data['buyerPhone'] ?? '',
      buyerLocation: data['buyerLocation'] as GeoPoint,
      buyerAddress: Map<String, dynamic>.from(data['buyerAddress'] ?? {}),
      deliveryType: data['deliveryType'] ?? 'purl_courier',
      status: data['status'] ?? 'searching',
      searchExpiresAt: data['searchExpiresAt'] as Timestamp?,
      assignedCourierId: data['assignedCourierId'] as String?,
      assignedCourierName: data['assignedCourierName'] as String?,
      assignedCourierPhone: data['assignedCourierPhone'] as String?,
      vehiclePlateNumber: data['vehiclePlateNumber'] as String?,
      vehicleName: data['vehicleName'] as String?,
      courierLocation: data['courierLocation'] as GeoPoint?,
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      distance: (data['distance'] ?? 0).toDouble(),
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      assignedAt: data['assignedAt'] as Timestamp?,
      pickedUpAt: data['pickedUpAt'] as Timestamp?,
      deliveredAt: data['deliveredAt'] as Timestamp?,
      cancelledAt: data['cancelledAt'] as Timestamp?,
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'searching':
        return 'Searching for courier...';
      case 'assigned':
        return 'Courier assigned';
      case 'picked_up':
        return 'Picked up';
      case 'in_transit':
        return 'In transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'no_courier_available':
        return 'No courier available';
      default:
        return status;
    }
  }

  bool get isSearching => status == 'searching';
  bool get isAssigned => status == 'assigned';
  bool get isActive => ['searching', 'assigned', 'picked_up', 'in_transit'].contains(status);
  bool get isCompleted => status == 'delivered';
  bool get isCancelled => status == 'cancelled' || status == 'no_courier_available';

  /// Get time remaining for courier search (in seconds)
  int? get searchTimeRemaining {
    if (searchExpiresAt == null || !isSearching) return null;
    final now = DateTime.now();
    final expiresAt = searchExpiresAt!.toDate();
    final diff = expiresAt.difference(now).inSeconds;
    return diff > 0 ? diff : 0;
  }
}
