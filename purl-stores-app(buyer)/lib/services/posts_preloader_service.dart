import 'package:cloud_firestore/cloud_firestore.dart';

class PostsPreloaderService {
  static final PostsPreloaderService _instance = PostsPreloaderService._internal();
  factory PostsPreloaderService() => _instance;
  PostsPreloaderService._internal();

  List<Map<String, dynamic>>? _cachedPosts;
  DocumentSnapshot? _lastDocument;
  bool _isPreloading = false;
  bool _isPreloaded = false;
  static const int _pageSize = 5;

  bool get isPreloaded => _isPreloaded;
  List<Map<String, dynamic>>? get cachedPosts => _cachedPosts;
  DocumentSnapshot? get lastDocument => _lastDocument;

  Future<void> preloadPosts() async {
    if (_isPreloading || _isPreloaded) return;
    
    _isPreloading = true;
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('posts')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _cachedPosts = await _enrichPostsWithStoreData(snapshot.docs);
        _isPreloaded = true;
      }
    } catch (e) {
      print('Error preloading posts: $e');
    } finally {
      _isPreloading = false;
    }
  }

  Future<List<Map<String, dynamic>>> _enrichPostsWithStoreData(List<QueryDocumentSnapshot> docs) async {
    final posts = <Map<String, dynamic>>[];
    final storeIds = <String>{};
    
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      data['storeId'] = doc.reference.parent.parent!.id;
      storeIds.add(data['storeId'] as String);
      posts.add(data);
    }

    final storeDataMap = <String, Map<String, dynamic>>{};
    await Future.wait(
      storeIds.map((storeId) async {
        try {
          final storeDoc = await FirebaseFirestore.instance
              .collection('stores')
              .doc(storeId)
              .get();
          
          if (storeDoc.exists) {
            storeDataMap[storeId] = storeDoc.data() ?? {};
          }
        } catch (e) {
          print('Error fetching store $storeId: $e');
        }
      }),
    );

    for (final post in posts) {
      final storeId = post['storeId'] as String;
      final storeData = storeDataMap[storeId];
      
      if (storeData != null) {
        post['storeName'] = storeData['name'] ?? 'Store';
        post['storeLogoUrl'] = storeData['logoUrl'];
      } else {
        post['storeName'] = 'Store';
      }
    }

    return posts;
  }

  void clearCache() {
    _cachedPosts = null;
    _lastDocument = null;
    _isPreloaded = false;
  }
}
