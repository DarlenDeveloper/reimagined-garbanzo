import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'directions_service.dart';

class DeliveryFeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DirectionsService _directionsService = DirectionsService();
  
  // Cache to prevent flickering
  final Map<String, DeliveryFeeEstimate> _cache = {};
  
  // Pricing based on package type
  static const double standardPricePerKm = 500.0; // Motorcycle
  static const double bulkyPricePerKm = 1000.0; // Car
  static const double minimumFee = 1000.0;

  /// Calculate delivery fee for a store using Google Directions API
  Future<DeliveryFeeEstimate> calculateDeliveryFee({
    required String storeId,
    required GeoPoint buyerLocation,
    String packageSize = 'standard', // standard or bulky
  }) async {
    // Check cache first to prevent flickering
    final cacheKey = '$storeId-${buyerLocation.latitude}-${buyerLocation.longitude}-$packageSize';
    if (_cache.containsKey(cacheKey)) {
      print('💾 Using cached delivery fee for $storeId');
      return _cache[cacheKey]!;
    }

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

      // Get route from Google Directions API
      final routeInfo = await _directionsService.getRoute(
        origin: storeLocation,
        destination: buyerLocation,
      );

      double distance;
      double fee;
      int? estimatedDuration;

      if (routeInfo != null) {
        // Use route-based distance
        distance = routeInfo.distanceKm;
        estimatedDuration = routeInfo.durationMinutes;
        print('✅ Using route distance: ${distance.toStringAsFixed(2)} km');
      } else {
        // Fallback to straight-line distance
        distance = _calculateDistance(
          storeLocation.latitude,
          storeLocation.longitude,
          buyerLocation.latitude,
          buyerLocation.longitude,
        );
        print('⚠️ Using fallback straight-line distance: ${distance.toStringAsFixed(2)} km');
      }

      // Calculate fee based on package size
      final pricePerKm = packageSize == 'bulky' ? bulkyPricePerKm : standardPricePerKm;
      final rawFee = distance * pricePerKm;
      final feeAfterMinimum = rawFee < minimumFee ? minimumFee : rawFee;
      fee = ((feeAfterMinimum / 500).round() * 500).toDouble(); // Round to nearest 500

      print('💰 Fee calculated: ${fee.toStringAsFixed(0)} UGX (${packageSize == 'bulky' ? 'Car' : 'Motorcycle'})');

      final estimate = DeliveryFeeEstimate(
        storeId: storeId,
        distance: distance,
        fee: fee,
        storeName: storeData?['name'] ?? 'Store',
        estimatedDuration: estimatedDuration,
        polylinePoints: routeInfo?.polylinePoints,
      );

      // Cache the result
      _cache[cacheKey] = estimate;

      return estimate;
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
    String packageSize = 'standard',
  }) async {
    final estimates = <DeliveryFeeEstimate>[];

    for (final storeId in storeIds) {
      final estimate = await calculateDeliveryFee(
        storeId: storeId,
        buyerLocation: buyerLocation,
        packageSize: packageSize,
      );
      estimates.add(estimate);
    }

    return estimates;
  }

  /// Calculate distance between two points using Haversine formula (fallback)
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

  /// Clear cache (call when location changes significantly)
  void clearCache() {
    _cache.clear();
  }
}

class DeliveryFeeEstimate {
  final String storeId;
  final String? storeName;
  final double distance; // in km
  final double fee; // in UGX
  final String? error;
  final int? estimatedDuration; // in minutes
  final String? polylinePoints; // encoded polyline for map

  DeliveryFeeEstimate({
    required this.storeId,
    this.storeName,
    required this.distance,
    required this.fee,
    this.error,
    this.estimatedDuration,
    this.polylinePoints,
  });

  bool get hasError => error != null;

  String get formattedDistance => '${distance.toStringAsFixed(1)} km';
  String get formattedFee => 'UGX ${fee.toStringAsFixed(0)}';
  String get formattedDuration => estimatedDuration != null ? '~$estimatedDuration min' : '';
}
