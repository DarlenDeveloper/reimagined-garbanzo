import 'package:cloud_firestore/cloud_firestore.dart';

/// MessagesService manages conversations between stores and buyers.
/// 
/// FIRESTORE STRUCTURE:
/// /conversations/{conversationId}
/// ├── participants: array<string> [storeId, userId]
/// ├── storeId: string
/// ├── storeName: string
/// ├── storeLogoUrl: string
/// ├── userId: string
/// ├── userName: string
/// ├── userPhotoUrl: string
/// ├── lastMessage: string
/// ├── lastMessageTime: timestamp
/// ├── unreadCount: map<string, number> {storeId: count, userId: count}
/// ├── createdAt: timestamp
/// ├── updatedAt: timestamp
/// └── messages: subcollection
///     └── {messageId}
///         ├── senderId: string
///         ├── text: string
///         ├── createdAt: timestamp
///         ├── read: boolean
class MessagesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get or create conversation between store and user
  Future<String> getOrCreateConversation({
    required String storeId,
    required String storeName,
    String? storeLogoUrl,
    required String userId,
    required String userName,
    String? userPhotoUrl,
  }) async {
    // Create conversation ID from sorted participant IDs for consistency
    final participants = [storeId, userId]..sort();
    final conversationId = participants.join('_');

    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    final conversationDoc = await conversationRef.get();

    if (!conversationDoc.exists) {
      // Create new conversation
      await conversationRef.set({
        'participants': participants,
        'storeId': storeId,
        'storeName': storeName,
        'storeLogoUrl': storeLogoUrl ?? '',
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl ?? '',
        'lastMessage': '',
        'lastMessageTime': Timestamp.now(),
        'unreadCount': {
          storeId: 0,
          userId: 0,
        },
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    }

    return conversationId;
  }

  /// Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    final messagesRef = conversationRef.collection('messages');

    // Get conversation to determine receiver
    final conversationDoc = await conversationRef.get();
    final conversationData = conversationDoc.data();
    if (conversationData == null) return;

    final participants = List<String>.from(conversationData['participants'] ?? []);
    final receiverId = participants.firstWhere((id) => id != senderId, orElse: () => '');

    // Add message
    await messagesRef.add({
      'senderId': senderId,
      'text': text,
      'createdAt': Timestamp.now(),
      'read': false,
    });

    // Update conversation
    final currentUnreadCount = Map<String, dynamic>.from(conversationData['unreadCount'] ?? {});
    currentUnreadCount[receiverId] = (currentUnreadCount[receiverId] ?? 0) + 1;

    await conversationRef.update({
      'lastMessage': text,
      'lastMessageTime': Timestamp.now(),
      'unreadCount': currentUnreadCount,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Get conversations for a store
  Stream<List<Map<String, dynamic>>> getStoreConversations(String storeId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: storeId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Get messages for a conversation
  Stream<List<Map<String, dynamic>>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Mark messages as read
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final conversationRef = _firestore.collection('conversations').doc(conversationId);

      // Reset unread count immediately
      await conversationRef.update({
        'unreadCount.$userId': 0,
        'updatedAt': Timestamp.now(),
      });

      // Mark individual messages as read (optional, for future features)
      final messagesRef = conversationRef.collection('messages');
      final unreadMessages = await messagesRef
          .where('senderId', isNotEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in unreadMessages.docs) {
          batch.update(doc.reference, {'read': true});
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error marking messages as read: $e');
      // Don't throw - we don't want to block the UI if this fails
    }
  }

  /// Get total unread count for store
  Future<int> getTotalUnreadCount(String storeId) async {
    final conversations = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: storeId)
        .get();

    int totalUnread = 0;
    for (final doc in conversations.docs) {
      final data = doc.data();
      final unreadCount = Map<String, dynamic>.from(data['unreadCount'] ?? {});
      totalUnread += (unreadCount[storeId] ?? 0) as int;
    }

    return totalUnread;
  }

  /// Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    
    // Delete all messages
    final messages = await conversationRef.collection('messages').get();
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    
    // Delete conversation
    batch.delete(conversationRef);
    await batch.commit();
  }

  /// Format time ago
  String getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Format message time
  String getMessageTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  /// Update conversation userName
  Future<void> updateConversationUserName(String conversationId, String userName) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'userName': userName,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating conversation userName: $e');
    }
  }
}
