import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/posts_service.dart';
import '../services/messages_service.dart';
import '../services/followers_service.dart';
import '../services/posts_preloader_service.dart';
import '../services/notification_service.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'store_profile_screen.dart';
import 'media_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final PostsService _postsService = PostsService();
  final MessagesService _messagesService = MessagesService();
  final FollowersService _followersService = FollowersService();
  final PostsPreloaderService _preloaderService = PostsPreloaderService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final Set<String> _likedPosts = {};
  final Set<String> _savedPosts = {};
  final Set<String> _followedVendors = {};
  
  // Cache for store data to prevent repeated fetches
  final Map<String, Map<String, dynamic>> _storeDataCache = {};
  
  // Persistent cache for verification status
  SharedPreferences? _prefs;
  
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _unreadMessageCount = 0;
  int _unreadNotificationCount = 0;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 5;

  @override
  void initState() {
    super.initState();
    _initCache();
    _loadFeed();
    _loadUnreadCount();
    _scrollController.addListener(_onScroll);
  }
  
  Future<void> _initCache() async {
    _prefs = await SharedPreferences.getInstance();
    // Load cached verification statuses
    final cachedData = _prefs?.getString('store_verification_cache');
    if (cachedData != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(cachedData);
        decoded.forEach((key, value) {
          if (value is Map) {
            _storeDataCache[key] = Map<String, dynamic>.from(value);
          }
        });
        print('📦 Loaded ${_storeDataCache.length} stores from cache');
        
        // Check cache age and refresh if older than 1 hour
        final cacheTimestamp = _prefs?.getInt('store_cache_timestamp') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        final cacheAge = now - cacheTimestamp;
        final oneHour = 60 * 60 * 1000; // 1 hour in milliseconds
        
        if (cacheAge > oneHour) {
          print('🔄 Cache is older than 1 hour, will refresh on next fetch');
          // Don't clear cache immediately, but mark it for refresh
          _prefs?.setBool('cache_needs_refresh', true);
        }
      } catch (e) {
        print('Error loading cache: $e');
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      if (!_isLoadingMore) {
        _loadMorePosts();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    // Check if posts are already preloaded
    if (_preloaderService.isPreloaded && _preloaderService.cachedPosts != null) {
      print('📦 Using preloaded posts');
      setState(() {
        _posts = List.from(_preloaderService.cachedPosts!);
        _lastDocument = _preloaderService.lastDocument;
        _isLoading = false;
      });
      
      // Enrich preloaded posts with store data (including verification status)
      await _enrichPreloadedPosts();
      
      // Initialize liked/saved/followed states
      for (final post in _posts) {
        if (_postsService.hasUserLiked(post, _auth.currentUser?.uid ?? '')) {
          _likedPosts.add(post['id']);
        }
        final savedBy = List<String>.from(post['savedBy'] ?? []);
        if (savedBy.contains(_auth.currentUser?.uid ?? '')) {
          _savedPosts.add(post['id']);
        }
      }
      
      await _loadFollowingStatus();
      return;
    }
    
    // Fallback to normal loading if preload didn't happen
    print('🔄 Loading posts from Firestore');
    setState(() => _isLoading = true);
    _lastDocument = null;
    _posts.clear();
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('posts')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        await _enrichPostsWithStoreData(snapshot.docs);
      }

      setState(() => _isLoading = false);
      await _loadFollowingStatus();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _enrichPreloadedPosts() async {
    // Get unique store IDs from preloaded posts
    final storeIds = _posts.map((post) => post['storeId'] as String).toSet();
    print('🔍 Enriching ${_posts.length} preloaded posts from ${storeIds.length} stores');
    
    final storeDataMap = <String, Map<String, dynamic>>{};
    final storesToFetch = <String>[];
    
    // Check if cache needs refresh
    final needsRefresh = _prefs?.getBool('cache_needs_refresh') ?? false;
    
    // First, check cache for all stores
    for (final storeId in storeIds) {
      if (_storeDataCache.containsKey(storeId) && !needsRefresh) {
        storeDataMap[storeId] = _storeDataCache[storeId]!;
        print('✅ Using cached data for store: $storeId (verified: ${_storeDataCache[storeId]!['verificationStatus']})');
      } else {
        storesToFetch.add(storeId);
      }
    }
    
    // Fetch missing stores from Firestore
    if (storesToFetch.isNotEmpty) {
      print('🔄 Fetching ${storesToFetch.length} stores from Firestore');
      await Future.wait(
        storesToFetch.map((storeId) async {
          try {
            final storeDoc = await FirebaseFirestore.instance
                .collection('stores')
                .doc(storeId)
                .get();
            
            if (storeDoc.exists) {
              final data = storeDoc.data() ?? {};
              // Cache the store data in memory
              _storeDataCache[storeId] = data;
              storeDataMap[storeId] = data;
              print('✅ Fetched and cached store: $storeId (verified: ${data['verificationStatus']})');
            }
          } catch (e) {
            print('❌ Error fetching store $storeId: $e');
          }
        }),
      );
      
      // Persist cache to SharedPreferences
      _saveCache();
    }
    
    // Update posts with store data
    for (final post in _posts) {
      final storeId = post['storeId'] as String;
      final storeData = storeDataMap[storeId];
      
      if (storeData != null) {
        post['storeName'] = storeData['name'] ?? 'Store';
        post['storeLogoUrl'] = storeData['logoUrl'];
        post['storeVerificationStatus'] = storeData['verificationStatus'];
        print('📝 Post ${post['id']}: store=${post['storeName']}, verified=${post['storeVerificationStatus']}');
      } else {
        post['storeName'] = 'Store';
        print('⚠️ Post ${post['id']}: No store data found');
      }
    }
    
    // Trigger rebuild to show verification badges
    setState(() {});
  }

  Future<void> _loadMorePosts() async {
    if (_lastDocument == null) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('posts')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        await _enrichPostsWithStoreData(snapshot.docs);
      }

      setState(() => _isLoadingMore = false);
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _enrichPostsWithStoreData(List<QueryDocumentSnapshot> docs) async {
    final newPosts = <Map<String, dynamic>>[];
    final storeIds = <String>{};
    
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      data['storeId'] = doc.reference.parent.parent!.id;
      storeIds.add(data['storeId'] as String);
      newPosts.add(data);
    }

    final storeDataMap = <String, Map<String, dynamic>>{};
    final storesToFetch = <String>[];
    
    // Check if cache needs refresh
    final needsRefresh = _prefs?.getBool('cache_needs_refresh') ?? false;
    
    // First, check cache for all stores
    for (final storeId in storeIds) {
      if (_storeDataCache.containsKey(storeId) && !needsRefresh) {
        storeDataMap[storeId] = _storeDataCache[storeId]!;
        print('✅ Using cached data for store: $storeId (verified: ${_storeDataCache[storeId]!['verificationStatus']})');
      } else {
        storesToFetch.add(storeId);
      }
    }
    
    // Fetch missing stores from Firestore
    if (storesToFetch.isNotEmpty) {
      print('🔄 Fetching ${storesToFetch.length} stores from Firestore');
      await Future.wait(
        storesToFetch.map((storeId) async {
          try {
            final storeDoc = await FirebaseFirestore.instance
                .collection('stores')
                .doc(storeId)
                .get();
            
            if (storeDoc.exists) {
              final data = storeDoc.data() ?? {};
              // Cache the store data in memory
              _storeDataCache[storeId] = data;
              storeDataMap[storeId] = data;
              print('✅ Fetched and cached store: $storeId (verified: ${data['verificationStatus']})');
            }
          } catch (e) {
            print('❌ Error fetching store $storeId: $e');
          }
        }),
      );
      
      // Persist cache to SharedPreferences
      _saveCache();
    }

    for (final post in newPosts) {
      final storeId = post['storeId'] as String;
      final storeData = storeDataMap[storeId];
      
      if (storeData != null) {
        post['storeName'] = storeData['name'] ?? 'Store';
        post['storeLogoUrl'] = storeData['logoUrl'];
        post['storeVerificationStatus'] = storeData['verificationStatus'];
        print('📝 Post ${post['id']}: store=${post['storeName']}, verified=${post['storeVerificationStatus']}');
      } else {
        post['storeName'] = 'Store';
        print('⚠️ Post ${post['id']}: No store data found');
      }
    }

    setState(() {
      _posts.addAll(newPosts);
      
      for (final post in newPosts) {
        if (_postsService.hasUserLiked(post, _auth.currentUser?.uid ?? '')) {
          _likedPosts.add(post['id']);
        }
        final savedBy = List<String>.from(post['savedBy'] ?? []);
        if (savedBy.contains(_auth.currentUser?.uid ?? '')) {
          _savedPosts.add(post['id']);
        }
      }
    });
  }
  
  Future<void> _saveCache() async {
    try {
      final cacheData = json.encode(_storeDataCache);
      await _prefs?.setString('store_verification_cache', cacheData);
      await _prefs?.setInt('store_cache_timestamp', DateTime.now().millisecondsSinceEpoch);
      await _prefs?.setBool('cache_needs_refresh', false);
      print('💾 Saved ${_storeDataCache.length} stores to persistent cache');
    } catch (e) {
      print('Error saving cache: $e');
    }
  }

  Future<void> _loadFollowingStatus() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Get unique store IDs from posts
    final storeIds = _posts.map((post) => post['storeId'] as String).toSet();

    // Check following status for each store
    for (final storeId in storeIds) {
      final isFollowing = await _followersService.isFollowing(userId, storeId);
      if (isFollowing) {
        setState(() => _followedVendors.add(storeId));
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    print('🔔 Loading unread counts for user: $userId');

    // Listen to conversations for real-time unread count
    _messagesService.getUserConversations(userId).listen((conversations) {
      int totalUnread = 0;
      for (final conversation in conversations) {
        final unreadCount = (conversation['unreadCount'] as Map<String, dynamic>?)?[userId] ?? 0;
        totalUnread += unreadCount as int;
      }
      print('💬 Message unread count: $totalUnread');
      if (mounted) {
        setState(() => _unreadMessageCount = totalUnread);
      }
    });
    
    // Listen to notifications for real-time unread count with detailed logging
    FirebaseFirestore.instance
        .collection('stores')
        .doc(userId)
        .collection('notifications')
        .snapshots()
        .listen((snapshot) {
      print('📦 Total notifications: ${snapshot.docs.length}');
      int unreadCount = 0;
      for (var doc in snapshot.docs) {
        final isRead = doc.data()['isRead'] ?? true;
        print('  - ${doc.id}: isRead=$isRead');
        if (!isRead) unreadCount++;
      }
      print('🔔 Notification unread count: $unreadCount');
      if (mounted) {
        setState(() => _unreadNotificationCount = unreadCount);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFeed,
          color: Colors.black,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildTopBar()),
              _isLoading
                  ? SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildSkeletonPostCard(),
                        childCount: 5,
                      ),
                    )
                  : _posts.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.document, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('No posts yet', style: GoogleFonts.poppins(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == _posts.length) {
                                return _isLoadingMore
                                    ? Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Center(
                                          child: CircularProgressIndicator(color: Colors.black),
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              }
                              final post = _posts[index];
                              return _buildPostCard(post);
                            },
                            childCount: _posts.length + (_isLoadingMore ? 1 : 0),
                          ),
                        ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/wibblelogo.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('P', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Text('Wibble', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
          const Spacer(),
          _buildHeaderIcon(Iconsax.search_normal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()))),
          const SizedBox(width: 16),
          _buildNotificationIcon(),
          const SizedBox(width: 16),
          _buildMessageIcon(),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Iconsax.notification, size: 24, color: Colors.black),
          if (_unreadNotificationCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageIcon() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen())),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Iconsax.message, size: 24, color: Colors.black),
          if (_unreadMessageCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  _unreadMessageCount > 99 ? '99+' : '$_unreadMessageCount',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 24, color: Colors.black),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final postId = post['id'] as String;
    final storeId = post['storeId'] as String;
    final storeName = post['storeName'] ?? 'Store';
    final storeLogoUrl = post['storeLogoUrl'] as String?;
    final storeVerificationStatus = post['storeVerificationStatus'] as String?;
    final isStoreVerified = storeVerificationStatus == 'verified';
    final content = post['content'] ?? '';
    final likes = post['likes'] ?? 0;
    final createdAt = post['createdAt'] as Timestamp?;
    final mediaList = post['mediaUrls'] as List?;
    
    // Debug logging
    print('🎨 Building post card: postId=$postId, storeId=$storeId, storeName=$storeName, verificationStatus=$storeVerificationStatus, isVerified=$isStoreVerified');
    
    final isLiked = _likedPosts.contains(postId);
    final isSaved = _savedPosts.contains(postId);
    final isFollowing = _followedVendors.contains(storeId);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          GestureDetector(
            onTap: () => _openStoreProfile(storeId, storeName),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              backgroundImage: (storeLogoUrl != null && storeLogoUrl.isNotEmpty)
                  ? NetworkImage(storeLogoUrl)
                  : null,
              onBackgroundImageError: (storeLogoUrl != null && storeLogoUrl.isNotEmpty)
                  ? (exception, stackTrace) {}
                  : null,
              child: (storeLogoUrl == null || storeLogoUrl.isEmpty)
                  ? Icon(Iconsax.shop, size: 18, color: Colors.grey[600])
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _openStoreProfile(storeId, storeName),
                      child: Row(
                        children: [
                          Text(storeName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                          if (isStoreVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 18, color: Colors.blue),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('· ${createdAt != null ? _postsService.getTimeAgo(createdAt) : '1h'}', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
                    const Spacer(),
                    if (!isFollowing)
                      GestureDetector(
                        onTap: () => _toggleFollow(storeId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
                          child: Text('Follow', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                        ),
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showMoreOptions(context, post),
                      child: Icon(Iconsax.more, size: 18, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Post content
                Text(content, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black, height: 1.4)),
                // Image if available
                if (mediaList != null && mediaList.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MediaPreviewScreen(
                            mediaList: List<Map<String, dynamic>>.from(mediaList),
                            initialIndex: 0,
                            storeName: storeName,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9, // Reserve space for image
                        child: Image.network(
                          (mediaList[0] as Map<String, dynamic>)['thumbnailUrl'] ?? '',
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[100],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Iconsax.image, size: 32, color: Colors.grey[400]),
                                    const SizedBox(height: 4),
                                    Text('Product Image', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400])),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
                // Action buttons - like, save, share, DM
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      _buildActionBtn(isLiked ? Iconsax.heart5 : Iconsax.heart, '${likes + (isLiked ? 1 : 0)}', () => _toggleLike(postId, storeId), isActive: isLiked),
                      const SizedBox(width: 24),
                      _buildActionBtn(isSaved ? Iconsax.archive_tick : Iconsax.archive_add, '', () => _toggleSave(postId, storeId), isActive: isSaved),
                      // Share button disabled for now
                      // const SizedBox(width: 24),
                      // _buildActionBtn(Iconsax.share, '', () => _sharePost(post)),
                      const Spacer(),
                      _buildActionBtn(Iconsax.direct_send, '', () => _sendDM(storeId, storeName)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonPostCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Skeleton content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header skeleton
                Row(
                  children: [
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 60,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Text skeleton
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 200,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                // Image skeleton
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String count, VoidCallback onTap, {bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isActive ? Colors.black : Colors.grey[500]),
          if (count.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(count, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
          ],
        ],
      ),
    );
  }

  void _openStoreProfile(String storeId, String storeName) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => StoreProfileScreen(storeId: storeId, storeName: storeName, storeAvatar: storeName[0])));
  }

  void _toggleLike(String postId, String storeId) async {
    setState(() => _likedPosts.contains(postId) ? _likedPosts.remove(postId) : _likedPosts.add(postId));
    await _postsService.toggleLike(storeId, postId, _auth.currentUser?.uid ?? '');
  }
  
  void _toggleSave(String postId, String storeId) async {
    setState(() => _savedPosts.contains(postId) ? _savedPosts.remove(postId) : _savedPosts.add(postId));
    
    final postRef = FirebaseFirestore.instance.collection('stores').doc(storeId).collection('posts').doc(postId);
    if (_savedPosts.contains(postId)) {
      await postRef.update({'savedBy': FieldValue.arrayUnion([_auth.currentUser?.uid ?? ''])});
    } else {
      await postRef.update({'savedBy': FieldValue.arrayRemove([_auth.currentUser?.uid ?? ''])});
    }
  }
  
  void _toggleFollow(String vendorId) async {
    setState(() => _followedVendors.contains(vendorId) ? _followedVendors.remove(vendorId) : _followedVendors.add(vendorId));
    
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    if (_followedVendors.contains(vendorId)) {
      await _followersService.followStore(userId, vendorId);
    } else {
      await _followersService.unfollowStore(userId, vendorId);
    }
  }

  void _copyPromoCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Promo code "$code" copied!', style: GoogleFonts.poppins()), backgroundColor: Colors.black, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
  }

  void _sharePost(Map<String, dynamic> post) {
    final shareText = '${post['storeName']}: ${post['content']}\n\nShop on POP';
    Share.share(shareText);
  }

  void _sendDM(String vendorId, String vendorName) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Get user name - try multiple sources
    String userName = 'User';
    String? userPhotoUrl;
    
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData != null && userData['name'] != null && (userData['name'] as String).isNotEmpty) {
        userName = userData['name'];
      }
      userPhotoUrl = userData?['photoUrl'] as String?;
    } catch (e) {
      print('Error fetching user: $e');
    }
    
    // Fallback to Firebase Auth displayName
    if (userName == 'User' && _auth.currentUser?.displayName != null && _auth.currentUser!.displayName!.isNotEmpty) {
      userName = _auth.currentUser!.displayName!;
    }
    
    // Fallback to email username
    if (userName == 'User' && _auth.currentUser?.email != null) {
      userName = _auth.currentUser!.email!.split('@')[0];
    }

    await _messagesService.getOrCreateConversation(
      storeId: vendorId,
      storeName: vendorName,
      storeLogoUrl: null,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
    );

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen()));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Start a conversation with $vendorName', style: GoogleFonts.poppins()), backgroundColor: Colors.black, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
    }
  }

  void _showMoreOptions(BuildContext ctx, Map<String, dynamic> post) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            _buildOptionTile(Iconsax.shop, 'Visit store'),
            _buildOptionTile(Iconsax.link, 'Copy link'),
            _buildOptionTile(Iconsax.flag, 'Report'),
            _buildOptionTile(Iconsax.slash, 'Not interested'),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.black, size: 22),
      title: Text(label, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black)),
      onTap: () => Navigator.pop(context),
    );
  }
}
