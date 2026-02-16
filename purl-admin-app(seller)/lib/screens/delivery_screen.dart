import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'request_delivery_screen.dart';
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
  
  String _selectedTimeFilter = 'Today';

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
                        Text('In Transit', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
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
                  CircleAvatar(radius: 18, backgroundColor: Colors.black, child: Text('D', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delivery Rider', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('On the way', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ),
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
        final deliveredAt = _getTimeAgo(delivery.createdAt);
        
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
  void _showMarkDeliveredDialog(StoreOrderData order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Mark as Delivered?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm that you have personally delivered this order:', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.orderNumber, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  Text('${order.userName} • ${order.items.length} items', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                  Text('${order.deliveryAddress['street']}, ${order.deliveryAddress['city']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600]))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _orderService.updateOrderStatus(order.id, 'delivered');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order ${order.orderNumber} marked as delivered!', style: GoogleFonts.poppins()),
                    backgroundColor: Colors.black,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: Text('Confirm Delivery', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // Request delivery rider for order
  void _requestDeliveryForOrder(StoreOrderData order) {
    final address = '${order.deliveryAddress['street'] ?? ''}, ${order.deliveryAddress['city'] ?? ''}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestDeliveryScreen(
          orderId: order.orderNumber,
          customerName: order.userName,
          deliveryAddress: address,
          orderAmount: _currencyService.formatPrice(order.total),
          onDeliveryRequested: () {
            // Delivery requested - order status will be updated by delivery service
          },
        ),
      ),
    );
  }

  // Tracking sheet for active deliveries
  void _showTrackingSheet(StoreOrderData delivery) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
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
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                    child: Text('In Transit', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Driver Info
            Row(
              children: [
                CircleAvatar(radius: 24, backgroundColor: Colors.black, child: Text('D', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delivery Rider', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text('On the way', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
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
      ),
    );
  }
}
