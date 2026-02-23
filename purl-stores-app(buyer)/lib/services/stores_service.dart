import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_service.dart';

class StoresService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  Future<List<Map<String, dynamic>>> getNearbyStores(double userLat, double userLon, {double radiusKm = 10}) async {
    try {
      // Limit to 100 stores for performance - filter by distance after
      final snapshot = await _firestore.collection('stores').limit(100).get();
      
      final stores = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final location = data['location'];
        
        if (location is GeoPoint) {
          final distance = _locationService.calculateDistance(
            userLat,
            userLon,
            location.latitude,
            location.longitude,
          );
          
          if (distance <= radiusKm) {
            stores.add({
              'id': doc.id,
              'name': data['name'] ?? 'Store',
              'category': data['category'] ?? 'General',
              'distance': distance,
              'distanceText': _locationService.formatDistance(distance),
              'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
              'latitude': location.latitude,
              'longitude': location.longitude,
              'logoUrl': data['logoUrl'] as String?,
            });
          }
        }
      }
      
      stores.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      
      return stores;
    } catch (e) {
      print('Error fetching nearby stores: $e');
      return [];
    }
  }

  Map<String, double> calculateRelativePosition(
    double storeLat,
    double storeLon,
    double userLat,
    double userLon,
    double maxDistanceKm,
  ) {
    final latDiff = storeLat - userLat;
    final lonDiff = storeLon - userLon;
    
    final scale = 0.4 / maxDistanceKm;
    
    final x = 0.5 + (lonDiff * scale * 100);
    final y = 0.5 - (latDiff * scale * 100);
    
    return {
      'x': x.clamp(0.1, 0.9),
      'y': y.clamp(0.1, 0.9),
    };
  }
}
