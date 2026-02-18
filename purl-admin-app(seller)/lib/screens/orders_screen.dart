import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/order_service.dart';
import '../services/currency_service.dart';
import '../services/delivery_service.dart';
import 'dart:async';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  final CurrencyService _currencyService = CurrencyService();
  final DeliveryService _deliveryService = DeliveryService();
  String _selectedFilter = 'All';

  List<StoreOrderData> _filterOrders(List<StoreOrderData> orders) {
    if (_selectedFilter == 'All') return orders;
    if (_selectedFilter == 'Done') {
      return orders.where((o) => o.status == 'delivered').toList();
    }
    return orders.where((o) => o.status == _selectedFilter.toLowerCase()).toList();
  }

  int _getCount(List<StoreOrderData> orders, String filter) {
    if (filter == 'All') return orders.length;
    if (filter == 'Done') {
      return orders.where((o) => o.status == 'delivered').length;
    }
    return orders.where((o) => o.status == filter.toLowerCase()).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<List<StoreOrderData>>(
          stream: _orderService.getStoreOrdersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.black));
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.warning_2, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('Error loading orders', style: GoogleFonts.poppins(color: Colors.grey[600])),
                  ],
                ),
              );
            }

            final allOrders = snapshot.data ?? [];
            final filteredOrders = _filterOrders(allOrders);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Orders',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showSearchSheet(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Iconsax.search_normal, color: Colors.grey[700], size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
                // Filter Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: ['All', 'Pending', 'Shipped', 'Done'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filter),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  filter,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected ? Colors.white : Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${_getCount(allOrders, filter)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // Orders List
                Expanded(
                  child: filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Iconsax.shopping_bag, size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No $_selectedFilter orders',
                                style: GoogleFonts.poppins(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredOrders.length + 1,
                          itemBuilder: (context, index) {
                            if (index == filteredOrders.length) {
                              return const SizedBox(height: 80);
                            }
                            final order = filteredOrders[index];
                            return _OrderItem(
                              order: order,
                              currencyService: _currencyService,
                              onAccept: () => _updateOrderStatus(order.id, 'shipped'),
                              onReject: () => _updateOrderStatus(order.id, 'refunded'),
                              onView: () => _showOrderDetails(context, order),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order updated to ${newStatus == 'shipped' ? 'Shipped' : 'Refunded'}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search orders...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  icon: Icon(Iconsax.search_normal, color: Colors.grey[600]),
                ),
                style: GoogleFonts.poppins(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, StoreOrderData order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order ${order.orderNumber}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.statusDisplay,
                      style: GoogleFonts.poppins(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _DetailSection(
                title: 'Customer',
                children: [
                  _DetailRow(icon: Iconsax.user, label: order.userName),
                  _DetailRow(icon: Iconsax.call, label: order.userPhone),
                  _DetailRow(
                    icon: Iconsax.location,
                    label: '${order.deliveryAddress['street'] ?? ''}, ${order.deliveryAddress['city'] ?? ''}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailSection(
                title: 'Items',
                children: order.items.map((item) {
                  return _ItemRow(
                    name: item.productName,
                    qty: item.quantity,
                    price: _currencyService.formatPriceWithCurrency(
                      item.sellerPrice * item.quantity,
                      item.currency,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
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
                        Text('Subtotal', style: GoogleFonts.poppins()),
                        Text(
                          _currencyService.formatPrice(order.subtotal),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (order.promoCode != null && order.promoCode!.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_offer, size: 16, color: Colors.green.shade700),
                              const SizedBox(width: 6),
                              Text(
                                'Promo (${order.promoCode})',
                                style: GoogleFonts.poppins(color: Colors.green.shade700),
                              ),
                            ],
                          ),
                          Text(
                            '-${_currencyService.formatPrice(order.promoDiscount ?? 0)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Shipping', style: GoogleFonts.poppins()),
                        Text(
                          _currencyService.formatPrice(order.shipping),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _currencyService.formatPrice(order.total),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return const Color(0xFF22C55E);
      case 'shipped':
        return Colors.blue;
      case 'pending':
        return const Color(0xFFFF9800);
      case 'refunded':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

}

class _OrderItem extends StatelessWidget {
  final StoreOrderData order;
  final CurrencyService currencyService;
  final VoidCallback onAccept, onReject, onView;

  const _OrderItem({
    required this.order,
    required this.currencyService,
    required this.onAccept,
    required this.onReject,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onView,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.orderNumber,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (order.promoCode != null && order.promoCode!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_offer, size: 12, color: Colors.green.shade700),
                              const SizedBox(width: 4),
                              Text(
                                order.promoCode!,
                                style: GoogleFonts.poppins(
                                  color: Colors.green.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.statusDisplay,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.userName,
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                    ),
                    Text(
                      order.itemsCount,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyService.formatPrice(order.total),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      order.timeAgo,
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
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
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final String name, price;
  final int qty;

  const _ItemRow({required this.name, required this.qty, required this.price});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$name x$qty',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
          Text(
            price,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ],
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
        // Courier accepted!
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
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
