import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_NotificationItem> _notifications = [
    _NotificationItem(id: '1', type: NotificationType.order, title: 'Order Shipped!', message: 'Your order #GC2847 has been shipped and is on its way.', time: '2 min ago', isRead: false, section: 'Today'),
    _NotificationItem(id: '2', type: NotificationType.promo, title: 'Flash Sale Alert!', message: 'Glow Electronics: 20% off all headphones. Use code GLOW20', time: '1 hour ago', isRead: false, section: 'Today', vendorName: 'Glow Electronics'),
    _NotificationItem(id: '3', type: NotificationType.follow, title: 'New Follower', message: 'Urban Style Co started following you', time: '3 hours ago', isRead: false, section: 'Today', vendorName: 'Urban Style Co'),
    _NotificationItem(id: '4', type: NotificationType.delivery, title: 'Out for Delivery', message: 'Your order #GC2831 is out for delivery. Expected by 5 PM.', time: 'Yesterday', isRead: true, section: 'Yesterday'),
    _NotificationItem(id: '5', type: NotificationType.like, title: 'Post Liked', message: 'nikizefanya and 24 others liked your saved post', time: 'Yesterday', isRead: true, section: 'Yesterday'),
    _NotificationItem(id: '6', type: NotificationType.restock, title: 'Back in Stock!', message: 'Smart Watch Ultra is back in stock at Glow Electronics', time: 'Yesterday', isRead: true, section: 'Yesterday', vendorName: 'Glow Electronics'),
    _NotificationItem(id: '7', type: NotificationType.order, title: 'Order Delivered', message: 'Your order #GC2815 has been delivered successfully.', time: 'Monday', isRead: true, section: 'This Week'),
    _NotificationItem(id: '8', type: NotificationType.promo, title: 'Weekend Special', message: 'Home Essentials: 30% off all blankets and cushions', time: 'Sunday', isRead: true, section: 'This Week', vendorName: 'Home Essentials'),
    _NotificationItem(id: '9', type: NotificationType.message, title: 'New Message', message: 'vernadare sent you a message', time: 'Saturday', isRead: true, section: 'This Week'),
  ];

  @override
  Widget build(BuildContext context) {
    final groupedNotifications = _groupNotifications();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text('Notifications', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
        actions: [
          TextButton(onPressed: _markAllAsRead, child: Text('Mark all read', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black))),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: groupedNotifications.length,
        itemBuilder: (context, index) {
          final section = groupedNotifications.keys.elementAt(index);
          final items = groupedNotifications[section]!;
          return _buildSection(section, items);
        },
      ),
    );
  }

  Map<String, List<_NotificationItem>> _groupNotifications() {
    final Map<String, List<_NotificationItem>> grouped = {};
    for (final notification in _notifications) {
      if (!grouped.containsKey(notification.section)) {
        grouped[notification.section] = [];
      }
      grouped[notification.section]!.add(notification);
    }
    return grouped;
  }

  Widget _buildSection(String title, List<_NotificationItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600])),
        ),
        ...items.map((item) => _buildNotificationTile(item)),
      ],
    );
  }

  Widget _buildNotificationTile(_NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.grey[300],
        child: const Icon(Iconsax.trash, color: Colors.black),
      ),
      onDismissed: (direction) => setState(() => _notifications.removeWhere((n) => n.id == notification.id)),
      child: GestureDetector(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.grey[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(14)),
                child: Icon(_getNotificationIcon(notification.type), color: Colors.black, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(notification.title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600, color: Colors.black))),
                        if (!notification.isRead)
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notification.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600], height: 1.4)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(notification.time, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                        if (notification.vendorName != null) ...[
                          const SizedBox(width: 8),
                          Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey[500], shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(notification.vendorName!, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.order: return Iconsax.box;
      case NotificationType.delivery: return Iconsax.truck_fast;
      case NotificationType.promo: return Iconsax.discount_shape;
      case NotificationType.follow: return Iconsax.profile_add;
      case NotificationType.like: return Iconsax.heart;
      case NotificationType.restock: return Iconsax.refresh;
      case NotificationType.message: return Iconsax.message;
    }
  }

  void _handleNotificationTap(_NotificationItem notification) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = _NotificationItem(id: notification.id, type: notification.type, title: notification.title, message: notification.message, time: notification.time, isRead: true, section: notification.section, vendorName: notification.vendorName);
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        final n = _notifications[i];
        _notifications[i] = _NotificationItem(id: n.id, type: n.type, title: n.title, message: n.message, time: n.time, isRead: true, section: n.section, vendorName: n.vendorName);
      }
    });
  }
}

enum NotificationType { order, delivery, promo, follow, like, restock, message }

class _NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final String section;
  final String? vendorName;

  _NotificationItem({required this.id, required this.type, required this.title, required this.message, required this.time, required this.isRead, required this.section, this.vendorName});
}
