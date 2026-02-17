import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:math' as math;
import '../services/analytics_service.dart';
import '../services/currency_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Week';
  final AnalyticsService _analyticsService = AnalyticsService();
  final CurrencyService _currencyService = CurrencyService();
  
  final List<double> _salesData = [2400, 1800, 3200, 2800, 4100, 3600, 4800];
  final List<double> _ordersData = [18, 14, 24, 21, 32, 28, 38];
  final List<double> _visitorsData = [320, 280, 410, 380, 520, 460, 580];
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text('Analytics', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
        actions: [
          GestureDetector(
            onTap: () => _showPeriodPicker(),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Text(_selectedPeriod, style: GoogleFonts.poppins(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  const Icon(Iconsax.arrow_down_1, color: Colors.black, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
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
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12),
              padding: const EdgeInsets.all(4),
              tabs: const [Tab(text: 'Overview'), Tab(text: 'Sales'), Tab(text: 'Products'), Tab(text: 'Traffic'), Tab(text: 'Support')],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildOverviewTab(), _buildSalesTab(), _buildProductsTab(), _buildTrafficTab(), _buildSupportTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        _analyticsService.getOverviewMetrics(_selectedPeriod),
        _analyticsService.getDailyRevenue(_selectedPeriod),
        _analyticsService.getRecentActivity(),
        _analyticsService.getQuickStats(_selectedPeriod),
      ]).then((results) => {
        'metrics': results[0],
        'dailyRevenue': results[1],
        'recentActivity': results[2],
        'quickStats': results[3],
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading analytics',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final metrics = data['metrics'] as Map<String, dynamic>? ?? {};
        final dailyRevenue = data['dailyRevenue'] as List<double>? ?? List.filled(7, 0.0);
        final recentActivity = data['recentActivity'] as List<Map<String, dynamic>>? ?? [];
        final quickStats = data['quickStats'] as Map<String, dynamic>? ?? {};

        final revenue = metrics['revenue'] ?? 0.0;
        final orders = metrics['orders'] ?? 0;
        final visitors = metrics['visitors'] ?? 0;
        final conversion = metrics['conversion'] ?? 0.0;
        final revenueChange = metrics['revenueChange'] ?? 0.0;
        final ordersChange = metrics['ordersChange'] ?? 0.0;

        final avgOrder = quickStats['avgOrder'] ?? 0.0;
        final itemsPerOrder = quickStats['itemsPerOrder'] ?? 0.0;
        final returnRate = quickStats['returnRate'] ?? 0.0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Key Metrics
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Revenue',
                    value: _currencyService.formatPrice(revenue),
                    change: '${revenueChange >= 0 ? '+' : ''}${revenueChange.toStringAsFixed(1)}%',
                    isPositive: revenueChange >= 0,
                    icon: Iconsax.money_recive,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Orders',
                    value: '$orders',
                    change: '${ordersChange >= 0 ? '+' : ''}${ordersChange.toStringAsFixed(1)}%',
                    isPositive: ordersChange >= 0,
                    icon: Iconsax.shopping_bag,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Visitors',
                    value: '$visitors',
                    change: '+8.3%',
                    isPositive: true,
                    icon: Iconsax.people,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Conversion',
                    value: '${conversion.toStringAsFixed(1)}%',
                    change: '-0.4%',
                    isPositive: false,
                    icon: Iconsax.chart_2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Revenue Chart
            _sectionHeader('Revenue Trend', Iconsax.trend_up),
            const SizedBox(height: 16),
            _LineChart(data: dailyRevenue, labels: _weekDays, color: Colors.black, prefix: '\$ '),
            const SizedBox(height: 24),
            // Quick Stats
            _sectionHeader('Quick Stats', Iconsax.flash_1),
            const SizedBox(height: 16),
            Row(
              children: [
                _QuickStat(
                  label: 'Avg Order',
                  value: _currencyService.formatPrice(avgOrder),
                  icon: Iconsax.receipt_item,
                ),
                const SizedBox(width: 12),
                _QuickStat(
                  label: 'Items/Order',
                  value: itemsPerOrder.toStringAsFixed(1),
                  icon: Iconsax.box,
                ),
                const SizedBox(width: 12),
                _QuickStat(
                  label: 'Return Rate',
                  value: '${returnRate.toStringAsFixed(1)}%',
                  icon: Iconsax.refresh,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Recent Activity
            _sectionHeader('Recent Activity', Iconsax.activity),
            const SizedBox(height: 12),
            if (recentActivity.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'No recent activity',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ...recentActivity.map((activity) => _ActivityItem(
                title: 'New order ${activity['orderNumber']}',
                subtitle: '${_currencyService.formatPrice(activity['total'])} • ${activity['itemCount']} item${activity['itemCount'] > 1 ? 's' : ''}',
                time: activity['timeAgo'],
                icon: Iconsax.shopping_bag,
                color: Colors.green,
              )),
          ],
        );
      },
    );
  }

  Widget _buildSalesTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        _analyticsService.getOverviewMetrics(_selectedPeriod),
        _analyticsService.getDailySales(_selectedPeriod),
        _analyticsService.getSalesBreakdown(_selectedPeriod),
        _analyticsService.getPaymentMethods(_selectedPeriod),
      ]).then((results) => {
        'metrics': results[0],
        'dailySales': results[1],
        'breakdown': results[2],
        'paymentMethods': results[3],
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading sales data',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final metrics = data['metrics'] as Map<String, dynamic>? ?? {};
        final dailySales = data['dailySales'] as List<double>? ?? List.filled(7, 0.0);
        final breakdown = data['breakdown'] as Map<String, dynamic>? ?? {};
        final paymentMethods = data['paymentMethods'] as Map<String, int>? ?? {};

        final revenue = metrics['revenue'] ?? 0.0;
        final revenueChange = metrics['revenueChange'] ?? 0.0;
        final prevRevenue = revenue / (1 + revenueChange / 100);

        final productSales = breakdown['productSales'] ?? 0.0;
        final shippingFees = breakdown['shippingFees'] ?? 0.0;
        final tips = breakdown['tips'] ?? 0.0;
        final total = breakdown['total'] ?? revenue;

        final mobileMoney = paymentMethods['mobileMoney'] ?? 0;
        final card = paymentMethods['card'] ?? 0;
        final cash = paymentMethods['cash'] ?? 0;
        final totalPayments = mobileMoney + card + cash;

        final mobileMoneyPercent = totalPayments > 0 ? ((mobileMoney / totalPayments) * 100).round() : 0;
        final cardPercent = totalPayments > 0 ? ((card / totalPayments) * 100).round() : 0;
        final cashPercent = totalPayments > 0 ? ((cash / totalPayments) * 100).round() : 0;

        final productSalesPercent = total > 0 ? ((productSales / total) * 100).round() : 0;
        final shippingPercent = total > 0 ? ((shippingFees / total) * 100).round() : 0;
        final tipsPercent = total > 0 ? ((tips / total) * 100).round() : 0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sales Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Sales', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_currencyService.formatPrice(revenue), style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: revenueChange >= 0 ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              revenueChange >= 0 ? Iconsax.trend_up : Iconsax.trend_down,
                              color: revenueChange >= 0 ? Colors.green : Colors.red,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${revenueChange >= 0 ? '+' : ''}${revenueChange.toStringAsFixed(1)}%',
                              style: GoogleFonts.poppins(
                                color: revenueChange >= 0 ? Colors.green : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'vs ${_currencyService.formatPrice(prevRevenue)} last period',
                    style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Sales Chart
            _sectionHeader('Daily Sales', Iconsax.chart_21),
            const SizedBox(height: 16),
            _BarChart(data: dailySales, labels: _weekDays, color: Colors.black),
            const SizedBox(height: 24),
            // Sales Breakdown
            _sectionHeader('Sales Breakdown', Iconsax.chart_1),
            const SizedBox(height: 16),
            _BreakdownItem(
              label: 'Product Sales',
              value: _currencyService.formatPrice(productSales),
              percentage: productSalesPercent,
              color: Colors.black,
            ),
            _BreakdownItem(
              label: 'Shipping Fees',
              value: _currencyService.formatPrice(shippingFees),
              percentage: shippingPercent,
              color: Colors.grey,
            ),
            _BreakdownItem(
              label: 'Tips',
              value: _currencyService.formatPrice(tips),
              percentage: tipsPercent,
              color: Colors.grey[400]!,
            ),
            const SizedBox(height: 24),
            // Payment Methods
            _sectionHeader('Payment Methods', Iconsax.card),
            const SizedBox(height: 16),
            Row(
              children: [
                _PaymentMethod(method: 'Mobile Money', percentage: mobileMoneyPercent, icon: Iconsax.mobile),
                const SizedBox(width: 12),
                _PaymentMethod(method: 'Card', percentage: cardPercent, icon: Iconsax.card),
                const SizedBox(width: 12),
                _PaymentMethod(method: 'Cash', percentage: cashPercent, icon: Iconsax.money),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        _analyticsService.getProductStats(),
        _analyticsService.getTopSellingProducts(_selectedPeriod),
        _analyticsService.getCategoryPerformance(_selectedPeriod),
      ]).then((results) => {
        'stats': results[0],
        'topProducts': results[1],
        'categories': results[2],
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading products data',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final stats = data['stats'] as Map<String, int>? ?? {};
        final topProducts = data['topProducts'] as List<Map<String, dynamic>>? ?? [];
        final categories = data['categories'] as List<Map<String, dynamic>>? ?? [];

        final totalProducts = stats['total'] ?? 0;
        final activeProducts = stats['active'] ?? 0;
        final lowStockProducts = stats['lowStock'] ?? 0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Product Stats
            Row(
              children: [
                Expanded(child: _SmallMetric(label: 'Total Products', value: '$totalProducts')),
                const SizedBox(width: 12),
                Expanded(child: _SmallMetric(label: 'Active', value: '$activeProducts')),
                const SizedBox(width: 12),
                Expanded(child: _SmallMetric(label: 'Low Stock', value: '$lowStockProducts')),
              ],
            ),
            const SizedBox(height: 24),
            // Top Selling Products
            _sectionHeader('Top Selling', Iconsax.crown),
            const SizedBox(height: 16),
            if (topProducts.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'No sales data available',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ...topProducts.asMap().entries.map((entry) {
                final index = entry.key;
                final product = entry.value;
                return _TopProduct(
                  rank: index + 1,
                  name: product['name'],
                  sales: product['sales'],
                  revenue: _currencyService.formatPrice(product['revenue']),
                  growth: product['growth'],
                );
              }),
            const SizedBox(height: 24),
            // Category Performance
            _sectionHeader('Category Performance', Iconsax.category),
            const SizedBox(height: 16),
            if (categories.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'No category data available',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ...categories.map((category) => _CategoryPerformance(
                category: category['category'],
                sales: _currencyService.formatPrice(category['sales']),
                orders: category['orders'],
                percentage: category['percentage'],
              )),
          ],
        );
      },
    );
  }

  Widget _buildTrafficTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.chart_2, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Traffic Analytics',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Traffic analytics coming soon',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.headphone, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Support Analytics',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Support analytics coming soon',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }

  void _showPeriodPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Period', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...['Today', 'Yesterday', 'This Week', 'Last Week', 'This Month', 'Last Month', 'This Year'].map((period) => ListTile(
              title: Text(period, style: GoogleFonts.poppins(fontWeight: _selectedPeriod == period ? FontWeight.w600 : FontWeight.w400)),
              trailing: _selectedPeriod == period ? const Icon(Iconsax.tick_circle, color: Colors.black) : null,
              onTap: () {
                setState(() => _selectedPeriod = period);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}


// Custom Line Chart Widget
class _LineChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color color;
  final String prefix;

  const _LineChart({required this.data, required this.labels, required this.color, required this.prefix});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.reduce(math.max);
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: _LineChartPainter(data: data, color: color, maxValue: maxValue),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.map((l) => Text(l, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]))).toList(),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double maxValue;

  _LineChartPainter({required this.data, required this.color, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withAlpha(25)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxValue * size.height * 0.9);
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Bar Chart Widget
class _BarChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color color;

  const _BarChart({required this.data, required this.labels, required this.color});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.reduce(math.max);
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (i) {
                final height = (data[i] / maxValue) * 120;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${(data[i] / 1000).toStringAsFixed(1)}K', style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Container(
                          height: height,
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: labels.map((l) => Text(l, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]))).toList(),
          ),
        ],
      ),
    );
  }
}

