import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'cart_screen.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static void navigateToCart(BuildContext context) {
    final state = context.findAncestorStateOfType<_MainScreenState>();
    if (state != null) {
      state.setState(() => state._currentIndex = 2);
    }
  }

  static void navigateToOrders(BuildContext context) {
    final state = context.findAncestorStateOfType<_MainScreenState>();
    if (state != null) {
      state.setState(() => state._currentIndex = 3);
    }
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          DiscoverScreen(),
          CartScreen(),
          MyOrdersScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavItem(icon: Iconsax.home_2, activeIcon: Iconsax.home_25, label: 'Home', isActive: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
            _NavItem(icon: Iconsax.discover_1, activeIcon: Iconsax.discover, label: 'Discover', isActive: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1)),
            _NavItem(icon: Iconsax.shopping_bag, activeIcon: Iconsax.shopping_bag, label: 'Cart', isActive: _currentIndex == 2, onTap: () => setState(() => _currentIndex = 2)),
            _NavItem(icon: Iconsax.truck_fast, activeIcon: Iconsax.truck_fast, label: 'Deliveries', isActive: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3)),
            _NavItem(icon: Iconsax.profile_circle, activeIcon: Iconsax.profile_circle, label: 'Profile', isActive: _currentIndex == 4, onTap: () => setState(() => _currentIndex = 4)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.darkGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, size: 22, color: isActive ? Colors.white : Colors.grey[400]),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ],
        ),
      ),
    );
  }
}
