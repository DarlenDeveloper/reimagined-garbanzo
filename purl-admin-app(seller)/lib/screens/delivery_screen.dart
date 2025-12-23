import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'request_delivery_screen.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Orders that need delivery
  final List<Map<String, dynamic>> _pendingOrders = [
    {'orderId': '#GC-1234', 'customer': 'John Doe', 'address': '123 Main St, New York', 'items': '3 items', 'amount': '\$150.00', 'time': '2 min ago'},
    {'orderId': '#GC-1231', 'customer': 'Sarah Williams', 'address': '321 Beach Blvd, Miami', 'items': '2 items', 'amount': '\$210.00', 'time': '5 hours ago'},
    {'orderId': '#GC-1228', 'customer': 'Alex Turner', 'address': '999 Park Ave, Boston', 'items': '1 item', 'amount': '\$89.00', 'time': '1 day ago'},
  ];

  // Active deliveries (in progress)
  final List<Map<String, dynamic>> _activeDeliveries = [
    {'orderId': '#GC-1233', 'customer': 'Jane Smith', 'address': '456 Oak Ave, Chicago', 'status': 'In Transit', 'driver': 'Mike D.', 'eta': '25 min', 'amount': '\$320.00'},
    {'orderId': '#GC-1230', 'customer': 'David Brown', 'address': '555 Hill Rd, Seattle', 'status': 'Picked Up', 'driver': 'Tom K.', 'eta': '30 min', 'amount': '\$445.00'},
  ];

  // Completed deliveries
  final List<Map<String, dynamic>> _completedDeliveries = [
    {'orderId': '#GC-1232', 'customer': 'Mike Johnson', 'address': '789 Palm Rd, LA', 'status': 'Delivered', 'driver': 'Sam L.', 'deliveredAt': '11:05 AM', 'amount': '\$85.00'},
    {'orderId': '#GC-1229', 'customer': 'Emma Wilson', 'address': '777 Lake St, Denver', 'status': 'Delivered', 'driver': 'Chris P.', 'deliveredAt': 'Yesterday', 'amount': '\$120.00'},
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Deliveries', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        Text('Today', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 12)),
                        Icon(Iconsax.arrow_down_1, color: Colors.grey[700], size: 18),
                      ],
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
                  _buildStatCard('Awaiting', _pendingOrders.length.toString(), Iconsax.box_time, Colors.black),
                  const SizedBox(width: 12),
                  _buildStatCard('In Transit', _activeDeliveries.length.toString(), Iconsax.truck_fast, Colors.black),
                  const SizedBox(width: 12),
                  _buildStatCard('Delivered', _completedDeliveries.length.toString(), Iconsax.tick_circle, Colors.black),
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
                  Tab(text: 'Needs Delivery (${_pendingOrders.length})'),
                  Tab(text: 'Active (${_activeDeliveries.length})'),
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
                  _buildPendingOrdersTab(),
                  _buildActiveDeliveriesTab(),
                  _buildCompletedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
  Widget _buildPendingOrdersTab() {
    if (_pendingOrders.isEmpty) {
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
      itemCount: _pendingOrders.length,
      itemBuilder: (context, index) {
        final order = _pendingOrders[index];
        return _buildPendingOrderCard(order, index);
      },
    );
  }

  Widget _buildPendingOrderCard(Map<String, dynamic> order, int index) {
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
                      Text(order['orderId'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(order['time'], style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
              Text(order['amount'], style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Iconsax.user, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(order['customer'], style: GoogleFonts.poppins(fontSize: 13)),
              const Spacer(),
              Text(order['items'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Iconsax.location, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(child: Text(order['address'], style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showMarkDeliveredDialog(order, index),
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
                  onTap: () => _requestDeliveryForOrder(order, index),
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
  Widget _buildActiveDeliveriesTab() {
    if (_activeDeliveries.isEmpty) {
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
      itemCount: _activeDeliveries.length,
      itemBuilder: (context, index) {
        final delivery = _activeDeliveries[index];
        return _buildActiveDeliveryCard(delivery, index);
      },
    );
  }

  Widget _buildActiveDeliveryCard(Map<String, dynamic> delivery, int index) {
    final isInTransit = delivery['status'] == 'In Transit';
    return GestureDetector(
      onTap: () => _showTrackingSheet(delivery, index),
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
                      child: Icon(isInTransit ? Iconsax.truck_fast : Iconsax.box_tick, color: Colors.black, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(delivery['orderId'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                        Text(delivery['status'], style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                  child: Text('ETA: ${delivery['eta']}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Iconsax.user, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(delivery['customer'], style: GoogleFonts.poppins(fontSize: 13)),
                const Spacer(),
                Text(delivery['amount'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Iconsax.location, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(child: Text(delivery['address'], style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]))),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  CircleAvatar(radius: 18, backgroundColor: Colors.black, child: Text(delivery['driver'][0], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(delivery['driver'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('Delivery Rider', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Iconsax.call, size: 20), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Iconsax.message, size: 20), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  const SizedBox(width: 8),
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
  Widget _buildCompletedTab() {
    if (_completedDeliveries.isEmpty) {
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
      itemCount: _completedDeliveries.length,
      itemBuilder: (context, index) {
        final delivery = _completedDeliveries[index];
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
                          Text(delivery['orderId'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                          Text('Delivered ${delivery['deliveredAt']}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  Text(delivery['amount'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Iconsax.user, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(delivery['customer'], style: GoogleFonts.poppins(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Iconsax.location, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(child: Text(delivery['address'], style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Iconsax.truck_fast, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text('Delivered by ${delivery['driver']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Mark as self-delivered dialog
  void _showMarkDeliveredDialog(Map<String, dynamic> order, int index) {
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
                  Text(order['orderId'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  Text('${order['customer']} • ${order['items']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                  Text(order['address'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600]))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                final removed = _pendingOrders.removeAt(index);
                _completedDeliveries.insert(0, {
                  ...removed,
                  'status': 'Delivered',
                  'driver': 'Self',
                  'deliveredAt': 'Just now',
                });
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order ${order['orderId']} marked as delivered!', style: GoogleFonts.poppins()),
                  backgroundColor: Colors.black,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Text('Confirm Delivery', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // Request delivery rider for order
  void _requestDeliveryForOrder(Map<String, dynamic> order, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestDeliveryScreen(
          orderId: order['orderId'],
          customerName: order['customer'],
          deliveryAddress: order['address'],
          orderAmount: order['amount'],
          onDeliveryRequested: () {
            setState(() {
              final removed = _pendingOrders.removeAt(index);
              _activeDeliveries.insert(0, {
                ...removed,
                'status': 'Picked Up',
                'driver': 'Assigning...',
                'eta': '~30 min',
              });
            });
          },
        ),
      ),
    );
  }

  // Tracking sheet for active deliveries
  void _showTrackingSheet(Map<String, dynamic> delivery, int index) {
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
                        Text(delivery['orderId'], style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('${delivery['customer']} • ${delivery['amount']}', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                    child: Text(delivery['status'], style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Driver Info
            Row(
              children: [
                CircleAvatar(radius: 24, backgroundColor: Colors.black, child: Text(delivery['driver'][0], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(delivery['driver'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text('Delivery Rider • Toyota Hiace', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Iconsax.call, color: Colors.black), onPressed: () {}),
                IconButton(icon: const Icon(Iconsax.message, color: Colors.black), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 24),
            // Tracking Steps
            _TrackingStep(title: 'Order Picked Up', time: '10:30 AM', isCompleted: true),
            _TrackingStep(title: 'In Transit', time: '10:45 AM', isCompleted: delivery['status'] == 'In Transit', isCurrent: delivery['status'] == 'In Transit'),
            _TrackingStep(title: 'Arriving Soon', time: 'Est. ${delivery['eta']}', isCompleted: false),
            _TrackingStep(title: 'Delivered', time: '—', isCompleted: false, isLast: true),
            const SizedBox(height: 24),
            // Mark Delivered Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    final removed = _activeDeliveries.removeAt(index);
                    _completedDeliveries.insert(0, {
                      ...removed,
                      'status': 'Delivered',
                      'deliveredAt': 'Just now',
                    });
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Order ${delivery['orderId']} delivered!', style: GoogleFonts.poppins()),
                      backgroundColor: Colors.black,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
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

class _TrackingStep extends StatelessWidget {
  final String title, time;
  final bool isCompleted, isCurrent, isLast;

  const _TrackingStep({required this.title, required this.time, required this.isCompleted, this.isCurrent = false, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: isCompleted ? Colors.black : Colors.grey[300], shape: BoxShape.circle),
              child: isCompleted ? const Icon(Iconsax.tick_circle, color: Colors.white, size: 16) : null,
            ),
            if (!isLast) Container(width: 2, height: 30, color: isCompleted ? Colors.black : Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400, color: isCurrent ? Colors.black : Colors.grey[600])),
              Text(time, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
              SizedBox(height: isLast ? 0 : 16),
            ],
          ),
        ),
      ],
    );
  }
}
