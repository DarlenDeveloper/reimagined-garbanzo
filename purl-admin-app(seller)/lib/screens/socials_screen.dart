import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../services/posts_service.dart';
import '../services/followers_service.dart';
import '../services/store_service.dart';
import '../services/media_service.dart';
import '../services/stories_service.dart';

class SocialsScreen extends StatefulWidget {
  const SocialsScreen({super.key});

  @override
  State<SocialsScreen> createState() => _SocialsScreenState();
}

class _SocialsScreenState extends State<SocialsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PostsService _postsService = PostsService();
  final FollowersService _followersService = FollowersService();
  final StoreService _storeService = StoreService();
  final StoriesService _storiesService = StoriesService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _storeId;
  bool _isLoading = true;
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _stories = [];
  int _followerCount = 0;
  Map<String, int> _engagementStats = {};
  String _storeName = '';
  String? _storeLogoUrl;



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update FAB
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get store ID
      final storeId = await _storeService.getUserStoreId();
      if (storeId == null) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() => _storeId = storeId);

      // Clean up expired stories
      await _storiesService.cleanupExpiredStories(storeId);

      // Load store data
      final storeData = await _storeService.getStore(storeId);
      
      // Load posts
      final posts = await _postsService.getPosts(storeId);
      
      // Load stories
      final stories = await _storiesService.getActiveStories(storeId);
      
      // Load follower count
      final followerCount = await _followersService.getFollowerCount(storeId);
      
      // Load engagement stats
      final engagementStats = await _postsService.getEngagementStats(storeId);

      setState(() {
        _storeName = storeData?['name'] ?? 'Your Store';
        _storeLogoUrl = storeData?['logoUrl'];
        _posts = posts;
        _stories = stories;
        _followerCount = followerCount;
        _engagementStats = engagementStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatePostSheet(
        storeId: _storeId,
        onPost: (content, mediaUrls, taggedProductIds) async {
          if (_storeId == null) return;
          
          try {
            await _postsService.createPost(
              storeId: _storeId!,
              storeName: _storeName,
              storeLogoUrl: _storeLogoUrl,
              content: content,
              mediaUrls: mediaUrls,
              taggedProductIds: taggedProductIds,
              isPremium: false,
            );
            
            // Reload posts
            _loadData();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to create post: $e')),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: Colors.black), onPressed: () => Navigator.pop(context)),
          title: Text('Store Feed', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
        ),
        body: _buildSkeletonLoader(),
      );
    }

    // Calculate engagement rate
    final totalViews = _engagementStats['views'] ?? 0;
    final totalEngagement = (_engagementStats['likes'] ?? 0) + 
                           (_engagementStats['comments'] ?? 0) + 
                           (_engagementStats['shares'] ?? 0);
    final engagementRate = totalViews > 0 
        ? ((totalEngagement / totalViews) * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text('Store Feed', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Iconsax.chart, color: Colors.black), onPressed: () => _showInsights()),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _showCreatePostSheet,
              backgroundColor: Colors.black,
              child: const Icon(Iconsax.add, color: Colors.white),
            )
          : FloatingActionButton(
              onPressed: _showCreateStorySheet,
              backgroundColor: Colors.black,
              child: const Icon(Iconsax.camera, color: Colors.white),
            ),
      body: Column(
        children: [
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _miniStat(_formatNumber(_followerCount), 'Followers'),
                _miniStat('${_posts.length}', 'Posts'),
                _miniStat('$engagementRate%', 'Engagement'),
                _miniStat(_formatNumber(totalViews), 'Reach'),
              ],
            ),
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.black,
            indicatorWeight: 2,
            dividerColor: Colors.transparent,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            tabs: const [Tab(text: 'Posts'), Tab(text: 'Stories')],
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _loadData,
                  color: Colors.black,
                  child: _buildPostsList(),
                ),
                RefreshIndicator(
                  onRefresh: _loadData,
                  color: Colors.black,
                  child: _buildStoriesList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _miniStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]!)),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.document, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No posts yet', style: GoogleFonts.poppins(color: Colors.grey[600])),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _showCreatePostSheet,
              child: Text('Create your first post', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _PostCard(
          key: ValueKey(post['id']),
          post: post,
          postsService: _postsService,
          storeName: _storeName,
          storeLogoUrl: _storeLogoUrl,
          storeId: _storeId!,
          userId: _auth.currentUser?.uid ?? '',
          onTap: () => _showPostDetails(post),
          onDelete: () async {
            if (_storeId != null) {
              await _postsService.deletePost(_storeId!, post['id']);
              _loadData();
            }
          },
        );
      },
    );
  }

  Widget _buildStoriesList() {
    if (_stories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.video_circle, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No stories yet', style: GoogleFonts.poppins(color: Colors.grey[600])),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _showCreateStorySheet,
              child: Text('Create your first story', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 9 / 16,
      ),
      itemCount: _stories.length,
      itemBuilder: (context, index) {
        final story = _stories[index];
        return _StoryCard(
          story: story,
          storiesService: _storiesService,
          onTap: () => _viewStory(index),
          onDelete: () async {
            if (_storeId != null) {
              await _storiesService.deleteStory(_storeId!, story['id']);
              _loadData();
            }
          },
        );
      },
    );
  }

  void _showCreateStorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Story', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _storyOption(Iconsax.image, 'Photo', () async {
                    Navigator.pop(context);
                    await _pickStoryMedia(ImageSource.gallery, isVideo: false);
                  }),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _storyOption(Iconsax.video, 'Video', () async {
                    Navigator.pop(context);
                    await _pickStoryMedia(ImageSource.gallery, isVideo: true);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _storyOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.black, size: 28),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStoryMedia(ImageSource source, {required bool isVideo}) async {
    if (_storeId == null) return;

    try {
      final picker = ImagePicker();
      XFile? file;

      if (isVideo) {
        file = await picker.pickVideo(source: source);
      } else {
        file = await picker.pickImage(source: source);
      }

      if (file == null) return;

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );

      final mediaService = MediaService();
      final postId = DateTime.now().millisecondsSinceEpoch.toString();

      if (isVideo) {
        final mediaData = await mediaService.uploadVideo(
          videoFile: File(file.path),
          storeId: _storeId!,
          postId: postId,
        );

        await _storiesService.createStory(
          storeId: _storeId!,
          mediaUrl: mediaData['fullUrl'],
          mediaType: 'video',
          thumbnailUrl: mediaData['thumbnailUrl'],
          duration: mediaData['duration'],
        );
      } else {
        final mediaData = await mediaService.uploadImage(
          imageFile: File(file.path),
          storeId: _storeId!,
          postId: postId,
        );

        await _storiesService.createStory(
          storeId: _storeId!,
          mediaUrl: mediaData['fullUrl'],
          mediaType: 'image',
          thumbnailUrl: mediaData['thumbnailUrl'],
        );
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story created successfully'),
          backgroundColor: Colors.black,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create story: $e')),
      );
    }
  }

  void _viewStory(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _StoryViewerScreen(
          stories: _stories,
          initialIndex: initialIndex,
          storeName: _storeName,
          storeLogoUrl: _storeLogoUrl,
          storiesService: _storiesService,
          storeId: _storeId!,
          onDelete: (storyId) async {
            await _storiesService.deleteStory(_storeId!, storyId);
            Navigator.pop(context);
            _loadData();
          },
        ),
      ),
    );
  }

  void _showInsights() {
    final totalViews = _engagementStats['views'] ?? 0;
    final totalLikes = _engagementStats['likes'] ?? 0;
    final totalComments = _engagementStats['comments'] ?? 0;
    final totalShares = _engagementStats['shares'] ?? 0;
    final totalEngagement = totalLikes + totalComments + totalShares;
    final engagementRate = totalViews > 0 
        ? ((totalEngagement / totalViews) * 100).toStringAsFixed(1)
        : '0.0';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Insights', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
            const SizedBox(height: 20),
            Row(children: [
              _insightCard('Total Views', _formatNumber(totalViews), '${_posts.length} posts'), 
              const SizedBox(width: 12), 
              _insightCard('Engagement', '$engagementRate%', '$totalEngagement total')
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _insightCard('Followers', _formatNumber(_followerCount), 'Total'), 
              const SizedBox(width: 12), 
              _insightCard('Total Likes', _formatNumber(totalLikes), 'All posts')
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _insightCard(String label, String value, String change) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]!)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
            Text(change, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]!, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }



  void _showPostDetails(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Post Performance', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem(Iconsax.eye, '${post['views'] ?? 0}', 'Views'),
                _statItem(Iconsax.heart, '${post['likes'] ?? 0}', 'Likes'),
                _statItem(Iconsax.message, '${post['comments'] ?? 0}', 'Comments'),
                _statItem(Iconsax.send_2, '${post['shares'] ?? 0}', 'Shares'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _actionBtn(Iconsax.edit, 'Edit', () => Navigator.pop(context))),
                const SizedBox(width: 12),
                Expanded(child: _actionBtn(Iconsax.trash, 'Delete', () async {
                  Navigator.pop(context);
                  if (_storeId != null) {
                    await _postsService.deletePost(_storeId!, post['id']);
                    _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post deleted'), backgroundColor: Colors.black),
                      );
                    }
                  }
                }, isDestructive: true)),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]!, size: 20),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.black)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]!)),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.1) : Colors.white, 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDestructive ? Colors.red : Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: isDestructive ? Colors.red : Colors.black, size: 20),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, color: isDestructive ? Colors.red : Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Column(
      children: [
        // Stats skeleton
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: List.generate(4, (index) => Expanded(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 50,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ),
        ),
        // Tabs skeleton
        Container(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Posts skeleton
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: 3,
            itemBuilder: (context, index) => _buildSkeletonPost(),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonPost() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 120,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 60,
                          height: 11,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content skeleton
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 200,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Image skeleton
          AspectRatio(
            aspectRatio: 1,
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                color: Colors.white,
              ),
            ),
          ),
          // Engagement skeleton
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Spacer(),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class _PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final PostsService postsService;
  final String storeName;
  final String? storeLogoUrl;
  final String storeId;
  final String userId;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PostCard({
    super.key,
    required this.post,
    required this.postsService,
    required this.storeName,
    this.storeLogoUrl,
    required this.storeId,
    required this.userId,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  int? _likes;
  bool? _isLiked;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _updateLikeState();
  }

  @override
  void didUpdateWidget(_PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always update when widget rebuilds to get fresh data
    _updateLikeState();
  }

  void _updateLikeState() {
    setState(() {
      _likes = widget.post['likes'] ?? 0;
      _isLiked = widget.postsService.hasUserLiked(widget.post, widget.userId);
    });
  }

  Future<void> _handleLike() async {
    if (_isLiking || _likes == null || _isLiked == null) return;
    
    final wasLiked = _isLiked!;
    final wasLikes = _likes!;
    
    // Optimistic update
    setState(() {
      _isLiking = true;
      _isLiked = !_isLiked!;
      _likes = _likes! + (_isLiked! ? 1 : -1);
    });

    try {
      await widget.postsService.toggleLike(widget.storeId, widget.post['id'], widget.userId);
      
      // Update the post data in the parent's list
      widget.post['likes'] = _likes;
      if (_isLiked!) {
        widget.post['likedBy'] = [...(widget.post['likedBy'] ?? []), widget.userId];
      } else {
        final likedBy = List<String>.from(widget.post['likedBy'] ?? []);
        likedBy.remove(widget.userId);
        widget.post['likedBy'] = likedBy;
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isLiked = wasLiked;
        _likes = wasLikes;
      });
    } finally {
      setState(() {
        _isLiking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaList = widget.post['mediaUrls'] as List?;
    final hasMedia = mediaList != null && mediaList.isNotEmpty;
    final createdAt = widget.post['createdAt'] as Timestamp?;
    
    final timeAgo = createdAt != null 
        ? widget.postsService.getTimeAgo(createdAt)
        : 'Unknown';

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Store logo/avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: widget.storeLogoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            widget.storeLogoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  widget.storeName.isNotEmpty ? widget.storeName[0].toUpperCase() : 'S',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            widget.storeName.isNotEmpty ? widget.storeName[0].toUpperCase() : 'S',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.storeName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.more, size: 20),
                  onPressed: widget.onTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.black,
                ),
              ],
            ),
          ),
          
          // Media
          if (hasMedia)
            _buildMediaPreview(mediaList!),
          
          // Post content below media
          if (widget.post['content'] != null && (widget.post['content'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Text(
                widget.post['content'] ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.black,
                ),
              ),
            ),
          
          // Engagement row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (_likes != null && _isLiked != null)
                  _engagementButtonClickable(
                    _isLiked! ? Iconsax.heart5 : Iconsax.heart,
                    '$_likes',
                    _handleLike,
                    isActive: _isLiked!,
                  )
                else
                  _engagementButton(Iconsax.heart, '0'),
                const SizedBox(width: 20),
                _engagementButton(Iconsax.message, '${widget.post['comments'] ?? 0}'),
                const SizedBox(width: 20),
                _engagementButton(Iconsax.send_2, '${widget.post['shares'] ?? 0}'),
                const Spacer(),
                Text(
                  '${widget.post['views'] ?? 0} views',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(List mediaList) {
    final firstMedia = mediaList[0] as Map<String, dynamic>;
    final type = firstMedia['type'] as String?;
    final thumbnailUrl = firstMedia['thumbnailUrl'] as String?;
    final duration = firstMedia['duration'] as num?;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 500),
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (thumbnailUrl != null)
            Image.network(
              thumbnailUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(child: Icon(Iconsax.image, size: 48, color: Colors.grey[400]));
              },
            )
          else
            Center(child: Icon(Iconsax.image, size: 48, color: Colors.grey[400])),
          
          // Video play button
          if (type == 'video')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.play, color: Colors.white, size: 28),
            ),
          
          // Video duration
          if (type == 'video' && duration != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(duration.toInt()),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          
          // Multiple media indicator
          if (mediaList.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.gallery, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '1/${mediaList.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _engagementButton(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.black),
        if (value != '0') ...[
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _engagementButtonClickable(IconData icon, String value, VoidCallback onTap, {bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: isActive ? Colors.red : Colors.black),
          if (value != '0') ...[
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  final String? storeId;
  final Function(String content, List<Map<String, dynamic>> mediaUrls, List<String> taggedProductIds) onPost;
  const _CreatePostSheet({required this.storeId, required this.onPost});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _contentController = TextEditingController();
  final MediaService _mediaService = MediaService();
  final ImagePicker _picker = ImagePicker();
  
  List<File> _selectedMedia = [];
  List<String> _mediaTypes = []; // 'image' or 'video'
  List<String> _taggedProductIds = [];
  List<Map<String, dynamic>> _taggedProducts = [];
  bool _isPosting = false;
  bool _isUploadingMedia = false;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedMedia.add(File(image.path));
          _mediaTypes.add('image');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedMedia.add(File(video.path));
          _mediaTypes.add('video');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick video: $e')),
        );
      }
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
      _mediaTypes.removeAt(index);
    });
  }

  Future<void> _handlePost() async {
    if (_contentController.text.isEmpty && _selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add content or media')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      // Upload media if any
      List<Map<String, dynamic>> uploadedMedia = [];
      
      if (_selectedMedia.isNotEmpty && widget.storeId != null) {
        setState(() => _isUploadingMedia = true);
        
        for (int i = 0; i < _selectedMedia.length; i++) {
          final file = _selectedMedia[i];
          final type = _mediaTypes[i];
          final postId = DateTime.now().millisecondsSinceEpoch.toString();

          if (type == 'image') {
            final mediaData = await _mediaService.uploadImage(
              imageFile: file,
              storeId: widget.storeId!,
              postId: postId,
            );
            uploadedMedia.add(mediaData);
          } else if (type == 'video') {
            final mediaData = await _mediaService.uploadVideo(
              videoFile: file,
              storeId: widget.storeId!,
              postId: postId,
            );
            uploadedMedia.add(mediaData);
          }
        }
        
        setState(() => _isUploadingMedia = false);
      }

      await widget.onPost(_contentController.text, uploadedMedia, _taggedProductIds);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isPosting = false;
        _isUploadingMedia = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200]!, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isPosting ? null : () => Navigator.pop(context), 
                    child: Text('Cancel', style: GoogleFonts.poppins(color: _isPosting ? Colors.grey[400]! : Colors.grey[600]!)),
                  ),
                  Text('Create Post', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
                  const SizedBox(width: 60), // Spacer for alignment
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]!),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    height: 150,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _contentController,
                      maxLines: 6,
                      enabled: !_isPosting,
                      decoration: InputDecoration.collapsed(
                        hintText: "What's happening at your store?", 
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]!)
                      ),
                      style: GoogleFonts.poppins(color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Media and tag buttons
                  Row(
                    children: [
                      Expanded(
                        child: _mediaBtn(Iconsax.image, 'Photo', _pickImage, _selectedMedia.any((m) => _mediaTypes[_selectedMedia.indexOf(m)] == 'image')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _mediaBtn(Iconsax.video, 'Video', _pickVideo, _selectedMedia.any((m) => _mediaTypes[_selectedMedia.indexOf(m)] == 'video')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _mediaBtn(Iconsax.tag, 'Tag', _showProductPicker, _taggedProducts.isNotEmpty),
                      ),
                    ],
                  ),
                  
                  // Tagged products preview
                  if (_taggedProducts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _taggedProducts.map((product) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product['name'] ?? 'Product',
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _removeProduct(product['id']),
                                child: Icon(Icons.close, size: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                
                // Selected media preview
                if (_selectedMedia.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedMedia.length,
                      itemBuilder: (context, index) {
                        return _buildMediaPreview(index);
                      },
                    ),
                  ),
                ],
                
                // Upload progress
                if (_isUploadingMedia) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        ),
                        const SizedBox(width: 12),
                        Text('Uploading media...', style: GoogleFonts.poppins(color: Colors.black)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Post button at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isPosting ? null : _handlePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFb71000),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: _isPosting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Post',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _mediaBtn(IconData icon, String label, VoidCallback onTap, bool isActive) {
    return GestureDetector(
      onTap: _isPosting ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white, 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? Colors.black : Colors.grey[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.white : Colors.black),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.poppins(fontSize: 13, color: isActive ? Colors.white : Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
    String? badge,
  }) {
    return GestureDetector(
      onTap: _isPosting ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? Colors.black : Colors.grey[300]!),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: isActive ? Colors.white : Colors.black),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFb71000),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Center(
                    child: Text(
                      badge,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(int index) {
    final file = _selectedMedia[index];
    final type = _mediaTypes[index];

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: type == 'image'
                ? Image.file(file, fit: BoxFit.cover, width: 120, height: 120)
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(Iconsax.video, color: Colors.white, size: 32),
                    ),
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeMedia(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.close_circle, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductPicker() async {
    if (widget.storeId == null) return;

    try {
      // Fetch store products
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();

      final products = productsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (!mounted) return;

      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No products available to tag', style: GoogleFonts.poppins()),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[200]!,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600]!)),
                      ),
                      Text('Tag Products', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                      TextButton(
                        onPressed: () {
                          setState(() {}); // Update main UI
                          Navigator.pop(context);
                        },
                        child: Text('Done', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey[200]!),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final productId = product['id'];
                      final isTagged = _taggedProductIds.contains(productId);

                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            if (isTagged) {
                              _taggedProductIds.remove(productId);
                              _taggedProducts.removeWhere((p) => p['id'] == productId);
                            } else {
                              _taggedProductIds.add(productId);
                              _taggedProducts.add(product);
                            }
                          });
                        },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isTagged ? Colors.black.withOpacity(0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isTagged ? Colors.black : Colors.grey[200]!,
                            width: isTagged ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: () {
                                String? imageUrl;
                                
                                if (product['images'] != null && (product['images'] as List).isNotEmpty) {
                                  final firstImage = (product['images'] as List)[0];
                                  print('First image object: $firstImage');
                                  if (firstImage is Map && firstImage['url'] != null) {
                                    imageUrl = firstImage['url'].toString();
                                    print('Extracted URL: $imageUrl');
                                  }
                                }
                                
                                if (imageUrl != null && imageUrl.isNotEmpty) {
                                  print('Loading image: $imageUrl');
                                  return Image.network(
                                    imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Image error: $error');
                                      return Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[200],
                                        child: Icon(Iconsax.box, color: Colors.grey[400], size: 24),
                                      );
                                    },
                                  );
                                } else {
                                  print('No image URL found');
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[200],
                                    child: Icon(Iconsax.box, color: Colors.grey[400], size: 24),
                                  );
                                }
                              }(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'] ?? 'Unnamed Product',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'UGX ${product['price']?.toStringAsFixed(0) ?? '0'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isTagged)
                              const Icon(Iconsax.tick_circle, color: Colors.black, size: 24),
                          ],
                        ),
                      ),
                    );
                  },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
    }
  }

  void _removeProduct(String productId) {
    setState(() {
      _taggedProductIds.remove(productId);
      _taggedProducts.removeWhere((p) => p['id'] == productId);
    });
  }
}


