import 'package:cloud_firestore/cloud_firestore.dart';

/// FollowersService manages store followers.
/// 
/// FIRESTORE STRUCTURE:
/// /storeFollowers/{storeId}
/// ├── count: number
/// ├── updatedAt: timestamp
/// 
/// /storeFollowers/{storeId}/followers/{userId}
/// ├── followedAt: timestamp
class FollowersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get follower count for a store
  Future<int> getFollowerCount(String storeId) async {
    try {
      final doc = await _firestore
          .collection('storeFollowers')
          .doc(storeId)
          .get();

      if (doc.exists && doc.data()?['count'] != null) {
        return doc.data()!['count'] as int;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Stream follower count for real-time updates
  Stream<int> getFollowerCountStream(String storeId) {
    return _firestore
        .collection('storeFollowers')
        .doc(storeId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data()?['count'] != null) {
        return doc.data()!['count'] as int;
      }
      return 0;
    });
  }

  /// Add a follower (called from buyer app)
  Future<void> followStore(String storeId, String userId) async {
    final batch = _firestore.batch();

    // Add to followers subcollection
    final followerRef = _firestore
        .collection('storeFollowers')
        .doc(storeId)
        .collection('followers')
        .doc(userId);

    batch.set(followerRef, {
      'followedAt': FieldValue.serverTimestamp(),
    });

    // Increment count
    final countRef = _firestore.collection('storeFollowers').doc(storeId);
    batch.set(
      countRef,
      {
        'count': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// Remove a follower (called from buyer app)
  Future<void> unfollowStore(String storeId, String userId) async {
    final batch = _firestore.batch();

    // Remove from followers subcollection
    final followerRef = _firestore
        .collection('storeFollowers')
        .doc(storeId)
        .collection('followers')
        .doc(userId);

    batch.delete(followerRef);

    // Decrement count
    final countRef = _firestore.collection('storeFollowers').doc(storeId);
    batch.update(countRef, {
      'count': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Check if user follows a store
  Future<bool> isFollowing(String storeId, String userId) async {
    final doc = await _firestore
        .collection('storeFollowers')
        .doc(storeId)
        .collection('followers')
        .doc(userId)
        .get();

    return doc.exists;
  }
}
