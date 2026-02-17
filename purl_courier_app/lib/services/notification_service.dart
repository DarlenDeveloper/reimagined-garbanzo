import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get courier's notifications stream
  Stream<List<CourierNotification>> getNotificationsStream() {
    final courierId = _auth.currentUser?.uid;
    if (courierId == null) return Stream.value([]);

    return _firestore
        .collection('couriers')
        .doc(courierId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CourierNotification.fromFirestore(doc))
            .toList());
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final courierId = _auth.currentUser?.uid;
    if (courierId == null) return;

    await _firestore
        .collection('couriers')
        .doc(courierId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final courierId = _auth.currentUser?.uid;
    if (courierId == null) return;

    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('couriers')
        .doc(courierId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }


    await batch.commit();
  }

  /// Get unread notification count
  Stream<int> getUnreadCountStream() {
    final courierId = _auth.currentUser?.uid;
    if (courierId == null) return Stream.value(0);

    return _firestore
        .collection('couriers')
        .doc(courierId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

/// Courier Notification Model
class CourierNotification {
  final String id;
  final String type; // 'delivery_request', 'delivery_completed', 'payment', 'rating', 'system'
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  CourierNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  factory CourierNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourierNotification(
      id: doc.id,
      type: data['type'] ?? 'system',
      title: data['title'] ?? '',
      message: data['message'] ?? data['body'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      data: data['data'] as Map<String, dynamic>?,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min${diff.inMinutes > 1 ? 's' : ''} ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
