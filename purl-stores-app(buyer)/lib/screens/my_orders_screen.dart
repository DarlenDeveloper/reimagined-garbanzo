import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/colors.dart';
import '../services/order_service.dart';
import 'delivery_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundBeige,
        body: const Center(child: Text('Please log in to view orders')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Text('Deliveries', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
            Expanded(
              child: StreamBuilder<List<UserOrderData>>(
                stream: _orderService.getUserOrdersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.warning_2, size: 64, color: Colors.red.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text('Error loading orders', style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          Text('${snapshot.error}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  }

                  final allOrders = snapshot.data ?? [];
                  
                  if (allOrders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.box, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text('No orders yet', style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Text('Place your first order to see it here', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.7))),
                        ],
                      ),
                    );
                  }

                  final activeOrders = allOrders.where((order) {
                    return order.status != 'delivered' && order.status != 'cancelled';
                  }).toList();
                  
                  final completedOrders = allOrders.where((order) {
                    return order.status == 'delivered';
                  }).toList();

                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(14)),
                          labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                          padding: const EdgeInsets.all(4),
                          tabs: [
                            Tab(text: 'Active (${activeOrders.length})'),
                            Tab(text: 'Completed (${completedOrders.length})'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOrderList(activeOrders, 'No active orders', Iconsax.box_time),
                            _buildOrderList(completedOrders, 'No completed orders', Iconsax.tick_circle),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<UserOrderData> orders, String emptyMessage, IconData emptyIcon) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(emptyMessage, style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Your orders will appear here', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.7))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: orders.length,
      itemBuilder: (context, index) => _buildOrderCard(orders[index]),
    );
  }

  Widget _buildOrderCard(UserOrderData order) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryScreen(
            orderId: order.orderNumber,
            status: order.status,
            total: order.total,
            productName: order.storeName,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_getStatusIcon(order.status), color: _getStatusColor(order.status), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.orderNumber, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(_formatDate(order.createdAt), style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusLabel(order.status),
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _getStatusColor(order.status)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('\$${order.total.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: AppColors.surfaceVariant),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Iconsax.box, size: 18, color: AppColors.darkGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Order details',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Iconsax.arrow_right_3, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
      case 'pending':
        return const Color(0xFF3B82F6);
      case 'preparing':
      case 'shipped':
        return const Color(0xFFF59E0B);
      case 'picked':
      case 'picked_up':
      case 'in_transit':
        return AppColors.darkGreen;
      case 'delivered':
        return const Color(0xFF22C55E);
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
      case 'pending':
        return Iconsax.receipt_item;
      case 'preparing':
      case 'shipped':
        return Iconsax.box_time;
      case 'picked':
      case 'picked_up':
      case 'in_transit':
        return Iconsax.truck_fast;
      case 'delivered':
        return Iconsax.tick_circle;
      default:
        return Iconsax.box;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'confirmed':
      case 'pending':
        return 'Confirmed';
      case 'preparing':
      case 'shipped':
        return 'Preparing';
      case 'picked':
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
