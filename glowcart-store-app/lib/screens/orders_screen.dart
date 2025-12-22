import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedFilter = 'All';
  
  final List<Map<String, dynamic>> _orders = [
    {'orderId': '#GC-1234', 'customer': 'John Doe', 'items': '3 items', 'amount': '\$150.00', 'status': 'Pending', 'time': '2 min ago'},
    {'orderId': '#GC-1233', 'customer': 'Jane Smith', 'items': '1 item', 'amount': '\$320.00', 'status': 'Shipped', 'time': '1 hour ago'},
    {'orderId': '#GC-1232', 'customer': 'Mike Johnson', 'items': '5 items', 'amount': '\$85.00', 'status': 'Delivered', 'time': '3 hours ago'},
    {'orderId': '#GC-1231', 'customer': 'Sarah Williams', 'items': '2 items', 'amount': '\$210.00', 'status': 'Pending', 'time': '5 hours ago'},
    {'orderId': '#GC-1230', 'customer': 'David Brown', 'items': '4 items', 'amount': '\$445.00', 'status': 'Shipped', 'time': '1 day ago'},
    {'orderId': '#GC-1229', 'customer': 'Emma Wilson', 'items': '1 item', 'amount': '\$120.00', 'status': 'Delivered', 'time': '2 days ago'},
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'All') return _orders;
    if (_selectedFilter == 'Done') return _orders.where((o) => o['status'] == 'Delivered').toList();
    return _orders.where((o) => o['status'] == _selectedFilter).toList();
  }

  int _getCount(String filter) {
    if (filter == 'All') return _orders.length;
    if (filter == 'Done') return _orders.where((o) => o['status'] == 'Delivered').length;
    return _orders.where((o) => o['status'] == filter).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOrderSheet(context),
        backgroundColor: Colors.black,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Orders', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showSearchSheet(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                          child: Icon(Iconsax.search_normal, color: Colors.grey[700], size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Filter Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['All', 'Pending', 'Shipped', 'Done'].map((filter) => 
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _selectedFilter == filter ? Colors.black : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(filter, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: _selectedFilter == filter ? Colors.white : Colors.grey[600])),
                            Text('${_getCount(filter)}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _selectedFilter == filter ? Colors.white : Colors.black)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Orders List
            Expanded(
              child: _filteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.shopping_bag, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('No $_selectedFilter orders', style: GoogleFonts.poppins(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredOrders.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _filteredOrders.length) return const SizedBox(height: 80);
                        final order = _filteredOrders[index];
                        return _OrderItem(
                          orderId: order['orderId'],
                          customer: order['customer'],
                          items: order['items'],
                          amount: order['amount'],
                          status: order['status'],
                          time: order['time'],
                          onAccept: () => _updateOrderStatus(order['orderId'], 'Shipped'),
                          onReject: () => _removeOrder(order['orderId']),
                          onView: () => _showOrderDetails(context, order),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateOrderStatus(String orderId, String newStatus) {
    setState(() {
      final index = _orders.indexWhere((o) => o['orderId'] == orderId);
      if (index != -1) _orders[index]['status'] = newStatus;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order $orderId updated to $newStatus', style: GoogleFonts.poppins()), backgroundColor: Colors.black),
    );
  }

  void _removeOrder(String orderId) {
    setState(() => _orders.removeWhere((o) => o['orderId'] == orderId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order $orderId rejected', style: GoogleFonts.poppins()), backgroundColor: Colors.black),
    );
  }

  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
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

  void _showCreateOrderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Order', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _buildTextField('Customer Name', Iconsax.user),
            const SizedBox(height: 16),
            _buildTextField('Phone Number', Iconsax.call),
            const SizedBox(height: 16),
            _buildTextField('Delivery Address', Iconsax.location),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _orders.insert(0, {
                      'orderId': '#GC-${1235 + _orders.length}',
                      'customer': 'New Customer',
                      'items': '1 item',
                      'amount': '\$0.00',
                      'status': 'Pending',
                      'time': 'Just now',
                    });
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Create Order', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
          icon: Icon(icon, color: Colors.grey[600]),
        ),
        style: GoogleFonts.poppins(),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                  Text('Order ${order['orderId']}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                    child: Text(order['status'], style: GoogleFonts.poppins(color: Colors.grey[700], fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _DetailSection(title: 'Customer', children: [
                _DetailRow(icon: Iconsax.user, label: order['customer']),
                _DetailRow(icon: Iconsax.call, label: '+233 XX XXX XXXX'),
                _DetailRow(icon: Iconsax.location, label: 'Accra, Ghana'),
              ]),
              const SizedBox(height: 16),
              _DetailSection(title: 'Items', children: [
                _ItemRow(name: 'Product Item', qty: 1, price: order['amount']),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    Text(order['amount'], style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (order['status'] == 'Pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _removeOrder(order['orderId']);
                        },
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: Colors.grey[400]!), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text('Reject', style: GoogleFonts.poppins(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateOrderStatus(order['orderId'], 'Shipped');
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text('Accept', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                )
              else if (order['status'] == 'Shipped')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateOrderStatus(order['orderId'], 'Delivered');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Mark as Delivered', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  final String orderId, customer, items, amount, status, time;
  final VoidCallback onAccept, onReject, onView;

  const _OrderItem({required this.orderId, required this.customer, required this.items, required this.amount, required this.status, required this.time, required this.onAccept, required this.onReject, required this.onView});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onView,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(orderId, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                  child: Text(status, style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 11, fontWeight: FontWeight.w500)),
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
                    Text(customer, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
                    Text(items, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(amount, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
                    Text(time, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
            if (status == 'Pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: onReject, style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey[400]!)), child: Text('Reject', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 12)))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: onAccept, style: ElevatedButton.styleFrom(backgroundColor: Colors.black), child: Text('Accept', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)))),
                ],
              ),
            ],
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
        Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey[600])),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
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
      child: Row(children: [Icon(icon, size: 18, color: Colors.grey[600]), const SizedBox(width: 12), Text(label, style: GoogleFonts.poppins(fontSize: 14))]),
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
          Text('$name x$qty', style: GoogleFonts.poppins(fontSize: 14)),
          Text(price, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