// Metric Card
class _MetricCard extends StatelessWidget {
  final String title, value, change;
  final bool isPositive;
  final IconData icon;

  const _MetricCard({required this.title, required this.value, required this.change, required this.isPositive, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: isPositive ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25), borderRadius: BorderRadius.circular(4)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isPositive ? Iconsax.trend_up : Iconsax.trend_down, size: 12, color: isPositive ? Colors.green : Colors.red),
                    const SizedBox(width: 2),
                    Text(change, style: GoogleFonts.poppins(fontSize: 10, color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
          Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

// Quick Stat
class _QuickStat extends StatelessWidget {
  final String label, value;
  final IconData icon;

  const _QuickStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

// Activity Item
class _ActivityItem extends StatelessWidget {
  final String title, subtitle, time;
  final IconData icon;
  final Color color;

  const _ActivityItem({required this.title, required this.subtitle, required this.time, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          Text(time, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

// Breakdown Item
class _BreakdownItem extends StatelessWidget {
  final String label, value;
  final int percentage;
  final Color color;

  const _BreakdownItem({required this.label, required this.value, required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: percentage / 100, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation(color), minHeight: 8),
          ),
        ],
      ),
    );
  }
}

// Payment Method
class _PaymentMethod extends StatelessWidget {
  final String method;
  final int percentage;
  final IconData icon;

  const _PaymentMethod({required this.method, required this.percentage, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Colors.black),
            const SizedBox(height: 8),
            Text('$percentage%', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(method, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

// Small Metric
class _SmallMetric extends StatelessWidget {
  final String label, value;

  const _SmallMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

// Top Product
class _TopProduct extends StatelessWidget {
  final int rank, sales, growth;
  final String name, revenue;

  const _TopProduct({required this.rank, required this.name, required this.sales, required this.revenue, required this.growth});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: rank <= 3 ? Colors.black : Colors.grey[300], borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('#$rank', style: GoogleFonts.poppins(color: rank <= 3 ? Colors.white : Colors.black, fontWeight: FontWeight.w700, fontSize: 12))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Text('$sales sold', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(revenue, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Icon(growth >= 0 ? Iconsax.trend_up : Iconsax.trend_down, size: 12, color: growth >= 0 ? Colors.green : Colors.red),
                  Text('${growth >= 0 ? '+' : ''}$growth%', style: GoogleFonts.poppins(fontSize: 11, color: growth >= 0 ? Colors.green : Colors.red)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Category Performance
class _CategoryPerformance extends StatelessWidget {
  final String category, sales;
  final int orders, percentage;

  const _CategoryPerformance({required this.category, required this.sales, required this.orders, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation(Colors.black),
                    strokeWidth: 5,
                  ),
                ),
                Text('$percentage%', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Text('$orders orders', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Text(sales, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// Traffic Source
class _TrafficSource extends StatelessWidget {
  final String source;
  final int visits, percentage;
  final IconData icon;

  const _TrafficSource({required this.source, required this.visits, required this.percentage, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(source, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(value: percentage / 100, backgroundColor: Colors.grey[300], valueColor: const AlwaysStoppedAnimation(Colors.black), minHeight: 4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$visits', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              Text('$percentage%', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}

// Device Stat
class _DeviceStat extends StatelessWidget {
  final String device;
  final int percentage;
  final IconData icon;

  const _DeviceStat({required this.device, required this.percentage, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 8),
            Text('$percentage%', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
            Text(device, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

// Top Page
class _TopPage extends StatelessWidget {
  final String page;
  final int views, bounceRate;

  const _TopPage({required this.page, required this.views, required this.bounceRate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Iconsax.document, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(page, style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$views views', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('$bounceRate% bounce', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}


// Support Issue
class _SupportIssue extends StatelessWidget {
  final String issue;
  final int count, percentage;

  const _SupportIssue({required this.issue, required this.count, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Iconsax.message_question, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(value: percentage / 100, backgroundColor: Colors.grey[300], valueColor: const AlwaysStoppedAnimation(Colors.black), minHeight: 4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$count', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              Text('$percentage%', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}

// Rating Bar
class _RatingBar extends StatelessWidget {
  final int stars, count, total;

  const _RatingBar({required this.stars, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final percentage = (count / total * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 20, child: Text('$stars', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]))),
          const Icon(Iconsax.star1, size: 14, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: count / total, backgroundColor: Colors.grey[300], valueColor: const AlwaysStoppedAnimation(Colors.black), minHeight: 6),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 40, child: Text('$percentage%', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
