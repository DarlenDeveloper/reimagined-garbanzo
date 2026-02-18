import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _lastLocationUpdateKey = 'last_location_update';
  static const Duration _updateInterval = Duration(hours: 5);

  /// Check if location update is needed (every 5 hours)
  Future<bool> shouldUpdateLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt(_lastLocationUpdateKey);
    
    if (lastUpdate == null) return true;
    
    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
    final now = DateTime.now();
    
    return now.difference(lastUpdateTime) >= _updateInterval;
  }

  /// Update store location in Firestore
  Future<void> updateStoreLocation(Position position) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Get store ID
    final storeQuery = await _firestore
        .collection('stores')
        .where('authorizedUsers', arrayContains: user.uid)
        .limit(1)
        .get();
    
    if (storeQuery.docs.isEmpty) return;
    
    final storeId = storeQuery.docs.first.id;
    
    // Update store location
    await _firestore.collection('stores').doc(storeId).update({
      'location': GeoPoint(position.latitude, position.longitude),
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    });

    // Save last update time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastLocationUpdateKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Get store location from Firestore
  Future<GeoPoint?> getStoreLocation() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final storeQuery = await _firestore
        .collection('stores')
        .where('authorizedUsers', arrayContains: user.uid)
        .limit(1)
        .get();
    
    if (storeQuery.docs.isEmpty) return null;
    
    final storeData = storeQuery.docs.first.data();
    return storeData['location'] as GeoPoint?;
  }
}
