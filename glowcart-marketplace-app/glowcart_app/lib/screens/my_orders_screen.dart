import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';
import 'delivery_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_Order> _orders = [
    _Order(id: 'ORD-2024-001', date: DateTime.now().subtract(const Duration(hours: 2)), status: 'preparing', total: 154.97, items: [_OrderItem(name: 'Smart Watch WH22-6', quantity: 1, price: 154.97, storeName: 'TechZone')]),
    _Order(id: 'ORD-2024-002', date: DateTime.now().subtract(const Duration(days: 1)), status: 'in_transit', total: 269.98, items: [_OrderItem(name: 'Nike Air Vapormax Plus', quantity: 1, price: 154.97, storeName: 'SneakerHub'), _OrderItem(name: 'Pullover Hoodie', quantity: 1, price: 65.00, storeName: 'UrbanStyle')]),
    _Order(id: 'ORD-2024-003', date: DateTime.now().subtract(const Duration(days: 3)), status: 'confirmed', total: 89.99, items: [_OrderItem(name: 'Wireless Earbuds Pro', quantity: 1, price: 89.99, storeName: 'TechZone')]),
    _Order(id: 'ORD-2024-004', date: DateTime.now().subtract(const Duration(days: 7)), status: 'delivered', total: 450.00, items: [_OrderItem(name: 'Premium Boxing Gloves', quantity: 2, price: 196.99, storeName: 'SportsPro')]),
    _Order(id: 'ORD-2024-005', date: DateTime.now().subtract(const Duration(days: 14)), status: 'delivered', total: 320.00, items: [_OrderItem(name: 'Running Shoes', quantity: 1, price: 320.00, storeName: 'SneakerHub')]),
  ];

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

  List<_Order> get _activeOrders => _orders.where((o) => o.status != 'delivered').toList();
  List<_Order> get _completedOrders => _orders.where((o) => o.status == 'delivered').toList();

  @override
  Widget build(BuildContext context) {
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
                tabs: [Tab(text: 'Active (${_activeOrders.length})'), Tab(text: 'Completed (${_completedOrders.length})')],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildOrderList(_activeOrders, 'No active orders', Iconsax.box_time), _buildOrderList(_completedOrders, 'No completed orders', Iconsax.tick_circle)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<_Order> orders, String emptyMessage, IconData emptyIcon) {
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

  Widget _buildOrderCard(_Order order) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeliveryScreen(orderId: order.id, status: order.status, total: order.total, productName: order.items.first.name))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: _getStatusColor(order.status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(_getStatusIcon(order.status), color: _getStatusColor(order.status), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.id, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(_formatDate(order.date), style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _getStatusColor(order.status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(_getStatusLabel(order.status), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _getStatusColor(order.status))),
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
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Iconsax.box, size: 18, color: AppColors.darkGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.items.first.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      Text('${order.items.first.storeName}${order.items.length > 1 ? ' +${order.items.length - 1} more' : ''}', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
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
      case 'confirmed': return const Color(0xFF3B82F6);
      case 'preparing': return const Color(0xFFF59E0B);
      case 'picked':
      case 'in_transit': return AppColors.darkGreen;
      case 'delivered': return const Color(0xFF22C55E);
      default: return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed': return Iconsax.receipt_item;
      case 'preparing': return Iconsax.box_time;
      case 'picked':
      case 'in_transit': return Iconsax.truck_fast;
      case 'delivered': return Iconsax.tick_circle;
      default: return Iconsax.box;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'confirmed': return 'Confirmed';
      case 'preparing': return 'Preparing';
      case 'picked': return 'Picked Up';
      case 'in_transit': return 'In Transit';
      case 'delivered': return 'Delivered';
      default: return status;
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

class _Order {
  final String id;
  final DateTime date;
  final String status;
  final double total;
  final List<_OrderItem> items;
  _Order({required this.id, required this.date, required this.status, required this.total, required this.items});
}

class _OrderItem {
  final String name;
  final int quantity;
  final double price;
  final String storeName;
  _OrderItem({required this.name, required this.quantity, required this.price, required this.storeName});
}
