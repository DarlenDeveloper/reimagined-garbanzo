import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/delivery_service.dart';
import '../services/location_service.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final String deliveryId;
  
  const ActiveDeliveryScreen({
    super.key,
    required this.deliveryId,
  });

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final DeliveryService _deliveryService = DeliveryService();
  final LocationService _locationService = LocationService();
  Timer? _locationUpdateTimer;
  DeliveryRequest? _delivery;
  String _currentStatus = 'assigned';

  @override
  void initState() {
    super.initState();
    _loadDeliveryData();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveryData() async {
    final doc = await FirebaseFirestore.instance
        .collection('deliveries')
        .doc(widget.deliveryId)
        .get();
    
    if (doc.exists) {
      final data = doc.data();
      print('📦 Delivery data: storePhone=${data?['storePhone']}, buyerPhone=${data?['buyerPhone']}');
      
      setState(() {
        _delivery = DeliveryRequest.fromFirestore(doc);
        _currentStatus = _delivery!.status;
      });
      
      print('📦 Delivery object: storePhone=${_delivery!.storePhone}, buyerPhone=${_delivery!.buyerPhone}');
      
      // If phone numbers are missing, fetch them
      if (_delivery!.storePhone.isEmpty || _delivery!.buyerPhone.isEmpty) {
        await _fetchMissingPhoneNumbers();
      }
      
      _updateMarkers();
      // Route will be shown after map is created
    }
  }

  Future<void> _fetchMissingPhoneNumbers() async {
    if (_delivery == null) return;
    
    try {
      String storePhone = _delivery!.storePhone;
      String buyerPhone = _delivery!.buyerPhone;
      
      // Fetch store phone if missing
      if (storePhone.isEmpty && _delivery!.storeId.isNotEmpty) {
        final storeDoc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(_delivery!.storeId)
            .get();
        final storeData = storeDoc.data();
        storePhone = storeData?['contact']?['phone'] ?? '';
        print('📞 Fetched store phone: $storePhone');
      }
      
      // Fetch buyer phone if missing
      if (buyerPhone.isEmpty) {
        // Try to get buyerId from delivery data first
        final deliveryDoc = await FirebaseFirestore.instance
            .collection('deliveries')
            .doc(widget.deliveryId)
            .get();
        
        final deliveryData = deliveryDoc.data();
        String userId = deliveryData?['buyerId'] ?? '';
        
        // If no buyerId in delivery, get it from order
        if (userId.isEmpty && _delivery!.orderId.isNotEmpty) {
          final orderDoc = await FirebaseFirestore.instance
              .collection('stores')
              .doc(_delivery!.storeId)
              .collection('orders')
              .doc(_delivery!.orderId)
              .get();
          
          final orderData = orderDoc.data();
          userId = orderData?['userId'] ?? '';
        }
        
        if (userId.isNotEmpty) {
          // Get phone from user document
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          
          final userData = userDoc.data();
          buyerPhone = userData?['phoneNumber'] ?? '';
          print('📞 Fetched buyer phone from user doc: $buyerPhone');
        }
      }
      
      // Update delivery object with fetched phones
      if (storePhone.isNotEmpty || buyerPhone.isNotEmpty) {
        setState(() {
          _delivery = DeliveryRequest(
            id: _delivery!.id,
            orderId: _delivery!.orderId,
            orderNumber: _delivery!.orderNumber,
            storeId: _delivery!.storeId,
            storeName: _delivery!.storeName,
            storeLocation: _delivery!.storeLocation,
            storeAddress: _delivery!.storeAddress,
            storePhone: storePhone.isNotEmpty ? storePhone : _delivery!.storePhone,
            buyerName: _delivery!.buyerName,
            buyerPhone: buyerPhone.isNotEmpty ? buyerPhone : _delivery!.buyerPhone,
            buyerLocation: _delivery!.buyerLocation,
            buyerAddress: _delivery!.buyerAddress,
            status: _delivery!.status,
            packageSize: _delivery!.packageSize,
            searchExpiresAt: _delivery!.searchExpiresAt,
            deliveryFee: _delivery!.deliveryFee,
            distance: _delivery!.distance,
            items: _delivery!.items,
            totalAmount: _delivery!.totalAmount,
            createdAt: _delivery!.createdAt,
            assignedAt: _delivery!.assignedAt,
            pickedUpAt: _delivery!.pickedUpAt,
            deliveredAt: _delivery!.deliveredAt,
          );
        });
        print('✅ Updated delivery with phone numbers');
      }
    } catch (e) {
      print('❌ Error fetching phone numbers: $e');
    }
  }

  Future<void> _showAutomaticRoute() async {
    if (_delivery == null) return;
    
    // Show route to pickup if assigned, or to dropoff if picked up
    if (_currentStatus == 'assigned') {
      print('🗺️ Showing route to store (pickup)');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loading route to store...', style: GoogleFonts.poppins()),
          backgroundColor: Colors.black,
          duration: const Duration(seconds: 2),
        ),
      );
      await _getDirections(_delivery!.storeLocation);
    } else if (_currentStatus == 'picked_up' || _currentStatus == 'in_transit') {
      print('🗺️ Showing route to buyer (dropoff)');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loading route to customer...', style: GoogleFonts.poppins()),
          backgroundColor: Colors.black,
          duration: const Duration(seconds: 2),
        ),
      );
      await _getDirections(_delivery!.buyerLocation);
    }
  }

  void _startLocationUpdates() {
    // Update courier location and route every 15 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      await _locationService.updateDeliveryLocation(widget.deliveryId);
      // Refresh markers and route from new location
      if (_delivery != null) {
        _updateMarkers();
        await _showAutomaticRoute();
      }
    });
  }

  void _updateMarkers() async {
    if (_delivery == null) return;

    try {
      // Get current courier location
      final position = await Geolocator.getCurrentPosition();
      
      setState(() {
        _markers.clear();

        // Courier's current location marker
        _markers.add(Marker(
          markerId: const MarkerId('courier'),
          position: LatLng(position.latitude, position.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'You'),
        ));

        // Store marker (pickup)
        _markers.add(Marker(
          markerId: const MarkerId('store'),
          position: LatLng(
            _delivery!.storeLocation.latitude,
            _delivery!.storeLocation.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(title: _delivery!.storeName),
        ));

        // Buyer marker (dropoff)
        _markers.add(Marker(
          markerId: const MarkerId('buyer'),
          position: LatLng(
            _delivery!.buyerLocation.latitude,
            _delivery!.buyerLocation.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: _delivery!.buyerName),
        ));
      });
    } catch (e) {
      print('Error getting courier location: $e');
      // Fallback without courier marker
      setState(() {
        _markers.clear();

        // Store marker (pickup)
        _markers.add(Marker(
          markerId: const MarkerId('store'),
          position: LatLng(
            _delivery!.storeLocation.latitude,
            _delivery!.storeLocation.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(title: _delivery!.storeName),
        ));

        // Buyer marker (dropoff)
        _markers.add(Marker(
          markerId: const MarkerId('buyer'),
          position: LatLng(
            _delivery!.buyerLocation.latitude,
            _delivery!.buyerLocation.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: _delivery!.buyerName),
        ));
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _deliveryService.updateDeliveryStatus(widget.deliveryId, newStatus);
      setState(() => _currentStatus = newStatus);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status updated to ${_getStatusText(newStatus)}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.black,
          duration: const Duration(seconds: 2),
        ),
      );

      // Show new route after status change
      await _showAutomaticRoute();

      if (newStatus == 'delivered') {
        // Navigate back after delivery is complete
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error updating status: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'assigned':
        return 'Assigned';
      case 'picked_up':
        return 'Picked Up';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      default:
        return status;
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    print('📞 Attempting to call: $phoneNumber');
    
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number not available', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Clean phone number (remove spaces, dashes, etc)
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    print('📞 Cleaned number: $cleanNumber');
    
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );
    
    try {
      final canLaunch = await canLaunchUrl(launchUri);
      print('📞 Can launch: $canLaunch');
      
      if (canLaunch) {
        await launchUrl(launchUri);
      } else {
        throw 'Phone dialer not available';
      }
    } catch (e) {
      print('📞 Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not make call: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_delivery == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _delivery!.storeLocation.latitude,
                _delivery!.storeLocation.longitude,
              ),
              zoom: 17,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              // Show route after map is ready
              Future.delayed(const Duration(milliseconds: 500), () {
                _showAutomaticRoute();
              });
            },
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Iconsax.arrow_left, color: Color(0xFFb71000)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${_delivery!.distance.toStringAsFixed(1)} km',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom sheet
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.4,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Package details header
                        Text(
                          'Package details',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tracking ID
                        Text(
                          'Tracking ID',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _delivery!.orderNumber,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Departure
                        _buildLocationRow(
                          'Departure',
                          _delivery!.storeName,
                          _delivery!.pickupAddress,
                          _delivery!.storePhone,
                          const Color(0xFFb71000),
                          true,
                        ),
                        const SizedBox(height: 20),

                        // Arrival
                        _buildLocationRow(
                          'Arrival',
                          _delivery!.buyerName,
                          _delivery!.dropoffAddress,
                          _delivery!.buyerPhone,
                          const Color(0xFFb71000),
                          false,
                        ),
                        const SizedBox(height: 24),

                        // Package info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Iconsax.box, size: 24, color: Color(0xFFb71000)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${_delivery!.itemCount} item${_delivery!.itemCount > 1 ? 's' : ''}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                'UGX ${_delivery!.deliveryFee.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action buttons based on status
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    String label,
    String name,
    String address,
    String phone,
    Color color,
    bool isDeparture,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDeparture ? Iconsax.location : Iconsax.location_tick,
                color: color,
                size: 20,
              ),
            ),
            if (!isDeparture)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                address,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _makePhoneCall(phone),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.call,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_currentStatus == 'assigned') {
      // Show Arrive at Pickup button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateStatus('picked_up'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Picked Up Package',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      );
    } else if (_currentStatus == 'picked_up') {
      // Show Complete Delivery button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateStatus('delivered'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Complete Delivery',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.tick_circle, color: Color(0xFFb71000)),
            const SizedBox(width: 8),
            Text(
              'Delivery Completed',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openDirectionsToPickup() async {
    if (_delivery == null) return;
    
    // Get directions and draw route on map
    await _getDirections(_delivery!.storeLocation);
  }

  Future<void> _openDirectionsToDropoff() async {
    if (_delivery == null) return;
    
    // Get directions and draw route on map
    await _getDirections(_delivery!.buyerLocation);
  }

  Future<void> _getDirections(GeoPoint destination) async {
    try {
      // Get current location
      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
      );
      final origin = LatLng(position.latitude, position.longitude);
      final dest = LatLng(destination.latitude, destination.longitude);

      // Fetch directions from Google Directions API
      const apiKey = 'AIzaSyAkTfLh7iFXsGJ4baSpRtzglNvlHhNmRHY';
      final url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${dest.latitude},${dest.longitude}&'
          'key=$apiKey';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          // Decode polyline
          final polylinePoints = data['routes'][0]['overview_polyline']['points'];
          final List<LatLng> routeCoords = _decodePolyline(polylinePoints);
          
          setState(() {
            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: routeCoords,
                color: Colors.black,
                width: 5,
              ),
            );
          });

          // Animate camera to show route
          _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(
                  origin.latitude < dest.latitude ? origin.latitude : dest.latitude,
                  origin.longitude < dest.longitude ? origin.longitude : dest.longitude,
                ),
                northeast: LatLng(
                  origin.latitude > dest.latitude ? origin.latitude : dest.latitude,
                  origin.longitude > dest.longitude ? origin.longitude : dest.longitude,
                ),
              ),
              100,
            ),
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Route displayed on map',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.black,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        } else {
          throw Exception('No routes found');
        }
      } else {
        throw Exception('API returned status ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting directions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not load route. Check your internet connection.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
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
