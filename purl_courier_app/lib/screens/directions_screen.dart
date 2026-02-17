import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/delivery_service.dart';
import 'active_delivery_screen.dart';

class DirectionsScreen extends StatefulWidget {
  const DirectionsScreen({super.key});

  @override
  State<DirectionsScreen> createState() => _DirectionsScreenState();
}

class _DirectionsScreenState extends State<DirectionsScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final DeliveryService _deliveryService = DeliveryService();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
    } catch (e) {
      // Use default location if can't get current
      setState(() => _currentPosition = Position(
        latitude: 0.3476,
        longitude: 32.5825,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<DeliveryRequest>>(
        stream: _deliveryService.getMyDeliveries(),
        builder: (context, snapshot) {
          final activeDeliveries = snapshot.data ?? [];
          
          if (activeDeliveries.isNotEmpty) {
            // Show active delivery
            return _buildActiveDeliveryMap(activeDeliveries.first);
          } else {
            // Show simple street view
            return _buildSimpleMapView();
          }
        },
      ),
    );
  }

  Widget _buildActiveDeliveryMap(DeliveryRequest delivery) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              delivery.storeLocation.latitude,
              delivery.storeLocation.longitude,
            ),
            zoom: 14,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('pickup'),
              position: LatLng(
                delivery.storeLocation.latitude,
                delivery.storeLocation.longitude,
              ),
              infoWindow: InfoWindow(title: delivery.storeName),
            ),
            Marker(
              markerId: const MarkerId('dropoff'),
              position: LatLng(
                delivery.buyerLocation.latitude,
                delivery.buyerLocation.longitude,
              ),
              infoWindow: InfoWindow(title: delivery.buyerName),
            ),
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onMapCreated: (controller) => _mapController = controller,
        ),
        
        // Delivery info overlay
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.box, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              delivery.orderNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${delivery.distance.toStringAsFixed(1)} km • UGX ${delivery.deliveryFee.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ActiveDeliveryScreen(
                                deliveryId: delivery.id,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('View'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleMapView() {
    if (_currentPosition == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        zoom: 15,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      onMapCreated: (controller) => _mapController = controller,
    );
  }
}
