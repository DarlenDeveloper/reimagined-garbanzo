import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' show cos, sqrt, asin, sin;

class DeliveryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get available deliveries within radius (status = "searching")
  Stream<List<DeliveryRequest>> getAvailableDeliveries({
    GeoPoint? courierLocation,
    double radiusKm = 2.0,
  }) {
    return _firestore
        .collection('deliveries')
        .where('status', isEqualTo: 'searching')
        .where('deliveryType', isEqualTo: 'purl_courier')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => DeliveryRequest.fromFirestore(doc))
          .where((delivery) {
            // Filter expired deliveries
            if (delivery.searchExpiresAt != null) {
              return delivery.searchExpiresAt!.toDate().isAfter(now);
            }
            return true;
          })
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
    });
  }

  /// Get courier's assigned deliveries
  Stream<List<DeliveryRequest>> getMyDeliveries() {
    final courierId = _auth.currentUser?.uid;
    if (courierId == null) return Stream.value([]);

    return _firestore
        .collection('deliveries')
        .where('assignedCourierId', isEqualTo: courierId)
        .where('status', whereIn: ['assigned', 'picked_up', 'in_transit'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryRequest.fromFirestore(doc))
            .toList());
  }

  /// Get completed deliveries
  Stream<List<DeliveryRequest>> getCompletedDeliveries() {
    final courierId = _auth.currentUser?.uid;
    if (courierId == null) return Stream.value([]);

    return _firestore
        .collection('deliveries')
        .where('assignedCourierId', isEqualTo: courierId)
        .where('status', whereIn: ['delivered', 'cancelled'])
        .orderBy('deliveredAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryRequest.fromFirestore(doc))
            .toList());
  }

  /// Accept a delivery request
  Future<void> acceptDelivery(String deliveryId) async {
    final courierId = _auth.currentUser?.uid;
    if (courierId == null) throw Exception('Not authenticated');

    // Get courier info
    final courierDoc = await _firestore.collection('couriers').doc(courierId).get();
    final courierData = courierDoc.data();
    if (courierData == null) throw Exception('Courier profile not found');

    final courierName = courierData['fullName'] ?? 'Courier';
    final courierPhone = courierData['phone'] ?? '';

    // Update delivery
    await _firestore.collection('deliveries').doc(deliveryId).update({
      'status': 'assigned',
      'assignedCourierId': courierId,
      'assignedCourierName': courierName,
      'assignedCourierPhone': courierPhone,
      'assignedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update delivery status
  Future<void> updateDeliveryStatus(String deliveryId, String status) async {
    final updates = <String, dynamic>{
      'status': status,
    };

    if (status == 'picked_up') {
      updates['pickedUpAt'] = FieldValue.serverTimestamp();
    } else if (status == 'delivered') {
      updates['deliveredAt'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection('deliveries').doc(deliveryId).update(updates);

    // Update courier stats if delivered
    if (status == 'delivered') {
      final courierId = _auth.currentUser?.uid;
      if (courierId != null) {
        final deliveryDoc = await _firestore.collection('deliveries').doc(deliveryId).get();
        final deliveryFee = (deliveryDoc.data()?['deliveryFee'] ?? 0).toDouble();

        await _firestore.collection('couriers').doc(courierId).update({
          'totalDeliveries': FieldValue.increment(1),
          'totalEarnings': FieldValue.increment(deliveryFee),
        });
      }
    }
  }

  /// Update courier location
  Future<void> updateCourierLocation(String deliveryId, GeoPoint location) async {
    await _firestore.collection('deliveries').doc(deliveryId).update({
      'courierLocation': location,
    });
  }

  /// Calculate distance between two points (Haversine formula)
  double calculateDistance(GeoPoint point1, GeoPoint point2) {
    const earthRadius = 6371; // km
    final lat1 = point1.latitude * 0.017453292519943295; // Convert to radians
    final lat2 = point2.latitude * 0.017453292519943295;
    final dLat = lat2 - lat1;
    final dLon = (point2.longitude - point1.longitude) * 0.017453292519943295;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }
}

/// Delivery Request Model
class DeliveryRequest {
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
  final String status;
  final Timestamp? searchExpiresAt;
  final double deliveryFee;
  final double distance;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final Timestamp createdAt;

  DeliveryRequest({
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
    required this.status,
    this.searchExpiresAt,
    required this.deliveryFee,
    required this.distance,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
  });

  factory DeliveryRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeliveryRequest(
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
      status: data['status'] ?? 'searching',
      searchExpiresAt: data['searchExpiresAt'] as Timestamp?,
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      distance: (data['distance'] ?? 0).toDouble(),
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  String get pickupAddress {
    return '${storeAddress['street'] ?? ''}, ${storeAddress['city'] ?? ''}'.trim();
  }

  String get dropoffAddress {
    return '${buyerAddress['street'] ?? ''}, ${buyerAddress['city'] ?? ''}'.trim();
  }

  int get itemCount {
    return items.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 0));
  }
}
