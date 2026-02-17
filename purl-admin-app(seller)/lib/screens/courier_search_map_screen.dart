import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';

class CourierSearchMapScreen extends StatefulWidget {
  final String deliveryId;
  final GeoPoint storeLocation;
  final GeoPoint buyerLocation;
  final double deliveryFee;
  
  const CourierSearchMapScreen({
    super.key,
    required this.deliveryId,
    required this.storeLocation,
    required this.buyerLocation,
    required this.deliveryFee,
  });

  @override
  State<CourierSearchMapScreen> createState() => _CourierSearchMapScreenState();
}

class _CourierSearchMapScreenState extends State<CourierSearchMapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  Timer? _searchTimer;
  int _secondsRemaining = 180; // 3 minutes
  int _nearbyCouriers = 0;
  bool _courierFound = false;

  @override
  void initState() {
    super.initState();
    _startSearchTimer();
    _loadMarkers();
    _listenForCourierAcceptance();
    _findNearbyCouriers();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startSearchTimer() {
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _handleSearchTimeout();
      }
    });
  }

  void _loadMarkers() {
    setState(() {
      // Store marker (pickup)
      _markers.add(Marker(
        markerId: const MarkerId('store'),
        position: LatLng(widget.storeLocation.latitude, widget.storeLocation.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ));

      // Buyer marker (dropoff)
      _markers.add(Marker(
        markerId: const MarkerId('buyer'),
        position: LatLng(widget.buyerLocation.latitude, widget.buyerLocation.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Delivery Location'),
      ));
    });
  }

  Future<void> _findNearbyCouriers() async {
    // Query nearby couriers
    final couriersSnapshot = await FirebaseFirestore.instance
        .collection('couriers')
        .where('verified', isEqualTo: true)
        .where('isOnline', isEqualTo: true)
        .get();

    int count = 0;
    for (var doc in couriersSnapshot.docs) {
      final data = doc.data();
      final location = data['currentLocation'] as GeoPoint?;
      
      if (location != null) {
        // Calculate distance (simple check within ~10km)
        final distance = _calculateDistance(
          widget.storeLocation.latitude,
          widget.storeLocation.longitude,
          location.latitude,
          location.longitude,
        );

        if (distance <= 2) {
          count++;
          // Add courier marker
          setState(() {
            _markers.add(Marker(
              markerId: MarkerId('courier_${doc.id}'),
              position: LatLng(location.latitude, location.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(title: data['fullName'] ?? 'Courier'),
            ));
          });
        }
      }
    }

    setState(() => _nearbyCouriers = count);
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth radius in km
    final dLat = (lat2 - lat1) * 0.017453292519943295;
    final dLon = (lon2 - lon1) * 0.017453292519943295;
    final a = (dLat / 2).abs() * (dLat / 2).abs() +
        (lat1 * 0.017453292519943295).abs() * (lat2 * 0.017453292519943295).abs() *
        (dLon / 2).abs() * (dLon / 2).abs();
    return R * 2 * (a).abs();
  }

  void _listenForCourierAcceptance() {
    FirebaseFirestore.instance
        .collection('deliveries')
        .doc(widget.deliveryId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data?['status'] == 'assigned') {
          setState(() => _courierFound = true);
          _searchTimer?.cancel();
          _showCourierFoundDialog(data?['assignedCourierName'] ?? 'Courier');
        }
      }
    });
  }

  void _handleSearchTimeout() {
    // Update delivery status to no_courier_available
    FirebaseFirestore.instance
        .collection('deliveries')
        .doc(widget.deliveryId)
        .update({'status': 'no_courier_available'});

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No courier available. Please try again later.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCourierFoundDialog(String courierName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.tick_circle, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Courier Found!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$courierName accepted your delivery request',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close map screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.storeLocation.latitude,
                widget.storeLocation.longitude,
              ),
              zoom: 17,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              // Fit bounds to show both markers
              Future.delayed(const Duration(milliseconds: 500), () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    LatLngBounds(
                      southwest: LatLng(
                        widget.storeLocation.latitude < widget.buyerLocation.latitude
                            ? widget.storeLocation.latitude
                            : widget.buyerLocation.latitude,
                        widget.storeLocation.longitude < widget.buyerLocation.longitude
                            ? widget.storeLocation.longitude
                            : widget.buyerLocation.longitude,
                      ),
                      northeast: LatLng(
                        widget.storeLocation.latitude > widget.buyerLocation.latitude
                            ? widget.storeLocation.latitude
                            : widget.buyerLocation.latitude,
                        widget.storeLocation.longitude > widget.buyerLocation.longitude
                            ? widget.storeLocation.longitude
                            : widget.buyerLocation.longitude,
                      ),
                    ),
                    100,
                  ),
                );
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
                      icon: const Icon(Iconsax.arrow_left),
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
                        const Icon(Iconsax.clock, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(_secondsRemaining),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom info card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Searching animation
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Searching for couriers...',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '$_nearbyCouriers couriers nearby',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Delivery fee
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Delivery Fee',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'UGX ${widget.deliveryFee.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
