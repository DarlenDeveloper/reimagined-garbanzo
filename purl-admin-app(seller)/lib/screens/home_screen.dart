import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notifications_screen.dart';
import 'analytics_screen.dart';
import 'discounts_screen.dart';
import 'main_screen.dart';
import 'messages_screen.dart';
import 'store_verification_screen.dart';
import 'live_screen.dart';
import 'product_questions_screen.dart';
import '../services/store_service.dart';
import '../services/messages_service.dart';
import '../services/order_service.dart';
import '../services/currency_service.dart';
import '../services/visitor_service.dart';
import '../services/verification_service.dart';
import '../services/product_questions_service.dart';

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
  final _messagesService = MessagesService();
  final _orderService = OrderService();
  final _currencyService = CurrencyService();
  final _visitorService = VisitorService();
  final _verificationService = VerificationService();
  String _storeName = '';
  String? _storeId;
  bool _isLoading = true;
  bool _showVerificationBanner = true;

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
      // Check if banner was dismissed
      final prefs = await SharedPreferences.getInstance();
      final bannerDismissed = prefs.getBool('hide_verification_banner') ?? false;
      setState(() => _showVerificationBanner = !bannerDismissed);
      
      // Get user's first name and store ID
      final user = FirebaseAuth.instance.currentUser;
      print('👤 Current user: ${user?.uid}');
      
      if (user != null) {
        setState(() {
          _storeName = user.displayName?.split(' ').first ?? 'there';
        });
        
        // Get the actual store ID from the stores collection
        final storeQuery = await FirebaseFirestore.instance
            .collection('stores')
            .where('authorizedUsers', arrayContains: user.uid)
            .limit(1)
            .get();
        
        print('🔍 Store query results: ${storeQuery.docs.length} stores found');
        
        if (storeQuery.docs.isNotEmpty) {
          final storeId = storeQuery.docs.first.id;
          setState(() {
            _storeId = storeId;
          });
          print('🏪 Store ID loaded: $storeId');
          
          // Debug: Check if visitors collection exists
          final visitorsSnapshot = await FirebaseFirestore.instance
              .collection('stores')
              .doc(storeId)
              .collection('visitors')
              .get();
          print('👥 Total visitors in collection: ${visitorsSnapshot.docs.length}');
          
          // Debug: Check today's visitors
          final today = DateTime.now();
          final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final todayVisitors = await FirebaseFirestore.instance
              .collection('stores')
              .doc(storeId)
              .collection('visitors')
              .where('lastVisitDate', isEqualTo: dateKey)
              .get();
          print('📅 Today\'s visitors ($dateKey): ${todayVisitors.docs.length}');
        } else {
          print('⚠️ No store found for user: ${user.uid}');
        }
      }
    } catch (e) {
      print('❌ Error loading store data: $e');
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
    if (hour >= 0 && hour < 5) return 'Good Night';
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// Format large numbers with K, M, B suffixes
  String _formatCompactNumber(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
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
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LiveScreen())),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFb71000),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.play_circle, color: Colors.white, size: 24),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MessagesScreen())),
                            child: _storeId == null
                                ? Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Iconsax.message, color: Colors.black),
                                  )
                                : StreamBuilder<int>(
                                    stream: Stream.periodic(const Duration(seconds: 2)).asyncMap((_) => _messagesService.getTotalUnreadCount(_storeId!)),
                                    builder: (context, snapshot) {
                                      final unreadCount = snapshot.data ?? 0;
                                      return Stack(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                                            child: const Icon(Iconsax.message, color: Colors.black),
                                          ),
                                          if (unreadCount > 0)
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: Container(
                                                width: 18,
                                                height: 18,
                                                decoration: const BoxDecoration(color: Color(0xFFfb2a0a), shape: BoxShape.circle),
                                                child: Center(
                                                  child: Text(
                                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Iconsax.notification, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Verification Banner
                  if (_storeId != null) _buildVerificationBanner(),
                  
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
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen())),
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFb71000),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // TODO: Create AnalyticsService to track and aggregate:
        // - Daily/weekly/monthly sales
        // - Order counts and trends
        // - Visitor tracking (page views, unique visitors)
        // - Conversion rates
        // - Product performance
        // - Customer insights
        // For now, showing basic order-based metrics
        StreamBuilder<List<StoreOrderData>>(
          stream: _orderService.getStoreOrdersStream(),
          builder: (context, snapshot) {
            final orders = snapshot.data ?? [];
            
            // Calculate today's metrics
            final today = DateTime.now();
            final todayOrders = orders.where((order) {
              return order.createdAt.year == today.year &&
                     order.createdAt.month == today.month &&
                     order.createdAt.day == today.day;
            }).toList();

            final todaySales = todayOrders.fold<double>(
              0, 
              (sum, order) => sum + order.total,
            );
            final todayOrderCount = todayOrders.length;

            // Calculate yesterday's metrics for comparison
            final yesterday = today.subtract(const Duration(days: 1));
            final yesterdayOrders = orders.where((order) {
              return order.createdAt.year == yesterday.year &&
                     order.createdAt.month == yesterday.month &&
                     order.createdAt.day == yesterday.day;
            }).toList();

            final yesterdaySales = yesterdayOrders.fold<double>(
              0, 
              (sum, order) => sum + order.total,
            );
            final yesterdayOrderCount = yesterdayOrders.length;

            // Calculate percentage changes
            final salesChange = yesterdaySales > 0 
                ? ((todaySales - yesterdaySales) / yesterdaySales * 100).toStringAsFixed(0)
                : (todaySales > 0 ? '+100' : '0');
            final ordersChange = yesterdayOrderCount > 0
                ? ((todayOrderCount - yesterdayOrderCount) / yesterdayOrderCount * 100).toStringAsFixed(0)
                : (todayOrderCount > 0 ? '+100' : '0');

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _AnalyticCard(title: 'Sales', value: _formatCompactNumber(todaySales), icon: Iconsax.trend_up, trend: '$salesChange%', delay: 0)),
                    const SizedBox(width: 12),
                    Expanded(child: _AnalyticCard(title: 'Orders', value: '$todayOrderCount', icon: Iconsax.shopping_bag, trend: '$ordersChange%', delay: 100)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Visitor tracking
                    _storeId == null
                        ? Expanded(child: _AnalyticCard(title: 'Visitors', value: '0', icon: Iconsax.eye, trend: '+0%', delay: 200))
                        : Expanded(
                            child: StreamBuilder<int>(
                              stream: _visitorService.getTodayVisitorCountStream(_storeId!),
                              builder: (context, snapshot) {
                                final visitorCount = snapshot.data ?? 0;
                                
                                // Calculate conversion rate
                                final conversionRate = visitorCount > 0
                                    ? ((todayOrderCount / visitorCount) * 100).toStringAsFixed(1)
                                    : '0.0';
                                
                                return Row(
                                  children: [
                                    Expanded(child: _AnalyticCard(title: 'Visitors', value: '$visitorCount', icon: Iconsax.eye, trend: '+0%', delay: 200)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _AnalyticCard(title: 'Conversion', value: '$conversionRate%', icon: Iconsax.chart_1, trend: '+0%', delay: 300)),
                                  ],
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ],
            );
          },
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
              child: Text(
                'See All',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFb71000),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<StoreOrderData>>(
          stream: _orderService.getStoreOrdersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Colors.black),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Error loading orders',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              );
            }

            final orders = snapshot.data ?? [];
            
            if (orders.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Icon(Iconsax.shopping_bag, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No orders yet',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Show only the first 3 orders
            final recentOrders = orders.take(3).toList();
            
            return Column(
              children: recentOrders.asMap().entries.map((entry) {
                final index = entry.key;
                final order = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: index < recentOrders.length - 1 ? 10 : 0),
                  child: _OrderCard(
                    orderId: order.orderNumber,
                    customer: order.userName,
                    amount: _currencyService.formatPrice(order.total),
                    status: order.statusDisplay,
                    time: order.timeAgo,
                    delay: index * 100,
                  ),
                );
              }).toList(),
            );
          },
        ),
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
            Expanded(child: _ActionButton(icon: Iconsax.truck_fast, label: 'New Delivery', onTap: () => MainScreen.navigateToTab(context, 3))),
            const SizedBox(width: 12),
            Expanded(child: _ActionButton(icon: Iconsax.ticket_discount, label: 'Discounts', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DiscountsScreen())))),
          ],
        ),
      ],
    );
  }

  Widget _buildVerificationBanner() {
    return FutureBuilder<VerificationStatus>(
      future: _verificationService.getVerificationStatus(_storeId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final status = snapshot.data!;
        
        // Don't show banner if verified and not expiring soon
        if (status == VerificationStatus.verified) {
          return FutureBuilder<bool>(
            future: _verificationService.isExpiringSoon(_storeId!),
            builder: (context, expiringSnapshot) {
              if (expiringSnapshot.data != true) return const SizedBox.shrink();
              
              // Show renewal reminder
              return FutureBuilder<int?>(
                future: _verificationService.getDaysUntilExpiry(_storeId!),
                builder: (context, daysSnapshot) {
                  final days = daysSnapshot.data ?? 0;
                  // TODO: Create separate renewal screen instead of reusing verification screen
                  // The renewal screen should:
                  // - Skip the form step (no owner name, location, ID document)
                  // - Go directly to payment step
                  // - Show "Renew Verification" title
                  // - Call renewVerification() instead of submitVerification()
                  return _buildBannerCard(
                    icon: Iconsax.refresh,
                    title: 'Verification Expiring Soon',
                    subtitle: 'Renew in $days days to keep your verified badge',
                    buttonText: 'Renew Now',
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StoreVerificationScreen(isRenewal: true),
                      ),
                    ),
                  );
                },
              );
            },
          );
        }
        
        // Show banner for non-verified stores
        if (status == VerificationStatus.none || status == VerificationStatus.expired) {
          if (!_showVerificationBanner) return const SizedBox.shrink();
          
          return _buildBannerCard(
            icon: Iconsax.verify,
            title: 'Get Verified',
            subtitle: 'Stand out with a verified badge • \$4.99/month',
            buttonText: 'Get Started',
            color: const Color(0xFFfb2a0a),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StoreVerificationScreen(),
              ),
            ),
            onDismiss: () async {
              setState(() => _showVerificationBanner = false);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hide_verification_banner', true);
            },
          );
        }
        
        // Don't show banner for pending status - they already submitted
        if (status == VerificationStatus.pending) {
          return const SizedBox.shrink();
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBannerCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String? buttonText,
    required Color color,
    required VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFfb2a0a),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (buttonText != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  buttonText,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, size: 20, color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ],
      ),
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
    // Determine if trend is positive, negative, or neutral
    final trendValue = widget.trend.replaceAll('%', '').replaceAll('+', '');
    final isPositive = widget.trend.startsWith('+') || (!widget.trend.startsWith('-') && trendValue != '0');
    final isNegative = widget.trend.startsWith('-') && trendValue != '0';
    
    final trendColor = isPositive 
        ? Colors.green 
        : isNegative 
            ? Colors.red 
            : Colors.grey[700]!;
    
    final trendBgColor = isPositive 
        ? Colors.green.withOpacity(0.1) 
        : isNegative 
            ? Colors.red.withOpacity(0.1) 
            : Colors.grey[200]!;
    
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
                  decoration: BoxDecoration(color: const Color(0xFFfb2a0a), borderRadius: BorderRadius.circular(10)),
                  child: Icon(widget.icon, color: Colors.white, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.trend,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: trendColor,
                    ),
                  ),
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
    // All statuses use black background with white text
    return Colors.black;
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
                decoration: BoxDecoration(color: const Color(0xFFfb2a0a), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Iconsax.shopping_bag, color: Colors.white, size: 22),
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
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.status,
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
        decoration: BoxDecoration(color: const Color(0xFFfb2a0a), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ActionButtonWithBadge extends StatefulWidget {
  final IconData icon;
  final String label;
  final String storeId;
  final VoidCallback onTap;

  const _ActionButtonWithBadge({
    required this.icon,
    required this.label,
    required this.storeId,
    required this.onTap,
  });

  @override
  State<_ActionButtonWithBadge> createState() => _ActionButtonWithBadgeState();
}

class _ActionButtonWithBadgeState extends State<_ActionButtonWithBadge> {
  final ProductQuestionsService _questionsService = ProductQuestionsService();
  int _unansweredCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnansweredCount();
  }

  Future<void> _loadUnansweredCount() async {
    try {
      final count = await _questionsService.getUnansweredCount(
        storeId: widget.storeId,
      );
      if (mounted) {
        setState(() => _unansweredCount = count);
      }
    } catch (e) {
      // Silently fail
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFfb2a0a),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(widget.icon, color: Colors.white, size: 26),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (_unansweredCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Center(
                  child: Text(
                    _unansweredCount > 99 ? '99+' : '$_unansweredCount',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFfb2a0a),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
