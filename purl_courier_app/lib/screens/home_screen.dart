import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/delivery_service.dart';
import '../services/location_service.dart';
import 'active_delivery_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  bool _isOnline = false;
  OverlayEntry? _overlayEntry;
  Timer? _inactivityTimer;
  static const Duration _inactivityDuration = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    _loadOnlineStatus();
    _listenForNewDeliveries();
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _locationService.stopLocationTracking();
    _removeOverlay();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () {
      if (_isOnline && mounted) {
        _toggleOnlineStatus(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You were set offline due to inactivity',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange[700],
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  void _resetInactivityTimer() {
    if (_isOnline) {
      _startInactivityTimer();
    }
  }

  void _listenForNewDeliveries() {
    DeliveryService().getAvailableDeliveries().listen((deliveries) {
      if (deliveries.isNotEmpty && _isOnline) {
        // Show popup for first delivery
        _showDynamicIslandPopup(deliveries.first);
      }
    });
  }

  Future<void> _loadOnlineStatus() async {
    final status = await _locationService.getOnlineStatus();
    setState(() => _isOnline = status);
    if (status) {
      _locationService.startLocationTracking();
    }
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    try {
      await _locationService.setOnlineStatus(value);
      setState(() => _isOnline = value);
      
      if (value) {
        _startInactivityTimer();
      } else {
        _inactivityTimer?.cancel();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'You are now online' : 'You are now offline',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: value ? Colors.black : Colors.grey[700],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final userId = authService.currentUser?.uid;

    return GestureDetector(
      onTap: _resetInactivityTimer,
      onPanDown: (_) => _resetInactivityTimer(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('couriers').doc(userId).snapshots(),
          builder: (context, courierSnapshot) {
            final data = courierSnapshot.data?.data() as Map<String, dynamic>?;
            final fullName = data?['fullName'] ?? 'Courier';
            final verified = data?['verified'] ?? false;
            
            return SafeArea(
              child: Column(
                children: [
                  _buildHeader(fullName, verified),
                  Expanded(
                    child: StreamBuilder<List<DeliveryRequest>>(
                      stream: DeliveryService().getMyDeliveries(),
                      builder: (context, activeSnapshot) {
                        return StreamBuilder<List<DeliveryRequest>>(
                          stream: DeliveryService().getCompletedDeliveries(),
                          builder: (context, completedSnapshot) {
                            final activeDeliveries = activeSnapshot.data ?? [];
                            final completedDeliveries = completedSnapshot.data ?? [];
                            
                            return SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Current Delivery - only show if exists
                                  if (activeDeliveries.isNotEmpty) ...[
                                    _buildSectionTitle('Current Delivery'),
                                    const SizedBox(height: 16),
                                    _buildFlightStyleCard(activeDeliveries.first),
                                    const SizedBox(height: 32),
                                  ],
                                  
                                  // Previous Delivery
                                  _buildSectionTitle('Previous Delivery'),
                                  const SizedBox(height: 16),
                                  completedDeliveries.isEmpty
                                      ? _buildEmptyPreviousDeliveryCard()
                                      : _buildPreviousDeliveryCard(completedDeliveries.first),
                                  const SizedBox(height: 32),
                                  
                                  // Recent Deliveries
                                  _buildSectionTitle('Recent Deliveries', showSeeAll: true),
                                  const SizedBox(height: 16),
                                  completedDeliveries.isEmpty
                                      ? _buildEmptyRecentDeliveriesCard()
                                      : Column(
                                          children: completedDeliveries
                                              .take(3)
                                              .map((delivery) => _buildRecentDeliveryItem(delivery))
                                              .toList(),
                                        ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String fullName, bool verified) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.black,
                child: const Icon(Iconsax.user, color: Colors.white),
              ),
              if (verified)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.verify5, color: Colors.blue, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $fullName',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isOnline ? 'Online' : 'Offline',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
            icon: Stack(
              children: [
                const Icon(Iconsax.notification, size: 24),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isOnline,
            onChanged: _toggleOnlineStatus,
            activeColor: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool showSeeAll = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        if (showSeeAll)
          TextButton(
            onPressed: () {},
            child: Text(
              'See All',
              style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyPreviousDeliveryCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Iconsax.clock, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No previous delivery',
            style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a delivery to see history',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecentDeliveriesCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Iconsax.box, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No recent deliveries',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightStyleCard(DeliveryRequest delivery) {
    String pickupCode = 'START';
    String dropoffCode = 'END';
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveDeliveryScreen(deliveryId: delivery.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a1a), Color(0xFF2d2d2d)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Iconsax.box, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    delivery.orderNumber,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    delivery.status == 'assigned' ? 'Pickup' : 'Delivering',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Route
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickupCode,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        delivery.storeName,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 2,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          const Icon(Iconsax.truck_fast, color: Colors.white, size: 16),
                          Expanded(
                            child: Container(
                              height: 2,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${delivery.distance.toStringAsFixed(1)} km',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        dropoffCode,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        delivery.buyerName,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: GoogleFonts.poppins(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Iconsax.routing_2, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            delivery.status == 'assigned' ? 'Go to Pickup' : 'In Transit',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Delivery Fee',
                      style: GoogleFonts.poppins(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UGX ${delivery.deliveryFee.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousDeliveryCard(DeliveryRequest delivery) {
    String pickupCode = 'START';
    String dropoffCode = 'END';
    
    // Calculate real duration from assignedAt to deliveredAt
    String duration = 'N/A';
    if (delivery.assignedAt != null && delivery.deliveredAt != null) {
      final startTime = delivery.assignedAt!.toDate();
      final endTime = delivery.deliveredAt!.toDate();
      final difference = endTime.difference(startTime);
      
      if (difference.inHours > 0) {
        duration = '${difference.inHours}h ${difference.inMinutes % 60}m';
      } else {
        duration = '${difference.inMinutes}m';
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a1a), Color(0xFF2d2d2d)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  delivery.orderNumber,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Completed',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Route
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pickupCode,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      delivery.storeName,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 2,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        const Icon(Iconsax.tick_circle, color: Colors.white, size: 16),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${delivery.distance.toStringAsFixed(1)} km',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dropoffCode,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      delivery.buyerName,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Duration, Payment, and Rating
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duration',
                      style: GoogleFonts.poppins(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Iconsax.clock, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          duration,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Payment',
                      style: GoogleFonts.poppins(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UGX ${delivery.deliveryFee.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rating',
                      style: GoogleFonts.poppins(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Iconsax.star1, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'N/A',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDeliveriesSection() {
    return StreamBuilder<List<DeliveryRequest>>(
      stream: DeliveryService().getCompletedDeliveries(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }

        final deliveries = snapshot.data ?? [];
        if (deliveries.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Iconsax.box, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No recent deliveries',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: deliveries.take(3).map((delivery) => _buildRecentDeliveryItem(delivery)).toList(),
        );
      },
    );
  }

  Widget _buildRecentDeliveryItem(DeliveryRequest delivery) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.tick_circle, size: 24, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delivery.orderNumber,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                Text(
                  delivery.storeName,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            'UGX ${delivery.deliveryFee.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }


  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showDynamicIslandPopup(DeliveryRequest delivery) {
    _removeOverlay(); // Remove any existing overlay

    _overlayEntry = OverlayEntry(
      builder: (context) => _DynamicIslandPopup(
        delivery: delivery,
        onAccept: () {
          _removeOverlay();
          _acceptDelivery(delivery.id);
        },
        onReject: () {
          _removeOverlay();
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isHighlighted ? Colors.black : Colors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _acceptDelivery(String deliveryId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.black),
              const SizedBox(height: 16),
              Text('Accepting delivery...', style: GoogleFonts.poppins()),
            ],
          ),
        ),
      ),
    );

    try {
      await DeliveryService().acceptDelivery(deliveryId);
      Navigator.pop(context); // Close loading
      
      // Auto-navigate to Active Delivery Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveDeliveryScreen(deliveryId: deliveryId),
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delivery accepted! Navigate to pickup location.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.black,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept delivery: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


// iOS Dynamic Island Style Popup
class _DynamicIslandPopup extends StatefulWidget {
  final DeliveryRequest delivery;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _DynamicIslandPopup({
    required this.delivery,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_DynamicIslandPopup> createState() => _DynamicIslandPopupState();
}

class _DynamicIslandPopupState extends State<_DynamicIslandPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto dismiss after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onReject();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1a1a1a), Color(0xFF2d2d2d)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header Row
                        Row(
                          children: [
                            const Icon(Iconsax.box, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'New Delivery Request',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    widget.delivery.orderNumber,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _dismiss,
                              icon: const Icon(Icons.close, color: Colors.white70, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Details Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildCompactDetail('Store', widget.delivery.storeName),
                            Container(width: 1, height: 30, color: Colors.white24),
                            _buildCompactDetail('Distance', '${widget.delivery.distance.toStringAsFixed(1)} km'),
                            Container(width: 1, height: 30, color: Colors.white24),
                            _buildCompactDetail('Fee', 'UGX ${widget.delivery.deliveryFee.toStringAsFixed(0)}'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Buttons Row
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _dismiss,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Reject',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _controller.reverse().then((_) {
                                    widget.onAccept();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Accept',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDetail(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white60,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: isHighlighted ? Colors.white : Colors.white,
            fontSize: 13,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
