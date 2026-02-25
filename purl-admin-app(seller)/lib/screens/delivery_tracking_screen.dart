import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/delivery_service.dart';
import '../services/directions_service.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final String deliveryId;
  final GeoPoint storeLocation;
  final GeoPoint buyerLocation;
  final String orderNumber;
  final String? routePolyline;

  const DeliveryTrackingScreen({
    super.key,
    required this.deliveryId,
    required this.storeLocation,
    required this.buyerLocation,
    required this.orderNumber,
    this.routePolyline,
  });

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  GoogleMapController? _mapController;
  final DeliveryService _deliveryService = DeliveryService();
  final DirectionsService _directionsService = DirectionsService();
  Timer? _countdownTimer;
  StreamSubscription? _deliverySubscription;
  StreamSubscription? _couriersSubscription;
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  DeliveryData? _delivery;
  List<Map<String, dynamic>> _nearbyCouriers = [];
  int _secondsRemaining = 180; // 3 minutes

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _listenToDelivery();
    _listenToNearbyCouriers();
    _startCountdown();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _countdownTimer?.cancel();
    _deliverySubscription?.cancel();
    _couriersSubscription?.cancel();
    super.dispose();
  }

  void _initializeMap() {
    _updateMarkers();
  }

  void _updateMarkers() {
    final markers = <Marker>{};
    final polylines = <Polyline>{};
    
    // Store marker (pickup)
    markers.add(Marker(
      markerId: const MarkerId('store'),
      position: LatLng(widget.storeLocation.latitude, widget.storeLocation.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Pickup Location'),
    ));
    
    // Buyer marker (delivery)
    markers.add(Marker(
      markerId: const MarkerId('buyer'),
      position: LatLng(widget.buyerLocation.latitude, widget.buyerLocation.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'Delivery Location'),
    ));
    
    // Draw route polyline if available
    if (widget.routePolyline != null) {
      final routePoints = _directionsService.decodePolyline(widget.routePolyline!);
      polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: const Color(0xFFfb2a0a),
        width: 4,
      ));
    }
    
    // Courier markers (if searching)
    if (_delivery?.isSearching == true) {
      for (var i = 0; i < _nearbyCouriers.length; i++) {
        final courier = _nearbyCouriers[i];
        final location = courier['currentLocation'] as GeoPoint?;
        if (location != null) {
          markers.add(Marker(
            markerId: MarkerId('courier_$i'),
            position: LatLng(location.latitude, location.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(title: courier['name'] ?? 'Courier'),
          ));
        }
      }
    }
    
    // Assigned courier marker (if assigned)
    if (_delivery?.courierLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('assigned_courier'),
        position: LatLng(
          _delivery!.courierLocation!.latitude,
          _delivery!.courierLocation!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: _delivery!.assignedCourierName ?? 'Courier'),
      ));
      
      // Update route polyline to show courier's current position
      if (widget.routePolyline != null) {
        final routePoints = _directionsService.decodePolyline(widget.routePolyline!);
        polylines.clear();
        polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: const Color(0xFFfb2a0a),
          width: 4,
        ));
      }
    }
    
    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
  }

  void _listenToDelivery() {
    _deliverySubscription = _deliveryService
        .listenToDelivery(widget.deliveryId)
        .listen((delivery) {
      if (delivery == null) return;
      
      setState(() => _delivery = delivery);
      _updateMarkers();
      
      if (delivery.isAssigned) {
        _countdownTimer?.cancel();
        _showSuccessBottomSheet();
      }
    });
  }

  void _listenToNearbyCouriers() {
    // Listen to online couriers within 5km radius
    _couriersSubscription = FirebaseFirestore.instance
        .collection('couriers')
        .where('isOnline', isEqualTo: true)
        .where('verified', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      final couriers = <Map<String, dynamic>>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final location = data['currentLocation'] as GeoPoint?;
        
        if (location != null) {
          final distance = _deliveryService.calculateDistance(
            widget.storeLocation,
            location,
          );
          
          if (distance <= 5) {
            couriers.add({
              'id': doc.id,
              'name': data['name'],
              'currentLocation': location,
              'distance': distance,
            });
          }
        }
      }
      
      setState(() => _nearbyCouriers = couriers);
      _updateMarkers();
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _deliveryService.markNoCourierAvailable(widget.deliveryId);
        _showTimeoutBottomSheet();
      }
    });
  }

  void _showSuccessBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Courier Found!',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _delivery?.assignedCourierName ?? 'Courier',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _delivery?.assignedCourierPhone ?? '',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(Iconsax.routing, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        '${_delivery?.distance.toStringAsFixed(1)} km',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Iconsax.money, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        'UGX ${_delivery?.deliveryFee.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeoutBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.access_time, color: Colors.orange, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'No Courier Available',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No couriers accepted the delivery request. You can try again or use self-delivery.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitMapToMarkers();
  }

  void _fitMapToMarkers() {
    if (_mapController == null) return;
    
    final bounds = LatLngBounds(
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
    );
    
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.storeLocation.latitude, widget.storeLocation.longitude),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          // Top bar with back button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _deliveryService.cancelDeliveryRequest(
                          widget.deliveryId,
                          reason: 'Cancelled by store',
                        );
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom sheet with delivery info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _delivery?.isAssigned == true
                      ? _buildAssignedContent()
                      : _buildSearchingContent(minutes, seconds),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingContent(int minutes, int seconds) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Countdown timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFfb2a0a).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.clock, color: Color(0xFFfb2a0a), size: 20),
              const SizedBox(width: 8),
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFfb2a0a),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Status text
        Text(
          'Searching for Courier',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Notifying nearby couriers...',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        
        // Order info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    widget.orderNumber,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (_delivery != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Iconsax.routing, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${_delivery!.distance.toStringAsFixed(1)} km',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      'UGX ${_delivery!.deliveryFee.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Available couriers count
        if (_nearbyCouriers.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.user, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Text(
                  '${_nearbyCouriers.length} courier${_nearbyCouriers.length == 1 ? '' : 's'} nearby',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        
        // Cancel button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              _deliveryService.cancelDeliveryRequest(
                widget.deliveryId,
                reason: 'Cancelled by store',
              );
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel Request',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Courier info
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFfb2a0a),
              child: Text(
                _delivery?.assignedCourierName?.substring(0, 1).toUpperCase() ?? 'C',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _delivery?.assignedCourierName ?? 'Courier',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _delivery?.assignedCourierPhone ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'On the way',
                style: GoogleFonts.poppins(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Delivery details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    widget.orderNumber,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Iconsax.routing, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${_delivery?.distance.toStringAsFixed(1)} km',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(
                    'UGX ${_delivery?.deliveryFee.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Close button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
