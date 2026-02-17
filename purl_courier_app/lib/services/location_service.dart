import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _locationTimer;
  bool _isTracking = false;

  /// Start tracking courier location
  Future<void> startLocationTracking() async {
    if (_isTracking) return;

    final courierId = _auth.currentUser?.uid;
    if (courierId == null) return;

    // Check permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    _isTracking = true;

    // Update location immediately
    await _updateLocation();

    // Update location every 30 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _updateLocation();
    });
  }

  /// Stop tracking courier location
  void stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isTracking = false;
  }

  /// Update courier location in Firestore
  Future<void> _updateLocation() async {
    try {
      final courierId = _auth.currentUser?.uid;
      if (courierId == null) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      await _firestore.collection('couriers').doc(courierId).update({
        'currentLocation': GeoPoint(position.latitude, position.longitude),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  /// Set courier online status
  Future<void> setOnlineStatus(bool isOnline) async {
    final courierId = _auth.currentUser?.uid;
    if (courierId == null) return;

    await _firestore.collection('couriers').doc(courierId).update({
      'isOnline': isOnline,
      'lastStatusUpdate': FieldValue.serverTimestamp(),
    });

    if (isOnline) {
      await startLocationTracking();
    } else {
      stopLocationTracking();
    }
  }

  /// Get current online status
  Future<bool> getOnlineStatus() async {
    final courierId = _auth.currentUser?.uid;
    if (courierId == null) return false;

    final doc = await _firestore.collection('couriers').doc(courierId).get();
    return doc.data()?['isOnline'] ?? false;
  }

  /// Update location for active delivery
  Future<void> updateDeliveryLocation(String deliveryId) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _firestore.collection('deliveries').doc(deliveryId).update({
        'courierLocation': GeoPoint(position.latitude, position.longitude),
        'courierLocationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating delivery location: $e');
    }
  }

  bool get isTracking => _isTracking;
}
