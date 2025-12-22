import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'bnpl_plans_screen.dart';
import 'bnpl_subscription_screen.dart';
import 'wishlist_screen.dart';
import 'addresses_screen.dart';
import 'payment_methods_screen.dart';
import 'order_history_screen.dart';
import 'help_support_screen.dart';
import 'receipts_screen.dart';
import 'notifications_settings_screen.dart';
import 'privacy_security_screen.dart';
import 'language_screen.dart';
import 'about_screen.dart';
import 'interests_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final bool _hasBnplAccount = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildProfileCard(),
              const SizedBox(height: 20),
              _hasBnplAccount ? _buildBnplBalanceCard() : _buildBnplApplyCard(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildMenuSection(),
              const SizedBox(height: 24),
              _buildSettingsSection(),
              const SizedBox(height: 24),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text('Profile', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiptsScreen())),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: const Icon(Iconsax.receipt_2, size: 20, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Container(
              width: 70, height: 70,
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              child: Center(child: Text('JD', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('John Doe', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                  const SizedBox(height: 2),
                  Text('john.doe@email.com', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.medal_star, size: 14, color: Colors.black),
                        const SizedBox(width: 4),
                        Text('Gold Member', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
              child: const Icon(Iconsax.edit_2, size: 18, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBnplBalanceCard() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BnplPlansScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('My Plans', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Text('Active', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Total to pay', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
            const SizedBox(height: 4),
            Text('\$678.33', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildBnplStat('On progress', '\$399.67'),
                const SizedBox(width: 24),
                _buildBnplStat('Overdue', '\$278.66'),
                const SizedBox(width: 24),
                _buildBnplStat('Total Items', '4 Item'),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        Text('15', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('Apr', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('iPhone 13 features...', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('5 of 6 installment', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$620.00', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text('On Progress', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Tap to view all plans', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white60)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BnplSubscriptionScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    child: Text('Upgrade', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBnplStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }

  Widget _buildBnplApplyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Iconsax.calendar_tick, size: 32, color: Colors.black),
          ),
          const SizedBox(height: 16),
          Text('Buy Now Pay Later', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Split your purchases into easy payments.\n0% interest, instant approval.', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70, height: 1.5)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BnplSubscriptionScreen())),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text('View Plans', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildQuickAction(Iconsax.heart, 'Wishlist', '12', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()))),
        const SizedBox(width: 12),
        _buildQuickAction(Iconsax.gift, 'Rewards', '850', () {}),
        const SizedBox(width: 12),
        _buildQuickAction(Iconsax.ticket_discount, 'Coupons', '5', () {}),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, String value, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Icon(icon, size: 24, color: Colors.black),
              const SizedBox(height: 8),
              Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
              Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My Account', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _buildMenuItem(Iconsax.location, 'My Addresses', 'Manage delivery addresses', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesScreen()))),
              _buildMenuDivider(),
              _buildMenuItem(Iconsax.card, 'Payment Methods', 'Cards, wallets & more', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()))),
              _buildMenuDivider(),
              _buildMenuItem(Iconsax.receipt_2, 'Order History', 'View past orders', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()))),
              _buildMenuDivider(),
              _buildMenuItem(Iconsax.message_question, 'Help & Support', 'Get help with orders', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _buildMenuItem(Iconsax.notification, 'Notifications', 'Manage alerts', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsSettingsScreen()))),
              _buildMenuDivider(),
              _buildMenuItem(Iconsax.magic_star, 'My Interests', 'Personalize your feed', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InterestsScreen(isOnboarding: false)))),
              _buildMenuDivider(),
              _buildMenuItem(Iconsax.lock, 'Privacy & Security', 'Password, 2FA', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()))),
              _buildMenuDivider(),
              _buildMenuItem(Iconsax.language_square, 'Language', 'English', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen()))),
              _buildMenuDivider(),
              _buildMenuItem(Iconsax.info_circle, 'About', 'App version 1.0.0', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: Colors.black),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 18, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: Colors.grey[200]);
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.logout, size: 20, color: Colors.black),
            const SizedBox(width: 10),
            Text('Log Out', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        content: Text('Are you sure you want to log out?', style: GoogleFonts.poppins(color: Colors.grey[600])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600]))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              GoRouter.of(context).go('/login');
            },
            child: Text('Log Out', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
