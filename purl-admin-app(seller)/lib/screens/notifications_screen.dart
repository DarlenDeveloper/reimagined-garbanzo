import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {'title': 'New Order', 'message': 'You have a new order #GC-1234', 'time': '2 min ago', 'isRead': false, 'icon': Iconsax.shopping_bag},
    {'title': 'Low Stock', 'message': 'Phone Case is running low (5 left)', 'time': '1 hour ago', 'isRead': false, 'icon': Iconsax.warning_2},
    {'title': 'Payment Received', 'message': '\$320.00 received for order #GC-1233', 'time': '3 hours ago', 'isRead': true, 'icon': Iconsax.wallet_check},
    {'title': 'Review', 'message': 'New 5-star review on Wireless Earbuds', 'time': 'Yesterday', 'isRead': true, 'icon': Iconsax.star_1},
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('All marked as read', style: GoogleFonts.poppins()), backgroundColor: Colors.black));
  }

  void _markAsRead(int index) {
    setState(() {
      _notifications[index]['isRead'] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['isRead']).length;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text('Notifications', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
        actions: [
          if (unreadCount > 0)
            TextButton(onPressed: _markAllAsRead, child: Text('Mark all read', style: GoogleFonts.poppins(color: Colors.black))),
        ],
      ),
      body: Column(
        children: [
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.withAlpha(25), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Iconsax.notification, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Text('$unreadCount unread notifications', style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final n = _notifications[index];
                return GestureDetector(
                  onTap: () => _markAsRead(index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: n['isRead'] ? Colors.grey[100] : Colors.blue.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: n['isRead'] ? null : Border.all(color: Colors.blue.withAlpha(50)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                          child: Icon(n['icon'], color: Colors.black, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(n['title'], style: GoogleFonts.poppins(fontWeight: n['isRead'] ? FontWeight.w500 : FontWeight.w700)),
                                  if (!n['isRead']) ...[
                                    const SizedBox(width: 8),
                                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(n['message'], style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                              const SizedBox(height: 4),
                              Text(n['time'], style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
