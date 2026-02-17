import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotificationItem(
            icon: Iconsax.box,
            iconColor: Colors.orange,
            title: 'New Delivery Request',
            message: 'Order #ORD-2026-123 from Fresh Mart',
            time: '2 mins ago',
            isUnread: true,
          ),
          _buildNotificationItem(
            icon: Iconsax.tick_circle,
            iconColor: Colors.green,
            title: 'Delivery Completed',
            message: 'You earned UGX 12,000 from order #ORD-2026-120',
            time: '1 hour ago',
            isUnread: true,
          ),
          _buildNotificationItem(
            icon: Iconsax.wallet_2,
            iconColor: Colors.blue,
            title: 'Payment Received',
            message: 'UGX 45,000 has been added to your wallet',
            time: '3 hours ago',
            isUnread: false,
          ),
          _buildNotificationItem(
            icon: Iconsax.star,
            iconColor: Colors.amber,
            title: 'New Rating',
            message: 'You received 5 stars from a customer',
            time: '5 hours ago',
            isUnread: false,
          ),
          _buildNotificationItem(
            icon: Iconsax.info_circle,
            iconColor: Colors.grey,
            title: 'System Update',
            message: 'New features available in the app',
            time: 'Yesterday',
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? Colors.orange.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUnread ? Border.all(color: Colors.orange.withOpacity(0.2)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
