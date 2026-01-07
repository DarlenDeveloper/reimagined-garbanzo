import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notifications_screen.dart';
import 'analytics_screen.dart';
import 'discounts_screen.dart';
import 'request_delivery_screen.dart';
import 'main_screen.dart';
import 'messages_screen.dart';
import '../services/store_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final _storeService = StoreService();
  String _storeName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    try {
      // Get user's first name
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _storeName = user.displayName?.split(' ').first ?? 'there';
        });
      }
    } catch (e) {
      setState(() => _storeName = 'there');
    }
    setState(() => _isLoading = false);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getGreeting(), style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                          Text(_storeName, style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.black)),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MessagesScreen())),
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Iconsax.message, color: Colors.black),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                                    child: Center(child: Text('3', style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Iconsax.notification, color: Colors.black),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                                    child: Center(child: Text('2', style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildAnalyticsSection(),
                  const SizedBox(height: 28),
                  _buildRecentOrdersSection(),
                  const SizedBox(height: 28),
                  _buildQuickActionsSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Today's Overview", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen())), child: Text('View All', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 13))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _AnalyticCard(title: 'Sales', value: '\$2,450', icon: Iconsax.trend_up, trend: '+12%', delay: 0)),
            const SizedBox(width: 12),
            Expanded(child: _AnalyticCard(title: 'Orders', value: '18', icon: Iconsax.shopping_bag, trend: '+5', delay: 100)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _AnalyticCard(title: 'Visitors', value: '342', icon: Iconsax.eye, trend: '+28%', delay: 200)),
            const SizedBox(width: 12),
            Expanded(child: _AnalyticCard(title: 'Conversion', value: '5.3%', icon: Iconsax.chart_1, trend: '+0.8%', delay: 300)),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Orders', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
            TextButton(
              onPressed: () => MainScreen.navigateToTab(context, 1),
              child: Text('See All', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _OrderCard(orderId: '#GC-1234', customer: 'John Doe', amount: '\$150.00', status: 'Pending', time: '2 min ago', delay: 0),
        const SizedBox(height: 10),
        _OrderCard(orderId: '#GC-1233', customer: 'Jane Smith', amount: '\$320.00', status: 'Shipped', time: '1 hour ago', delay: 100),
        const SizedBox(height: 10),
        _OrderCard(orderId: '#GC-1232', customer: 'Mike Johnson', amount: '\$85.00', status: 'Delivered', time: '3 hours ago', delay: 200),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _ActionButton(icon: Iconsax.add_square, label: 'Add Product', onTap: () => MainScreen.navigateToTab(context, 2))),
            const SizedBox(width: 12),
            Expanded(child: _ActionButton(icon: Iconsax.truck_fast, label: 'New Delivery', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestDeliveryScreen())))),
            const SizedBox(width: 12),
            Expanded(child: _ActionButton(icon: Iconsax.ticket_discount, label: 'Discounts', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiscountsScreen())))),
          ],
        ),
      ],
    );
  }
}

class _AnalyticCard extends StatefulWidget {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final int delay;

  const _AnalyticCard({required this.title, required this.value, required this.icon, required this.trend, required this.delay});

  @override
  State<_AnalyticCard> createState() => _AnalyticCardState();
}

class _AnalyticCardState extends State<_AnalyticCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _controller.forward(); });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Icon(widget.icon, color: Colors.black, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                  child: Text(widget.trend, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(widget.value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black)),
            const SizedBox(height: 2),
            Text(widget.title, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final String orderId;
  final String customer;
  final String amount;
  final String status;
  final String time;
  final int delay;

  const _OrderCard({required this.orderId, required this.customer, required this.amount, required this.status, required this.time, required this.delay});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  Color get statusColor {
    switch (widget.status) {
      case 'Pending': return Colors.grey[600]!;
      case 'Shipped': return Colors.grey[700]!;
      case 'Delivered': return Colors.black;
      default: return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _slideAnimation = Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    Future.delayed(Duration(milliseconds: 300 + widget.delay), () { if (mounted) _controller.forward(); });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Iconsax.shopping_bag, color: Colors.black, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.orderId, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                          child: Text(widget.status, style: GoogleFonts.poppins(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.customer, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13)),
                        Text(widget.amount, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(widget.time, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: Colors.black, size: 26),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
