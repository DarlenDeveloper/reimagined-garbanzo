import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'products_screen.dart';
import 'delivery_screen.dart';
import 'store_screen.dart';
import 'inventory_screen.dart';
import 'shipping_screen.dart';
import 'analytics_screen.dart';
import 'payments_screen.dart';
import 'socials_screen.dart';
import 'users_screen.dart';
import 'notifications_screen.dart';
import 'ai_customer_service_screen.dart';
import 'discounts_screen.dart';
import 'settings_screen.dart';
import 'messages_screen.dart';
import 'ads_screen.dart';
import 'store_verification_screen.dart';
import '../services/location_service.dart';
import '../widgets/location_update_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static void navigateToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainScreenState>();
    state?.setTab(index);
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _checkLocationUpdate();
  }

  Future<void> _checkLocationUpdate() async {
    // Wait a bit for the screen to settle
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final shouldUpdate = await _locationService.shouldUpdateLocation();
    if (shouldUpdate && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LocationUpdateDialog(),
      );
    }
  }

  void setTab(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const OrdersScreen(),
    const ProductsScreen(),
    const DeliveryScreen(),
    const StoreScreen(),
  ];

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87,
      builder: (context) => _MoreMenuSheet(
        onNavigateTab: (index) {
          Navigator.pop(context);
          setState(() => _currentIndex = index);
        },
        onNavigateScreen: (screen) {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Iconsax.home_2, activeIcon: Iconsax.home_25, label: 'Home', isSelected: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
                _NavItem(icon: Iconsax.receipt_2, activeIcon: Iconsax.receipt_25, label: 'Orders', isSelected: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1)),
                _NavItem(icon: Iconsax.box, activeIcon: Iconsax.box_1, label: 'Products', isSelected: _currentIndex == 2, onTap: () => setState(() => _currentIndex = 2)),
                _NavItem(icon: Iconsax.truck_fast, activeIcon: Iconsax.truck_fast, label: 'Delivery', isSelected: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3)),
                _NavItem(icon: Iconsax.menu_1, activeIcon: Iconsax.menu_1, label: 'More', isSelected: false, onTap: () => _showMoreMenu(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(isSelected ? activeIcon : icon, size: 24, color: isSelected ? Colors.black : Colors.grey[400]),
            ),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? Colors.black : Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}

class _MoreMenuSheet extends StatefulWidget {
  final Function(int) onNavigateTab;
  final Function(Widget) onNavigateScreen;

  const _MoreMenuSheet({required this.onNavigateTab, required this.onNavigateScreen});

  @override
  State<_MoreMenuSheet> createState() => _MoreMenuSheetState();
}

class _MoreMenuSheetState extends State<_MoreMenuSheet> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Set<String> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand(String label) {
    setState(() {
      if (_expandedItems.contains(label)) {
        _expandedItems.remove(label);
      } else {
        _expandedItems.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    _buildExpandableItem(icon: Iconsax.receipt_2, label: 'Orders', onTap: () => widget.onNavigateTab(1), children: [
                      _buildSubItem('All Orders', () => widget.onNavigateTab(1)),
                      _buildSubItem('Pending', () => widget.onNavigateTab(1)),
                      _buildSubItem('Shipped', () => widget.onNavigateTab(1)),
                    ]),
                    _buildExpandableItem(icon: Iconsax.box, label: 'Products', onTap: () => widget.onNavigateTab(2), children: [
                      _buildSubItem('All Products', () => widget.onNavigateTab(2)),
                      _buildSubItem('Add Product', () => widget.onNavigateTab(2)),
                      _buildSubItem('Categories', () => widget.onNavigateTab(2)),
                    ]),
                    _buildMenuItem(Iconsax.archive_2, 'Inventory', () => widget.onNavigateScreen(const InventoryScreen())),
                    _buildMenuItem(Iconsax.truck_fast, 'Deliveries', () => widget.onNavigateTab(3)),
                    _buildMenuItem(Iconsax.airplane, 'Shipping', () => widget.onNavigateScreen(const ShippingScreen())),
                    
                    const SizedBox(height: 16),
                    _buildSectionHeader('Business'),
                    
                    _buildMenuItem(Iconsax.chart_2, 'Analytics', () => widget.onNavigateScreen(const AnalyticsScreen())),
                    _buildMenuItem(Iconsax.wallet_2, 'Payments', () => widget.onNavigateScreen(const PaymentsScreen())),
                    _buildMenuItem(Iconsax.discount_shape, 'Discounts', () => widget.onNavigateScreen(DiscountsScreen())),
                    _buildMenuItem(Iconsax.chart_215, 'Ads', () => widget.onNavigateScreen(const AdsScreen())),
                    
                    const SizedBox(height: 16),
                    _buildSectionHeader('Social'),
                    
                    _buildMenuItem(Iconsax.gallery, 'Socials', () => widget.onNavigateScreen(const SocialsScreen())),
                    _buildMenuItem(Iconsax.message, 'Messages', () => widget.onNavigateScreen(const MessagesScreen())),
                    _buildMenuItem(Iconsax.cpu, 'Customer Service', () => widget.onNavigateScreen(const AICustomerServiceScreen())),
                    _buildMenuItem(Iconsax.notification, 'Notifications', () => widget.onNavigateScreen(const NotificationsScreen())),
                    
                    const SizedBox(height: 16),
                    _buildSectionHeader('Settings'),
                    
                    _buildMenuItem(Iconsax.verify, 'Verification', () => widget.onNavigateScreen(const StoreVerificationScreen())),
                    _buildMenuItem(Iconsax.people, 'Team', () => widget.onNavigateScreen(const UsersScreen())),
                    _buildMenuItem(Iconsax.shop, 'Store Profile', () => widget.onNavigateTab(4)),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(title, style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 22),
      title: Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
      trailing: Icon(Iconsax.arrow_right_3, color: Colors.grey[600], size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildExpandableItem({required IconData icon, required String label, required VoidCallback onTap, required List<Widget> children}) {
    final isExpanded = _expandedItems.contains(label);
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.white, size: 22),
          title: Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(6)),
                  child: Text('View', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _toggleExpand(label),
                child: Icon(isExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1, color: Colors.grey[500], size: 20),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        ),
        if (isExpanded) Padding(padding: const EdgeInsets.only(left: 48), child: Column(children: children)),
      ],
    );
  }

  Widget _buildSubItem(String label, VoidCallback onTap) {
    return ListTile(
      title: Text(label, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14)),
      trailing: Icon(Iconsax.arrow_right_3, color: Colors.grey[700], size: 16),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(24)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.setting_2, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Settings', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[800], shape: BoxShape.circle),
              child: const Icon(Iconsax.close_circle, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
