import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/order_service.dart';
import '../services/delivery_service.dart';
import '../services/currency_service.dart';
import '../services/directions_service.dart';
import 'delivery_tracking_screen.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  final DeliveryService _deliveryService = DeliveryService();
  final CurrencyService _currencyService = CurrencyService();
  final DirectionsService _directionsService = DirectionsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _selectedTimeFilter = 'This Month';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showTimeFilterMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filter by Time', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...['Today', 'This Week', 'This Month', 'All Time'].map((filter) {
              final isSelected = _selectedTimeFilter == filter;
              return ListTile(
                title: Text(
                  filter,
                  style: GoogleFonts.poppins(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? const Color(0xFFfb2a0a) : Colors.black,
                  ),
                ),
                trailing: isSelected ? const Icon(Iconsax.tick_circle, color: Color(0xFFfb2a0a)) : null,
                onTap: () {
                  setState(() => _selectedTimeFilter = filter);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<List<StoreOrderData>>(
          stream: _orderService.getStoreOrdersStream(),
          builder: (context, orderSnapshot) {
            if (orderSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.black));
            }

            final allOrders = orderSnapshot.data ?? [];
            
            // Filter orders by time
            final filteredOrders = _filterOrdersByTime(allOrders);
            
            // Separate orders by delivery status
            final pendingOrders = filteredOrders.where((o) => o.status == 'pending').toList();
            final activeDeliveries = filteredOrders.where((o) => o.status == 'shipped').toList();
            final completedDeliveries = filteredOrders.where((o) => o.status == 'delivered').toList();

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Deliveries', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
                      GestureDetector(
                        onTap: _showTimeFilterMenu,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              Text(_selectedTimeFilter, style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 12)),
                              Icon(Iconsax.arrow_down_1, color: Colors.grey[700], size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Stats Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildStatCard('Awaiting', pendingOrders.length.toString(), Iconsax.box_time, Colors.black),
                      const SizedBox(width: 12),
                      _buildStatCard('In Transit', activeDeliveries.length.toString(), Iconsax.truck_fast, Colors.black),
                      const SizedBox(width: 12),
                      _buildStatCard('Delivered', completedDeliveries.length.toString(), Iconsax.tick_circle, Colors.black),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 48,
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(24)),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[600],
                    indicator: BoxDecoration(color: const Color(0xFFfb2a0a), borderRadius: BorderRadius.circular(20)),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                    padding: const EdgeInsets.all(4),
                    tabs: [
                      Tab(text: 'Needs Delivery (${pendingOrders.length})'),
                      Tab(text: 'Active (${activeDeliveries.length})'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPendingOrdersTab(pendingOrders),
                      _buildActiveDeliveriesTab(activeDeliveries),
                      _buildCompletedTab(completedDeliveries),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<StoreOrderData> _filterOrdersByTime(List<StoreOrderData> orders) {
    final now = DateTime.now();
    switch (_selectedTimeFilter) {
      case 'Today':
        return orders.where((o) {
          final orderDate = o.createdAt;
          return orderDate.year == now.year &&
                 orderDate.month == now.month &&
                 orderDate.day == now.day;
        }).toList();
      case 'This Week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return orders.where((o) => o.createdAt.isAfter(weekAgo)).toList();
      case 'This Month':
        return orders.where((o) {
          return o.createdAt.year == now.year &&
                 o.createdAt.month == now.month;
        }).toList();
      case 'All Time':
      default:
        return orders;
    }
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: Colors.black, size: 22),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // TAB 1: Orders awaiting delivery
  Widget _buildPendingOrdersTab(List<StoreOrderData> pendingOrders) {
    if (pendingOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.box_tick, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('All orders delivered!', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16)),
            Text('No pending deliveries', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingOrders.length,
      itemBuilder: (context, index) {
        final order = pendingOrders[index];
        return _buildPendingOrderCard(order);
      },
    );
  }

  Widget _buildPendingOrderCard(StoreOrderData order) {
    final timeAgo = _getTimeAgo(order.createdAt);
    final address = '${order.deliveryAddress['street'] ?? ''}, ${order.deliveryAddress['city'] ?? ''}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Iconsax.box_time, color: Colors.black, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.orderNumber, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(timeAgo, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
              Text(_currencyService.formatPrice(order.total), style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Iconsax.user, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(order.userName, style: GoogleFonts.poppins(fontSize: 13)),
              const Spacer(),
              Text('${order.items.length} items', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Iconsax.location, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(child: Text(address, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showMarkDeliveredDialog(order),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.tick_circle, size: 18),
                        const SizedBox(width: 6),
                        Text('Self Deliver', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _requestDeliveryForOrder(order),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFb71000),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.truck_fast, size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Text('Request Rider', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 2: Active deliveries in progress
  Widget _buildActiveDeliveriesTab(List<StoreOrderData> activeDeliveries) {
    if (activeDeliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.truck_fast, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No active deliveries', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeDeliveries.length,
      itemBuilder: (context, index) {
        final delivery = activeDeliveries[index];
        return _buildActiveDeliveryCard(delivery);
      },
    );
  }

  Widget _buildActiveDeliveryCard(StoreOrderData delivery) {
    final address = '${delivery.deliveryAddress['street'] ?? ''}, ${delivery.deliveryAddress['city'] ?? ''}';
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('deliveries')
          .where('orderId', isEqualTo: delivery.id)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        String? deliveryPersonName;
        String? deliveryPersonPhone;
        String? vehiclePlate;
        String? vehicleName;
        String? deliveryType;
        
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final deliveryData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          deliveryPersonName = deliveryData['assignedCourierName'];
          deliveryPersonPhone = deliveryData['assignedCourierPhone'];
          vehiclePlate = deliveryData['vehiclePlateNumber'];
          vehicleName = deliveryData['vehicleName'];
          deliveryType = deliveryData['deliveryType'];
        }
        
        final isSelfDelivery = deliveryType == 'self';
        
        return GestureDetector(
          onTap: () => _showTrackingSheet(delivery),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Iconsax.truck_fast, color: Colors.black, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(delivery.orderNumber, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                            Text(
                              isSelfDelivery ? 'Self Delivery' : 'In Transit',
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (!isSelfDelivery)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                        child: Text('ETA: ~30 min', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Iconsax.user, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(delivery.userName, style: GoogleFonts.poppins(fontSize: 13)),
                    const Spacer(),
                    Text(_currencyService.formatPrice(delivery.total), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Iconsax.location, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(child: Text(address, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]))),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.black,
                        child: Text(
                          deliveryPersonName?.substring(0, 1).toUpperCase() ?? 'D',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deliveryPersonName ?? 'Delivery Person',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            if (deliveryPersonPhone != null)
                              Text(
                                deliveryPersonPhone,
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                              ),
                            if (vehiclePlate != null || vehicleName != null)
                              Text(
                                '${vehicleName ?? ''} ${vehiclePlate ?? ''}'.trim(),
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                              ),
                          ],
                        ),
                      ),
                      if (!isSelfDelivery)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                          child: Text('Track', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // TAB 3: Completed deliveries
  Widget _buildCompletedTab(List<StoreOrderData> completedDeliveries) {
    if (completedDeliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.tick_circle, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No completed deliveries yet', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedDeliveries.length,
      itemBuilder: (context, index) {
        final delivery = completedDeliveries[index];
        final address = '${delivery.deliveryAddress['street'] ?? ''}, ${delivery.deliveryAddress['city'] ?? ''}';
        final deliveredAt = _getTimeAgo(delivery.deliveredAt ?? delivery.updatedAt);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Iconsax.tick_circle, color: Colors.black, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(delivery.orderNumber, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                          Text('Delivered $deliveredAt', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  Text(_currencyService.formatPrice(delivery.total), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Iconsax.user, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(delivery.userName, style: GoogleFonts.poppins(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Iconsax.location, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(child: Text(address, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Iconsax.truck_fast, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text('Delivered successfully', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  // Mark as self-delivered dialog
  // Show self-delivery form to collect delivery person details
  void _showMarkDeliveredDialog(StoreOrderData order) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final plateController = TextEditingController();
    final vehicleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Self-Delivery Details',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter delivery person information for ${order.orderNumber}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              
              // Delivery Person Name
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Delivery Person Name',
                  labelStyle: GoogleFonts.poppins(),
                  prefixIcon: const Icon(Iconsax.user),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter delivery person name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Phone Number
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: GoogleFonts.poppins(),
                  prefixIcon: const Icon(Iconsax.call),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.trim().length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Vehicle Name/Type
              TextFormField(
                controller: vehicleController,
                decoration: InputDecoration(
                  labelText: 'Vehicle Type',
                  labelStyle: GoogleFonts.poppins(),
                  hintText: 'e.g., Motorcycle, Car, Bicycle',
                  hintStyle: GoogleFonts.poppins(fontSize: 12),
                  prefixIcon: const Icon(Iconsax.car),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter vehicle type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Vehicle Plate Number
              TextFormField(
                controller: plateController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Vehicle Plate Number',
                  labelStyle: GoogleFonts.poppins(),
                  hintText: 'e.g., UAH 123A',
                  hintStyle: GoogleFonts.poppins(fontSize: 12),
                  prefixIcon: const Icon(Iconsax.card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter vehicle plate number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Assign Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      await _assignSelfDeliveryFromDeliveryScreen(
                        order,
                        nameController.text.trim(),
                        phoneController.text.trim(),
                        vehicleController.text.trim(),
                        plateController.text.trim(),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Assign Delivery',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _assignSelfDeliveryFromDeliveryScreen(
    StoreOrderData order,
    String runnerName,
    String runnerPhone,
    String vehicleName,
    String vehiclePlate,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF6C5CE7)),
              const SizedBox(height: 16),
              Text('Getting location...', style: GoogleFonts.poppins()),
            ],
          ),
        ),
      ),
    );

    try {
      // Get current location (pickup point)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enable location services', style: GoogleFonts.poppins()),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => Geolocator.openLocationSettings(),
            ),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location permission is required', style: GoogleFonts.poppins()),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enable location permission in settings', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
        return;
      }

      // Get current position as pickup location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      final storeLocation = GeoPoint(position.latitude, position.longitude);

      // Get delivery location from order
      final orderDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(order.storeId)
          .collection('orders')
          .doc(order.id)
          .get();

      final orderData = orderDoc.data();
      if (orderData == null || orderData['deliveryLocation'] == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This order doesn\'t have a delivery location',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final deliveryLocation = orderData['deliveryLocation'] as GeoPoint;
      final deliveryAddress = orderData['deliveryAddress'] as Map<String, dynamic>? ?? {};

      // Assign self-delivery
      await _deliveryService.assignSelfDelivery(
        orderId: order.id,
        orderNumber: order.orderNumber,
        storeLocation: storeLocation,
        buyerLocation: deliveryLocation,
        buyerAddress: deliveryAddress,
        buyerName: order.userName,
        buyerPhone: order.userPhone,
        totalAmount: order.total,
        items: order.items.map((item) => {
          'productName': item.productName,
          'quantity': item.quantity,
          'price': item.price,
        }).toList(),
        runnerId: 'self_${DateTime.now().millisecondsSinceEpoch}',
        runnerName: runnerName,
        runnerPhone: runnerPhone,
        vehiclePlateNumber: vehiclePlate,
        vehicleName: vehicleName,
      );

      // Update order status to shipped
      await _orderService.updateOrderStatus(order.id, 'shipped');

      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Self-delivery assigned to $runnerName',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.black,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to assign delivery: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Request delivery rider for order
  Future<void> _requestDeliveryForOrder(StoreOrderData order) async {
    // Check if order has packageSize, if not show selector dialog
    if (order.packageSize == null) {
      final selectedSize = await _showPackageSizeDialog();
      if (selectedSize == null) return; // User cancelled
      
      // Update order with selected package size
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(order.storeId)
          .collection('orders')
          .doc(order.id)
          .update({'packageSize': selectedSize});
      
      // Continue with updated package size
      await _proceedWithDeliveryRequest(order, selectedSize);
    } else {
      // Package size already set, proceed
      await _proceedWithDeliveryRequest(order, order.packageSize!);
    }
  }

  Future<String?> _showPackageSizeDialog() async {
    String? selectedSize;
    
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Package Type',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This order doesn\'t have a package type. Please select one:',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    
                    // Standard Package
                    GestureDetector(
                      onTap: () => setDialogState(() => selectedSize = 'standard'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selectedSize == 'standard' ? const Color(0xFFb71000) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedSize == 'standard' ? const Color(0xFFb71000) : Colors.grey[300]!,
                            width: selectedSize == 'standard' ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.driving5,
                              size: 24,
                              color: selectedSize == 'standard' ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Standard',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: selectedSize == 'standard' ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Under 15 kg • Motorcycle',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: selectedSize == 'standard' ? Colors.white70 : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selectedSize == 'standard')
                              const Icon(Iconsax.tick_circle5, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Bulky Package
                    GestureDetector(
                      onTap: () => setDialogState(() => selectedSize = 'bulky'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selectedSize == 'bulky' ? const Color(0xFFb71000) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedSize == 'bulky' ? const Color(0xFFb71000) : Colors.grey[300]!,
                            width: selectedSize == 'bulky' ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.car5,
                              size: 24,
                              color: selectedSize == 'bulky' ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bulky',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: selectedSize == 'bulky' ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Over 15 kg • Car/Vehicle',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: selectedSize == 'bulky' ? Colors.white70 : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selectedSize == 'bulky')
                              const Icon(Iconsax.tick_circle5, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext, null),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text('Cancel', style: GoogleFonts.poppins()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedSize != null
                                ? () => Navigator.pop(dialogContext, selectedSize)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFb71000),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              disabledBackgroundColor: Colors.grey[300],
                            ),
                            child: Text('Confirm', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _proceedWithDeliveryRequest(StoreOrderData order, String packageSize) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.black),
              const SizedBox(height: 16),
              Text('Getting location...', style: GoogleFonts.poppins()),
            ],
          ),
        ),
      ),
    );

    try {
      // Get current location (store location)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enable location services', style: GoogleFonts.poppins()),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => Geolocator.openLocationSettings(),
            ),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location permission is required', style: GoogleFonts.poppins()),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enable location permission in settings', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
        return;
      }

      // Get current position as store location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      final storeLocation = GeoPoint(position.latitude, position.longitude);

      // Get delivery location from order
      final orderDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(order.storeId)
          .collection('orders')
          .doc(order.id)
          .get();

      final orderData = orderDoc.data();
      if (orderData == null || orderData['deliveryLocation'] == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This order doesn\'t have a delivery location',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final buyerLocation = orderData['deliveryLocation'] as GeoPoint;
      final deliveryAddress = orderData['deliveryAddress'] as Map<String, dynamic>? ?? {};

      // Get route information from Google Directions API
      final routeInfo = await _directionsService.getRoute(
        origin: storeLocation,
        destination: buyerLocation,
      );

      double distance;
      double deliveryFee;
      String? polylinePoints;

      if (routeInfo != null) {
        // Use route distance from Directions API with package size
        distance = routeInfo.distanceKm;
        deliveryFee = _directionsService.calculateDeliveryFee(distance, packageSize: packageSize);
        polylinePoints = routeInfo.polylinePoints;
        print('✅ Using route distance: ${distance.toStringAsFixed(2)} km, Fee: UGX ${deliveryFee.toStringAsFixed(0)} ($packageSize)');
      } else {
        // Fallback to straight-line distance if API fails
        distance = _calculateDistance(
          storeLocation.latitude,
          storeLocation.longitude,
          buyerLocation.latitude,
          buyerLocation.longitude,
        );
        deliveryFee = _calculateDeliveryFee(distance, packageSize: packageSize);
        print('⚠️ Using straight-line distance (API failed): ${distance.toStringAsFixed(2)} km');
      }

      // Get store data for phone number
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(order.storeId)
          .get();
      
      final storeData = storeDoc.data();
      final storePhone = storeData?['contact']?['phone'] ?? '';
      final storeName = storeData?['name'] ?? 'Store';

      // Get buyer phone from user document
      String buyerPhone = '';
      if (order.userId.isNotEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(order.userId)
            .get();
        final userData = userDoc.data();
        buyerPhone = userData?['phoneNumber'] ?? '';
      }

      // Create delivery request in Firestore
      final deliveryRef = await FirebaseFirestore.instance.collection('deliveries').add({
        'orderId': order.id,
        'orderNumber': order.orderNumber,
        'storeId': order.storeId,
        'storeName': storeName,
        'storeLocation': storeLocation,
        'storeAddress': {}, // Add store address if available
        'storePhone': storePhone,
        'buyerId': order.userId,
        'buyerName': order.userName,
        'buyerPhone': buyerPhone,
        'buyerLocation': buyerLocation,
        'buyerAddress': deliveryAddress,
        'deliveryType': 'purl_courier',
        'status': 'searching',
        'packageSize': packageSize, // Store package size in delivery
        'deliveryFee': deliveryFee,
        'distance': distance,
        'routePolyline': polylinePoints, // Store polyline for map display
        'items': order.items.map((item) => {
          'productName': item.productName,
          'quantity': item.quantity,
          'price': item.price,
        }).toList(),
        'totalAmount': order.total,
        'createdAt': FieldValue.serverTimestamp(),
        'searchExpiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 3))),
      });

      Navigator.pop(context); // Close loading

      // Navigate to map-based tracking screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryTrackingScreen(
              deliveryId: deliveryRef.id,
              storeLocation: storeLocation,
              buyerLocation: buyerLocation,
              orderNumber: order.orderNumber,
              routePolyline: polylinePoints,
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to request delivery: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  double _calculateDeliveryFee(double distanceKm, {String packageSize = 'standard'}) {
    // Standard (motorcycle): 500 UGX/km, Bulky (car): 1000 UGX/km
    // Minimum 1000 UGX, rounded to nearest 500
    final perKmFee = packageSize == 'bulky' ? 1000.0 : 500.0;
    const minimumFee = 1000.0;
    
    final rawFee = distanceKm * perKmFee;
    final feeAfterMinimum = rawFee < minimumFee ? minimumFee : rawFee;
    final roundedFee = (feeAfterMinimum / 500).round() * 500.0;
    
    return roundedFee;
  }

  // Tracking sheet for active deliveries
  void _showTrackingSheet(StoreOrderData delivery) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('deliveries')
            .where('orderId', isEqualTo: delivery.id)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          String? deliveryPersonName;
          String? deliveryPersonPhone;
          String? vehiclePlate;
          String? vehicleName;
          String? deliveryType;
          
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final deliveryData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            deliveryPersonName = deliveryData['assignedCourierName'];
            deliveryPersonPhone = deliveryData['assignedCourierPhone'];
            vehiclePlate = deliveryData['vehiclePlateNumber'];
            vehicleName = deliveryData['vehicleName'];
            deliveryType = deliveryData['deliveryType'];
          }
          
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                // Order Info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(delivery.orderNumber, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                            Text('${delivery.userName} • ${_currencyService.formatPrice(delivery.total)}', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: deliveryType == 'self' ? const Color(0xFF6C5CE7) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          deliveryType == 'self' ? 'Self Delivery' : 'In Transit',
                          style: GoogleFonts.poppins(
                            color: deliveryType == 'self' ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Driver Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: deliveryType == 'self' ? const Color(0xFF6C5CE7) : Colors.black,
                      child: Text(
                        deliveryPersonName?.substring(0, 1).toUpperCase() ?? 'D',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deliveryPersonName ?? 'Delivery Rider',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          if (deliveryPersonPhone != null)
                            Text(
                              deliveryPersonPhone,
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (vehicleName != null || vehiclePlate != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Iconsax.car, size: 20, color: Colors.grey[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (vehicleName != null)
                                Text(
                                  vehicleName,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              if (vehiclePlate != null)
                                Text(
                                  vehiclePlate,
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Mark Delivered Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _orderService.updateOrderStatus(delivery.id, 'delivered');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Order ${delivery.orderNumber} delivered!', style: GoogleFonts.poppins()),
                            backgroundColor: Colors.black,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Mark as Delivered', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }
}


// Courier Search Dialog with Countdown
class _CourierSearchDialog extends StatefulWidget {
  final String deliveryId;
  final DeliveryService deliveryService;

  const _CourierSearchDialog({
    required this.deliveryId,
    required this.deliveryService,
  });

  @override
  State<_CourierSearchDialog> createState() => _CourierSearchDialogState();
}

class _CourierSearchDialogState extends State<_CourierSearchDialog> {
  Timer? _timer;
  StreamSubscription? _deliverySubscription;

  @override
  void initState() {
    super.initState();
    _listenToDelivery();
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _deliverySubscription?.cancel();
    super.dispose();
  }

  void _listenToDelivery() {
    _deliverySubscription = widget.deliveryService
        .listenToDelivery(widget.deliveryId)
        .listen((delivery) {
      if (delivery == null) return;

      if (delivery.isAssigned) {
        _timer?.cancel();
        if (mounted) {
          Navigator.pop(context);
          _showSuccessDialog(delivery);
        }
      }
    });
  }

  void _startTimeoutTimer() {
    _timer = Timer(const Duration(minutes: 3), () {
      if (mounted) {
        widget.deliveryService.markNoCourierAvailable(widget.deliveryId);
        Navigator.pop(context);
        _showTimeoutDialog();
      }
    });
  }

  void _showSuccessDialog(DeliveryData delivery) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Courier Found!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              delivery.assignedCourierName ?? 'Courier',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              delivery.assignedCourierPhone ?? '',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.routing, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${delivery.distance.toStringAsFixed(1)} km',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    'UGX ${delivery.deliveryFee.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.access_time, color: Colors.orange, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No Courier Available',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'No couriers accepted the delivery request. You can try again or assign your own delivery person.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DeliveryData?>(
      stream: widget.deliveryService.listenToDelivery(widget.deliveryId),
      builder: (context, snapshot) {
        final delivery = snapshot.data;
        final timeRemaining = delivery?.searchTimeRemaining ?? 180;
        final minutes = timeRemaining ~/ 60;
        final seconds = timeRemaining % 60;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Searching for Courier',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFfb2a0a)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Notifying nearby couriers...',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              if (delivery != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.routing, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${delivery.distance.toStringAsFixed(1)} km • UGX ${delivery.deliveryFee.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                widget.deliveryService.cancelDeliveryRequest(
                  widget.deliveryId,
                  reason: 'Cancelled by store',
                );
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
