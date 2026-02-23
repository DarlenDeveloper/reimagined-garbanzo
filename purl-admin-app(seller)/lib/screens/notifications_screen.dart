import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  String _selectedFilter = 'This Week'; // Default filter

  DateTime _getFilterStartDate() {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'This Week':
        return now.subtract(const Duration(days: 7)); // Last 7 days
      case 'This Month':
        return DateTime(now.year, now.month, 1); // Start of month
      default:
        return now.subtract(const Duration(days: 7)); // Default to 7 days
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Filter Notifications',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...['Today', 'This Week', 'This Month'].map((filter) {
              final isSelected = _selectedFilter == filter;
              return ListTile(
                title: Text(
                  filter,
                  style: GoogleFonts.poppins(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? const Color(0xFFfb2a0a) : Colors.black,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Iconsax.tick_circle, color: Color(0xFFfb2a0a))
                    : null,
                onTap: () {
                  setState(() => _selectedFilter = filter);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'new_order':
        return Iconsax.shopping_bag;
      case 'low_stock':
        return Iconsax.warning_2;
      case 'message':
        return Iconsax.message;
      case 'payment':
        return Iconsax.wallet_check;
      case 'review':
        return Iconsax.star_1;
      default:
        return Iconsax.notification;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Notifications', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
        ),
        body: Center(
          child: Text('Please sign in', style: GoogleFonts.poppins()),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Iconsax.filter, color: Colors.black),
            onPressed: _showFilterSheet,
          ),
          StreamBuilder<int>(
            stream: _notificationService.getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount > 0) {
                return TextButton(
                  onPressed: () async {
                    await _notificationService.markAllAsRead();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('All marked as read', style: GoogleFonts.poppins()),
                          backgroundColor: const Color(0xFFfb2a0a),
                        ),
                      );
                    }
                  },
                  child: Text('Mark all read', style: GoogleFonts.poppins(color: const Color(0xFFfb2a0a), fontSize: 14)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _firestore
            .collection('stores')
            .where('authorizedUsers', arrayContains: userId)
            .limit(1)
            .get(),
        builder: (context, storeSnapshot) {
          if (storeSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFfb2a0a)));
          }

          if (!storeSnapshot.hasData || storeSnapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No store found', style: GoogleFonts.poppins()),
            );
          }

          final storeId = storeSnapshot.data!.docs.first.id;

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('stores')
                .doc(storeId)
                .collection('notifications')
                .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_getFilterStartDate()))
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFfb2a0a)));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading notifications', style: GoogleFonts.poppins()),
                );
              }

              final notifications = snapshot.data?.docs ?? [];

              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.notification, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final doc = notifications[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final isRead = data['isRead'] ?? false;
                  final type = data['type'] ?? 'general';
                  final title = data['title'] ?? 'Notification';
                  final body = data['body'] ?? '';
                  final createdAt = data['createdAt'] as Timestamp?;

                  return GestureDetector(
                    onTap: () async {
                      if (!isRead) {
                        await _firestore
                            .collection('stores')
                            .doc(storeId)
                            .collection('notifications')
                            .doc(doc.id)
                            .update({'isRead': true});
                      }
                      // TODO: Navigate based on type
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFfb2a0a),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_getIconForType(type), color: Colors.white, size: 20),
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
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (!isRead) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFfb2a0a),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  body,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(createdAt),
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
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
