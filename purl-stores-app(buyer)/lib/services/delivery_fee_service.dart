import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class DeliveryFeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Pricing: 325 UGX per km
  static const double pricePerKm = 325.0;

  /// Calculate delivery fee for a store
  Future<DeliveryFeeEstimate> calculateDeliveryFee({
    required String storeId,
    required GeoPoint buyerLocation,
  }) async {
    try {
      print('🏪 Calculating delivery fee for store: $storeId');
      
      // Get store location
      final storeDoc = await _firestore.collection('stores').doc(storeId).get();
      
      if (!storeDoc.exists) {
        print('❌ Store not found: $storeId');
        return DeliveryFeeEstimate(
          storeId: storeId,
          distance: 0,
          fee: 0,
          error: 'Store not found',
        );
      }

      final storeData = storeDoc.data();
      final locationData = storeData?['location'];
      
      print('📍 Store location data type: ${locationData.runtimeType}');
      print('📍 Store location value: $locationData');

      GeoPoint? storeLocation;
      if (locationData is GeoPoint) {
        storeLocation = locationData;
      } else if (locationData is String) {
        print('⚠️ Store location is a String, not GeoPoint: $locationData');
      }

      if (storeLocation == null) {
        print('❌ Store location not available as GeoPoint');
        return DeliveryFeeEstimate(
          storeId: storeId,
          distance: 0,
          fee: 0,
          error: 'Store location not available',
        );
      }

      print('📍 Store location: ${storeLocation.latitude}, ${storeLocation.longitude}');
      print('📍 Buyer location: ${buyerLocation.latitude}, ${buyerLocation.longitude}');

      // Calculate distance
      final distance = _calculateDistance(
        storeLocation.latitude,
        storeLocation.longitude,
        buyerLocation.latitude,
        buyerLocation.longitude,
      );

      print('📏 Distance calculated: ${distance.toStringAsFixed(2)} km');

      // Calculate fee
      final fee = distance * pricePerKm;

      print('💰 Fee calculated: ${fee.toStringAsFixed(0)} UGX');

      return DeliveryFeeEstimate(
        storeId: storeId,
        distance: distance,
        fee: fee,
        storeName: storeData?['name'] ?? 'Store',
      );
    } catch (e) {
      print('❌ Error calculating delivery fee: $e');
      return DeliveryFeeEstimate(
        storeId: storeId,
        distance: 0,
        fee: 0,
        error: 'Failed to calculate delivery fee',
      );
    }
  }

  /// Calculate delivery fees for multiple stores
  Future<List<DeliveryFeeEstimate>> calculateDeliveryFeesForStores({
    required List<String> storeIds,
    required GeoPoint buyerLocation,
  }) async {
    final estimates = <DeliveryFeeEstimate>[];

    for (final storeId in storeIds) {
      final estimate = await calculateDeliveryFee(
        storeId: storeId,
        buyerLocation: buyerLocation,
      );
      estimates.add(estimate);
    }

    return estimates;
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadius * c;

    return distance;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
}

class DeliveryFeeEstimate {
  final String storeId;
  final String? storeName;
  final double distance; // in km
  final double fee; // in UGX
  final String? error;

  DeliveryFeeEstimate({
    required this.storeId,
    this.storeName,
    required this.distance,
    required this.fee,
    this.error,
  });

  bool get hasError => error != null;

  String get formattedDistance => '${distance.toStringAsFixed(1)} km';
  String get formattedFee => 'UGX ${fee.toStringAsFixed(0)}';
}