// Story Card Widget
class _StoryCard extends StatelessWidget {
  final Map<String, dynamic> story;
  final StoriesService storiesService;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _StoryCard({
    required this.story,
    required this.storiesService,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = story['thumbnailUrl'] as String?;
    final mediaType = story['mediaType'] as String?;
    final expiresAt = story['expiresAt'] as Timestamp?;
    final timeRemaining = expiresAt != null ? storiesService.getTimeRemaining(expiresAt) : '';

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            if (thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(Iconsax.image, size: 48, color: Colors.grey[400]),
                    );
                  },
                ),
              )
            else
              Center(child: Icon(Iconsax.image, size: 48, color: Colors.grey[400])),
            
            // Video indicator
            if (mediaType == 'video')
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.play, color: Colors.white, size: 32),
                ),
              ),
            
            // Time remaining badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  timeRemaining,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            // Views count
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.eye, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${story['views'] ?? 0}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.trash, color: Colors.red),
              title: Text('Delete Story', style: GoogleFonts.poppins(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// Story Viewer Screen
class _StoryViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;
  final String storeName;
  final String? storeLogoUrl;
  final StoriesService storiesService;
  final String storeId;
  final Function(String storyId) onDelete;

  const _StoryViewerScreen({
    required this.stories,
    required this.initialIndex,
    required this.storeName,
    this.storeLogoUrl,
    required this.storiesService,
    required this.storeId,
    required this.onDelete,
  });

  @override
  State<_StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<_StoryViewerScreen> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    // Increment views for initial story
    widget.storiesService.incrementViews(
      widget.storeId,
      widget.stories[widget.initialIndex]['id'],
    );
    
    _progressController.addStatusListener(_onProgressComplete);
    _startProgress();
  }

  void _startProgress() {
    _progressController.forward();
  }

  void _onProgressComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _nextStory();
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
        _progressController.reset();
      });
      widget.storiesService.incrementViews(
        widget.storeId,
        widget.stories[_currentIndex]['id'],
      );
      _startProgress();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _progressController.reset();
      });
      _startProgress();
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _progressController.stop();
      } else {
        _progressController.forward();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final tapPosition = details.globalPosition.dx;
          
          if (tapPosition < screenWidth / 3) {
            // Tap on left third - previous story
            _previousStory();
          } else if (tapPosition > screenWidth * 2 / 3) {
            // Tap on right third - next story
            _nextStory();
          } else {
            // Tap in middle - pause/play
            _togglePause();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story content - full screen
            _buildStoryContent(story),
            
            // Progress bars at top
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(
                  widget.stories.length,
                  (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                      child: index < _currentIndex
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            )
                          : index == _currentIndex
                              ? AnimatedBuilder(
                                  animation: _progressController,
                                  builder: (context, child) {
                                    return FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: _progressController.value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(1.5),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : const SizedBox(),
                    ),
                  ),
                ),
              ),
            ),
            
            // Top bar with store info
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Store avatar
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: widget.storeLogoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                widget.storeLogoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      widget.storeName.isNotEmpty ? widget.storeName[0].toUpperCase() : 'S',
                                      style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                widget.storeName.isNotEmpty ? widget.storeName[0].toUpperCase() : 'S',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.storeName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            widget.storiesService.getTimeRemaining(
                              story['expiresAt'] as Timestamp,
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.9),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isPaused)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Iconsax.pause, color: Colors.white, size: 16),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Iconsax.more, color: Colors.white, size: 20),
                      onPressed: () {
                        _progressController.stop();
                        _showStoryOptions();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Iconsax.close_circle, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom info
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.eye, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '${story['views'] ?? 0} views',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(Map<String, dynamic> story) {
    final mediaUrl = story['mediaUrl'] as String?;

    if (mediaUrl == null) {
      return const Center(
        child: Icon(Iconsax.image, size: 64, color: Colors.white),
      );
    }

    return Center(
      child: Image.network(
        mediaUrl,
        fit: BoxFit.contain,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Iconsax.image, size: 64, color: Colors.white),
          );
        },
      ),
    );
  }

  void _showStoryOptions() {
    final currentStory = widget.stories[_currentIndex];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.trash, color: Colors.red),
              title: Text('Delete Story', style: GoogleFonts.poppins(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete(currentStory['id']);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).then((_) {
      // Resume progress when bottom sheet closes
      if (!_isPaused) {
        _progressController.forward();
      }
    });
  }
}
