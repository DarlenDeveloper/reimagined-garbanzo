import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _orderUpdates = true;
  bool _promotions = false;
  bool _newArrivals = true;
  bool _priceDrops = true;
  bool _messages = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBeige,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Notifications', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('General', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            _buildToggleCard('Push Notifications', 'Receive push notifications', _pushEnabled, (v) => setState(() => _pushEnabled = v)),
            _buildToggleCard('Email Notifications', 'Receive email updates', _emailEnabled, (v) => setState(() => _emailEnabled = v)),
            const SizedBox(height: 24),
            Text('Shopping', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            _buildToggleCard('Order Updates', 'Shipping and delivery alerts', _orderUpdates, (v) => setState(() => _orderUpdates = v)),
            _buildToggleCard('Promotions', 'Sales and special offers', _promotions, (v) => setState(() => _promotions = v)),
            _buildToggleCard('New Arrivals', 'New products from followed stores', _newArrivals, (v) => setState(() => _newArrivals = v)),
            _buildToggleCard('Price Drops', 'Wishlist item price changes', _priceDrops, (v) => setState(() => _priceDrops = v)),
            const SizedBox(height: 24),
            Text('Social', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            _buildToggleCard('Messages', 'New messages from sellers', _messages, (v) => setState(() => _messages = v)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.darkGreen,
            activeTrackColor: AppColors.darkGreen.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
