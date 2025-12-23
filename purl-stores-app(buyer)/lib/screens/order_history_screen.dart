import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';
import 'delivery_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_Order> _orders = [
    _Order(
      id: 'ORD-2024-001',
      date: DateTime.now().subtract(const Duration(days: 2)),
      status: 'delivered',
      total: 154.97,
      items: [
        _OrderItem(name: 'Smart Watch WH22-6', quantity: 1, price: 154.97, storeName: 'TechZone'),
      ],
    ),
    _Order(
      id: 'ORD-2024-002',
      date: DateTime.now().subtract(const Duration(days: 5)),
      status: 'in_transit',
      total: 269.98,
      items: [
        _OrderItem(name: 'Nike Air Vapormax Plus', quantity: 1, price: 154.97, storeName: 'SneakerHub'),
        _OrderItem(name: 'Pullover Hoodie', quantity: 1, price: 65.00, storeName: 'UrbanStyle'),
        _OrderItem(name: 'Club Kit Archery Set', quantity: 1, price: 48.99, storeName: 'SportsPro'),
      ],
    ),
    _Order(
      id: 'ORD-2024-003',
      date: DateTime.now().subtract(const Duration(days: 12)),
      status: 'delivered',
      total: 450.00,
      items: [
        _OrderItem(name: 'Premium Boxing Gloves', quantity: 2, price: 196.99, storeName: 'SportsPro'),
        _OrderItem(name: 'Fitness Tracker Band', quantity: 1, price: 56.02, storeName: 'TechZone'),
      ],
    ),
    _Order(
      id: 'ORD-2024-004',
      date: DateTime.now().subtract(const Duration(days: 20)),
      status: 'cancelled',
      total: 89.99,
      items: [
        _OrderItem(name: 'Wireless Earbuds Pro', quantity: 1, price: 89.99, storeName: 'TechZone'),
      ],
    ),
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

  List<_Order> get _activeOrders => _orders.where((o) => o.status == 'in_transit' || o.status == 'processing').toList();
  List<_Order> get _completedOrders => _orders.where((o) => o.status == 'delivered').toList();
  List<_Order> get _cancelledOrders => _orders.where((o) => o.status == 'cancelled').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order History',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.darkGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
              padding: const EdgeInsets.all(4),
              tabs: [
                Tab(text: 'Active (${_activeOrders.length})'),
                Tab(text: 'Completed (${_completedOrders.length})'),
                Tab(text: 'Cancelled (${_cancelledOrders.length})'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_activeOrders, 'No active orders'),
                _buildOrderList(_completedOrders, 'No completed orders'),
                _buildOrderList(_cancelledOrders, 'No cancelled orders'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<_Order> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.box, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: orders.length,
      itemBuilder: (context, index) => _buildOrderCard(orders[index]),
    );
  }

  Widget _buildOrderCard(_Order order) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryScreen(
            orderId: order.id,
            status: order.status,
            total: order.total,
            productName: order.items.first.name,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(order.status),
                    color: _getStatusColor(order.status),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.id,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _formatDate(order.date),
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(order.status),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(order.status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(height: 1, color: AppColors.border),
          // Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...order.items.take(2).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F0E8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Iconsax.box, size: 18, color: AppColors.darkGreen),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                            ),
                            Text(
                              '${item.storeName} • Qty: ${item.quantity}',
                              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGreen),
                      ),
                    ],
                  ),
                )),
                if (order.items.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${order.items.length - 2} more items',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0E8),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
                ),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGreen),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return const Color(0xFF22C55E);
      case 'in_transit':
        return AppColors.darkGreen;
      case 'processing':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'delivered':
        return Iconsax.tick_circle;
      case 'in_transit':
        return Iconsax.truck_fast;
      case 'processing':
        return Iconsax.timer_1;
      case 'cancelled':
        return Iconsax.close_circle;
      default:
        return Iconsax.box;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'delivered':
        return 'Delivered';
      case 'in_transit':
        return 'In Transit';
      case 'processing':
        return 'Processing';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
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

  _Order({
    required this.id,
    required this.date,
    required this.status,
    required this.total,
    required this.items,
  });
}

class _OrderItem {
  final String name;
  final int quantity;
  final double price;
  final String storeName;

  _OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.storeName,
  });
}
