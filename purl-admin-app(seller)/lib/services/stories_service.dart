import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// StoriesService handles store stories (24-hour temporary content)
/// Stories are separate from posts and expire automatically
class StoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new story
  Future<String> createStory({
    required String storeId,
    required String mediaUrl,
    required String mediaType, // 'image' or 'video'
    String? thumbnailUrl,
    int? duration, // for videos
  }) async {
    final now = Timestamp.now();
    
    final storyRef = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('stories')
        .add({
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'thumbnailUrl': thumbnailUrl ?? mediaUrl,
      'duration': duration,
      'views': 0,
      'viewedBy': [], // Track unique viewers
      'createdAt': now, // Use client timestamp for immediate availability
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 24)),
      ),
    });

    return storyRef.id;
  }

  /// Get all active stories for a store (not expired)
  Future<List<Map<String, dynamic>>> getActiveStories(String storeId) async {
    final now = Timestamp.now();
    
    final snapshot = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('stories')
        .orderBy('createdAt', descending: true)
        .get();

    // Filter out expired stories client-side
    return snapshot.docs
        .where((doc) {
          final expiresAt = doc.data()['expiresAt'] as Timestamp?;
          return expiresAt != null && expiresAt.toDate().isAfter(DateTime.now());
        })
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        })
        .toList();
  }

  /// Delete a story
  Future<void> deleteStory(String storeId, String storyId) async {
    await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('stories')
        .doc(storyId)
        .delete();
  }

  /// Increment story views (only once per user, excluding store owner)
  Future<void> incrementViews(String storeId, String storyId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Get store data to check if current user is the owner
    final storeDoc = await _firestore.collection('stores').doc(storeId).get();
    final storeData = storeDoc.data();
    final ownerId = storeData?['ownerId'] as String?;

    // Don't count views from the store owner
    if (uid == ownerId) return;

    final storyRef = _firestore
        .collection('stores')
        .doc(storeId)
        .collection('stories')
        .doc(storyId);

    final storyDoc = await storyRef.get();
    final viewedBy = List<String>.from(storyDoc.data()?['viewedBy'] ?? []);

    // Only increment if user hasn't viewed before
    if (!viewedBy.contains(uid)) {
      await storyRef.update({
        'views': FieldValue.increment(1),
        'viewedBy': FieldValue.arrayUnion([uid]),
      });
    }
  }

  /// Get time remaining for a story
  String getTimeRemaining(Timestamp expiresAt) {
    final now = DateTime.now();
    final expiry = expiresAt.toDate();
    final difference = expiry.difference(now);

    if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Expiring soon';
    }
  }

  /// Clean up expired stories (call this periodically or on app start)
  Future<void> cleanupExpiredStories(String storeId) async {
    final now = Timestamp.now();
    
    final snapshot = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('stories')
        .where('expiresAt', isLessThanOrEqualTo: now)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
