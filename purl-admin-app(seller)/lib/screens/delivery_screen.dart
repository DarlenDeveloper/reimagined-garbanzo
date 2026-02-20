import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../services/order_service.dart';
import '../services/delivery_service.dart';
import '../services/currency_service.dart';

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
              return ListTile(
                title: Text(filter, style: GoogleFonts.poppins()),
                trailing: _selectedTimeFilter == filter ? const Icon(Iconsax.tick_circle) : null,
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
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[600],
                    indicator: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)),
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
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

      // Calculate delivery fee (simple calculation based on distance)
      final distance = _calculateDistance(
        storeLocation.latitude,
        storeLocation.longitude,
        buyerLocation.latitude,
        buyerLocation.longitude,
      );
      final deliveryFee = _calculateDeliveryFee(distance);

      // Create delivery request in Firestore
      final deliveryRef = await FirebaseFirestore.instance.collection('deliveries').add({
        'orderId': order.id,
        'orderNumber': order.orderNumber,
        'storeId': order.storeId,
        'storeName': orderData['storeName'] ?? 'Store',
        'storeLocation': storeLocation,
        'storeAddress': {}, // Add store address if available
        'storePhone': orderData['storePhone'] ?? '',
        'buyerName': order.userName,
        'buyerPhone': order.userPhone,
        'buyerLocation': buyerLocation,
        'buyerAddress': deliveryAddress,
        'deliveryType': 'purl_courier',
        'status': 'searching',
        'deliveryFee': deliveryFee,
        'distance': distance,
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

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delivery request created successfully',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
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

  double _calculateDeliveryFee(double distanceKm) {
    // UGX 325 per km
    const perKmFee = 325.0;
    return distanceKm * perKmFee;
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
