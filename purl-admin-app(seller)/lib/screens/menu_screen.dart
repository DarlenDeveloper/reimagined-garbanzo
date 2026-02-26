import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/product_questions_service.dart';
import 'product_questions_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const darkGreen = Color(0xFFfb2a0a); // POP main red
  final ProductQuestionsService _questionsService = ProductQuestionsService();
  int _unansweredCount = 0;
  bool _isLoadingCount = true;

  @override
  void initState() {
    super.initState();
    _loadUnansweredCount();
  }

  Future<void> _loadUnansweredCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final count = await _questionsService.getUnansweredCount(
        storeId: user.uid,
      );
      if (mounted) {
        setState(() {
          _unansweredCount = count;
          _isLoadingCount = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCount = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Menu',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _MenuSection(
                        title: 'Store Management',
                        items: [
                          _MenuItem(icon: Icons.inventory_2_outlined, label: 'Products'),
                          _MenuItem(icon: Icons.shopping_bag_outlined, label: 'Orders'),
                          _MenuItem(icon: Icons.people_outline, label: 'Customers'),
                          _MenuItem(icon: Icons.discount_outlined, label: 'Discounts'),
                          _MenuItem(
                            icon: Icons.question_answer_outlined,
                            label: 'Questions',
                            badge: _unansweredCount > 0 ? _unansweredCount : null,
                            onTap: () {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductQuestionsScreen(
                                      storeId: user.uid,
                                    ),
                                  ),
                                ).then((_) => _loadUnansweredCount());
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _MenuSection(
                        title: 'Sales Channels',
                        items: [
                          _MenuItem(icon: Icons.storefront_outlined, label: 'Online Store'),
                          _MenuItem(icon: Icons.point_of_sale_outlined, label: 'Point of Sale'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _MenuSection(
                        title: 'Analytics',
                        items: [
                          _MenuItem(icon: Icons.bar_chart_outlined, label: 'Reports'),
                          _MenuItem(icon: Icons.insights_outlined, label: 'Live View'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _MenuSection(
                        title: 'Settings',
                        items: [
                          _MenuItem(icon: Icons.verified_outlined, label: 'Verification', route: '/store-verification'),
                          _MenuItem(icon: Icons.settings_outlined, label: 'Store Settings'),
                          _MenuItem(icon: Icons.payment_outlined, label: 'Payments'),
                          _MenuItem(icon: Icons.local_shipping_outlined, label: 'Shipping'),
                          _MenuItem(icon: Icons.notifications_outlined, label: 'Notifications'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    Divider(height: 1, color: Colors.grey[200]),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? route;
  final int? badge;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.route,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFfb2a0a), size: 22),
      title: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (badge != null && badge! > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFfb2a0a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$badge',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (route != null) {
          Navigator.pushNamed(context, route!);
        }
      },
    );
  }
}
