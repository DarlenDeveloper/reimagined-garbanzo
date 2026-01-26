import 'package:cloud_firestore/cloud_firestore.dart';

/// PostsService manages store posts (social feed).
/// 
/// FIRESTORE STRUCTURE:
/// /stores/{storeId}/posts/{postId}
/// ├── content: string
/// ├── mediaUrls: array<object>
/// ├── hashtags: array<string>
/// ├── likes, comments, shares, views: number
/// ├── createdAt, updatedAt: timestamp
///
/// /hashtags/{hashtag} (MAIN COLLECTION for discovery)
/// ├── tag: string
/// ├── postCount: number
/// ├── lastUsed: timestamp
/// └── posts: subcollection
///     └── {postId}
///         ├── storeId: string
///         ├── storeName: string
///         ├── storeLogoUrl: string
///         ├── content: string (preview)
///         ├── thumbnailUrl: string
///         ├── createdAt: timestamp
class PostsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get reference to posts collection for a store
  CollectionReference<Map<String, dynamic>> _postsRef(String storeId) {
    return _firestore.collection('stores').doc(storeId).collection('posts');
  }

  /// Create a new post with hashtags
  Future<String> createPost({
    required String storeId,
    required String storeName,
    String? storeLogoUrl,
    required String content,
    List<Map<String, dynamic>> mediaUrls = const [],
    bool isPremium = false,
  }) async {
    // Extract hashtags from content
    final hashtags = _extractHashtags(content);
    
    final postData = {
      'storeName': storeName,
      'storeLogoUrl': storeLogoUrl ?? '',
      'content': content,
      'mediaUrls': mediaUrls,
      'hashtags': hashtags,
      'likes': 0,
      'likedBy': [], // Track who liked
      'savedBy': [], // Track who saved
      'comments': 0,
      'shares': 0,
      'views': 0,
      'isPremium': isPremium,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    final docRef = await _postsRef(storeId).add(postData);
    
    // Update hashtags collection
    if (hashtags.isNotEmpty) {
      await _updateHashtagsCollection(
        postId: docRef.id,
        storeId: storeId,
        storeName: storeName,
        storeLogoUrl: storeLogoUrl,
        content: content,
        hashtags: hashtags,
        thumbnailUrl: mediaUrls.isNotEmpty ? mediaUrls[0]['thumbnailUrl'] : null,
      );
    }
    
    return docRef.id;
  }

  /// Extract hashtags from text
  List<String> _extractHashtags(String text) {
    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(text);
    return matches.map((match) => match.group(1)!.toLowerCase()).toList();
  }

  /// Update hashtags collection for discovery
  Future<void> _updateHashtagsCollection({
    required String postId,
    required String storeId,
    required String storeName,
    String? storeLogoUrl,
    required String content,
    required List<String> hashtags,
    String? thumbnailUrl,
  }) async {
    final batch = _firestore.batch();
    
    for (final tag in hashtags) {
      final hashtagRef = _firestore.collection('hashtags').doc(tag);
      
      // Update or create hashtag document
      batch.set(hashtagRef, {
        'tag': tag,
        'postCount': FieldValue.increment(1),
        'lastUsed': Timestamp.now(),
      }, SetOptions(merge: true));
      
      // Add post reference to hashtag's posts subcollection
      final postRef = hashtagRef.collection('posts').doc(postId);
      batch.set(postRef, {
        'storeId': storeId,
        'storeName': storeName,
        'storeLogoUrl': storeLogoUrl ?? '',
        'content': content.length > 200 ? '${content.substring(0, 200)}...' : content,
        'thumbnailUrl': thumbnailUrl ?? '',
        'createdAt': Timestamp.now(),
      });
    }
    
    await batch.commit();
  }

  /// Get posts for a store with pagination
  Future<List<Map<String, dynamic>>> getPosts(String storeId, {int limit = 10}) async {
    final snapshot = await _postsRef(storeId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Get trending hashtags
  Future<List<Map<String, dynamic>>> getTrendingHashtags({int limit = 20}) async {
    final snapshot = await _firestore
        .collection('hashtags')
        .orderBy('postCount', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Get posts by hashtag
  Future<List<Map<String, dynamic>>> getPostsByHashtag(String hashtag, {int limit = 20}) async {
    final snapshot = await _firestore
        .collection('hashtags')
        .doc(hashtag.toLowerCase())
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Stream posts for real-time updates
  Stream<List<Map<String, dynamic>>> getPostsStream(String storeId) {
    return _postsRef(storeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Update post content
  Future<void> updatePost(String storeId, String postId, String content) async {
    await _postsRef(storeId).doc(postId).update({
      'content': content,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete a post
  Future<void> deletePost(String storeId, String postId) async {
    await _postsRef(storeId).doc(postId).delete();
    // Note: Hashtag cleanup can be done via Cloud Functions
  }

  /// Increment views count
  Future<void> incrementViews(String storeId, String postId) async {
    await _postsRef(storeId).doc(postId).update({
      'views': FieldValue.increment(1),
    });
  }

  /// Toggle like (like or unlike)
  Future<void> toggleLike(String storeId, String postId, String userId) async {
    final postRef = _postsRef(storeId).doc(postId);
    final postDoc = await postRef.get();
    final likedBy = List<String>.from(postDoc.data()?['likedBy'] ?? []);

    if (likedBy.contains(userId)) {
      // Unlike
      await postRef.update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([userId]),
      });
    } else {
      // Like
      await postRef.update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([userId]),
      });
    }
  }

  /// Check if user has liked a post
  bool hasUserLiked(Map<String, dynamic> post, String userId) {
    final likedBy = List<String>.from(post['likedBy'] ?? []);
    return likedBy.contains(userId);
  }

  /// Increment comments count
  Future<void> incrementComments(String storeId, String postId) async {
    await _postsRef(storeId).doc(postId).update({
      'comments': FieldValue.increment(1),
    });
  }

  /// Increment shares count
  Future<void> incrementShares(String storeId, String postId) async {
    await _postsRef(storeId).doc(postId).update({
      'shares': FieldValue.increment(1),
    });
  }

  /// Get post count for a store
  Future<int> getPostCount(String storeId) async {
    final snapshot = await _postsRef(storeId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get total engagement (likes + comments + shares) for all posts
  Future<Map<String, int>> getEngagementStats(String storeId) async {
    final snapshot = await _postsRef(storeId).get();

    int totalLikes = 0;
    int totalComments = 0;
    int totalShares = 0;
    int totalViews = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      totalLikes += (data['likes'] as int?) ?? 0;
      totalComments += (data['comments'] as int?) ?? 0;
      totalShares += (data['shares'] as int?) ?? 0;
      totalViews += (data['views'] as int?) ?? 0;
    }

    return {
      'likes': totalLikes,
      'comments': totalComments,
      'shares': totalShares,
      'views': totalViews,
    };
  }

  /// Calculate time ago string from timestamp
  String getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
