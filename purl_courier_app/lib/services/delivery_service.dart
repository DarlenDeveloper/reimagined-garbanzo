import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' show cos, sqrt, asin, sin;

class DeliveryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get available deliveries within radius (status = "searching")
  /// Filters by courier's vehicle type to match package requirements
  Stream<List<DeliveryRequest>> getAvailableDeliveries({
    GeoPoint? courierLocation,
    double radiusKm = 2.0,
  }) async* {
    final courierId = _auth.currentUser?.uid;
    print('👤 Courier ID: $courierId');
    if (courierId == null) {
      yield [];
      return;
    }

    // Get courier's vehicle type
    final courierDoc = await _firestore.collection('couriers').doc(courierId).get();
    final vehicleType = courierDoc.data()?['vehicleType'] as String?;
    
    print('🚗 Courier vehicle type: $vehicleType');
    
    // Query only non-expired deliveries (created in last 1 minute)
    final oneMinuteAgo = Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 1)));
    
    print('⏰ Querying deliveries created after: ${oneMinuteAgo.toDate()}');
    
    // If no vehicle type set, show all deliveries (backward compatibility)
    if (vehicleType == null) {
      print('⚠️ No vehicle type set, showing all deliveries');
      yield* _firestore
          .collection('deliveries')
          .where('status', isEqualTo: 'searching')
          .where('deliveryType', isEqualTo: 'purl_courier')
          .snapshots()
          .map((snapshot) {
        print('📦 Query returned ${snapshot.docs.length} deliveries');
        final now = DateTime.now();
        final filtered = snapshot.docs
            .map((doc) => DeliveryRequest.fromFirestore(doc))
            .where((delivery) {
              // Only show deliveries from last 3 minutes
              final createdAt = delivery.createdAt.toDate();
              if (now.difference(createdAt).inMinutes > 3) {
                return false;
              }
              if (delivery.searchExpiresAt != null) {
                return delivery.searchExpiresAt!.toDate().isAfter(now);
              }
              return true;
            })
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        print('✅ After filtering: ${filtered.length} deliveries');
        return filtered;
      });
      return;
    }

    // Filter by vehicle type: motorcycle for standard, car for bulky
    print('🔍 Filtering deliveries for $vehicleType');
    yield* _firestore
        .collection('deliveries')
        .where('status', isEqualTo: 'searching')
        .where('deliveryType', isEqualTo: 'purl_courier')
        .snapshots()
        .map((snapshot) {
      print('📦 Query returned ${snapshot.docs.length} deliveries');
      final now = DateTime.now();
      final filtered = snapshot.docs
          .map((doc) => DeliveryRequest.fromFirestore(doc))
          .where((delivery) {
            // Only show deliveries from last 3 minutes
            final createdAt = delivery.createdAt.toDate();
            if (now.difference(createdAt).inMinutes > 3) {
              return false;
            }
            
            // Filter expired deliveries
            if (delivery.searchExpiresAt != null) {
              if (!delivery.searchExpiresAt!.toDate().isAfter(now)) {
                return false;
              }
            }
            
            // Filter by vehicle type
            final packageSize = delivery.packageSize ?? 'standard';
            if (vehicleType == 'motorcycle' && packageSize == 'bulky') {
              print('❌ Filtered out bulky package for motorcycle: ${delivery.orderNumber}');
              return false; // Motorcycles can't handle bulky packages
            }
            // Cars can handle both standard and bulky
            
            return true;
          })
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      print('✅ After filtering: ${filtered.length} deliveries');
      return filtered;
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

    // Get delivery data for order updates
    final deliveryDoc = await _firestore.collection('deliveries').doc(deliveryId).get();
    final deliveryData = deliveryDoc.data();
    final orderId = deliveryData?['orderId'] as String?;
    final storeId = deliveryData?['storeId'] as String?;
    final buyerId = deliveryData?['buyerId'] as String?;

    // Update order status when picked up
    if (status == 'picked_up' && orderId != null && storeId != null) {
      // Update store's order
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'picked_up',
        'shippedAt': FieldValue.serverTimestamp(),
      });
      
      // Update buyer's order copy
      if (buyerId != null && buyerId.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(buyerId)
            .collection('orders')
            .doc(orderId)
            .update({
          'status': 'picked_up',
          'shippedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // Update courier stats and order status if delivered
    if (status == 'delivered') {
      final courierId = _auth.currentUser?.uid;
      if (courierId != null) {
        final deliveryFee = (deliveryData?['deliveryFee'] ?? 0).toDouble();

        // Update courier stats
        await _firestore.collection('couriers').doc(courierId).update({
          'totalDeliveries': FieldValue.increment(1),
          'totalEarnings': FieldValue.increment(deliveryFee),
        });
        
        // Update store's order to delivered
        if (orderId != null && storeId != null) {
          await _firestore
              .collection('stores')
              .doc(storeId)
              .collection('orders')
              .doc(orderId)
              .update({
            'status': 'delivered',
            'deliveredAt': FieldValue.serverTimestamp(),
          });
          
          // Update buyer's order copy
          if (buyerId != null && buyerId.isNotEmpty) {
            await _firestore
                .collection('users')
                .doc(buyerId)
                .collection('orders')
                .doc(orderId)
                .update({
              'status': 'delivered',
              'deliveredAt': FieldValue.serverTimestamp(),
            });
          }
        }
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
  final String? packageSize; // Add package size field
  final Timestamp? searchExpiresAt;
  final double deliveryFee;
  final double distance;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final Timestamp createdAt;
  final Timestamp? assignedAt;
  final Timestamp? pickedUpAt;
  final Timestamp? deliveredAt;

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
    this.packageSize, // Add to constructor
    this.searchExpiresAt,
    required this.deliveryFee,
    required this.distance,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
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
      packageSize: data['packageSize'] as String?, // Read package size
      searchExpiresAt: data['searchExpiresAt'] as Timestamp?,
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      distance: (data['distance'] ?? 0).toDouble(),
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      assignedAt: data['assignedAt'] as Timestamp?,
      pickedUpAt: data['pickedUpAt'] as Timestamp?,
      deliveredAt: data['deliveredAt'] as Timestamp?,
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
