import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsService {
  static const String _apiKey = 'AIzaSyAkTfLh7iFXsGJ4baSpRtzglNvlHhNmRHY';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Get route information from Google Directions API
  Future<RouteInfo?> getRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print('❌ Directions API error: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }

      final data = json.decode(response.body);

      if (data['status'] != 'OK') {
        print('❌ Directions API status: ${data['status']}');
        if (data['error_message'] != null) {
          print('Error message: ${data['error_message']}');
        }
        return null;
      }

      if (data['routes'] == null || data['routes'].isEmpty) {
        print('❌ No routes found in response');
        return null;
      }

      final route = data['routes'][0];
      final leg = route['legs'][0];

      final distanceMeters = leg['distance']['value'] as int;
      final durationSeconds = leg['duration']['value'] as int;
      final polylinePoints = route['overview_polyline']['points'] as String;

      final distanceKm = distanceMeters / 1000.0;
      final durationMinutes = (durationSeconds / 60.0).ceil();

      print('✅ Route found: ${distanceKm.toStringAsFixed(2)} km, ~$durationMinutes min');
      print('📍 Origin: ${origin.latitude},${origin.longitude}');
      print('📍 Destination: ${destination.latitude},${destination.longitude}');
      print('🔗 Full API URL: $url');

      return RouteInfo(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        polylinePoints: polylinePoints,
      );
    } catch (e) {
      print('❌ Error getting route: $e');
      return null;
    }
  }

  /// Calculate delivery fee based on route distance and package type
  /// Standard (Motorcycle): 500 UGX per km
  /// Bulky (Car): 1000 UGX per km
  /// Minimum: 1000 UGX
  /// Rounding: To nearest 500 UGX
  double calculateDeliveryFee(double routeDistanceKm, {String packageSize = 'standard'}) {
    final perKmRate = packageSize == 'bulky' ? 1000.0 : 500.0;
    const minimumFee = 1000.0;

    double rawFee = routeDistanceKm * perKmRate;
    double feeAfterMinimum = rawFee < minimumFee ? minimumFee : rawFee;
    double roundedFee = (feeAfterMinimum / 500).round() * 500.0;

    return roundedFee;
  }

  /// Decode polyline points to List<LatLng> for map display
  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}

class RouteInfo {
  final double distanceKm;
  final int durationMinutes;
  final String polylinePoints;

  RouteInfo({
    required this.distanceKm,
    required this.durationMinutes,
    required this.polylinePoints,
  });
}
