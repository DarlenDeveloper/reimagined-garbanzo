import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../data/dummy_data.dart';
import '../models/models.dart';
import '../theme/colors.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'story_view_screen.dart';
import 'store_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _likedPosts = {};
  final Set<String> _savedPosts = {};
  final Set<String> _followedVendors = {'vendor-1'};
  final Set<String> _expandedPosts = {};

  late AnimationController _storyAnimController;

  @override
  void initState() {
    super.initState();
    _storyAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _storyAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar()),
            SliverToBoxAdapter(child: _buildStoryBar()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = DummyData.socialPosts[index % DummyData.socialPosts.length];
                    return _buildPostCard(post, index);
                  },
                  childCount: DummyData.socialPosts.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset('assets/images/mainlogo.png', fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Text(
            'GlowCart',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.darkGreen,
            ),
          ),
          const Spacer(),
          _buildIconButton(
            icon: Iconsax.notification,
            badge: 3,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            ),
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: Iconsax.message,
            badge: 5,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MessagesScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    int badge = 0,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, size: 22, color: AppColors.darkGreen)),
            if (badge > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge > 9 ? '9+' : '$badge',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryBar() {
    final vendors = DummyData.vendors;
    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: vendors.length,
        itemBuilder: (context, index) => _buildStoryItem(vendors[index]),
      ),
    );
  }

  Widget _buildStoryItem(Vendor vendor) {
    final hasUnseenStory = vendor.id != 'vendor-3';
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _openStory(vendor),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _storyAnimController,
              builder: (context, child) {
                return Container(
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasUnseenStory
                        ? SweepGradient(
                            startAngle: _storyAnimController.value * 6.28,
                            colors: const [AppColors.darkGreen, Color(0xFF4A1942), AppColors.darkGreen],
                          )
                        : null,
                    color: !hasUnseenStory ? AppColors.surfaceVariant : null,
                  ),
                  child: child,
                );
              },
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  backgroundColor: _getVendorColor(vendor.id),
                  child: Text(
                    vendor.name[0],
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 72,
              child: Text(
                vendor.name.split(' ')[0],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openStory(Vendor vendor) {
    final stories = [
      StoryItem(title: '${vendor.name} Sale!', subtitle: 'Up to 50% off on selected items', emoji: '🔥', discount: '50% OFF', timeAgo: '2h ago', gradientColors: [_getVendorColor(vendor.id), _getVendorColor(vendor.id).withValues(alpha: 0.7)]),
      StoryItem(title: 'New Arrivals', subtitle: 'Check out our latest collection', emoji: '✨', timeAgo: '4h ago', gradientColors: [const Color(0xFF4A1942), const Color(0xFF1E3A5F)]),
      StoryItem(title: 'Free Shipping', subtitle: 'On orders over \$50', emoji: '🚚', timeAgo: '6h ago', gradientColors: [const Color(0xFF1E3A5F), AppColors.darkGreen]),
    ];
    Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewScreen(vendorName: vendor.name, vendorAvatar: vendor.name[0], stories: stories)));
  }

  void _openStoreProfile(String storeId, String storeName) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => StoreProfileScreen(storeId: storeId, storeName: storeName, storeAvatar: storeName[0])));
  }

  Widget _buildPostCard(SocialPost post, int index) {
    final isLiked = _likedPosts.contains(post.id);
    final isSaved = _savedPosts.contains(post.id);
    final isFollowing = _followedVendors.contains(post.vendorId);
    final isExpanded = _expandedPosts.contains(post.id);
    final vendor = DummyData.vendors.firstWhere(
      (v) => v.id == post.vendorId,
      orElse: () => DummyData.vendors.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _openStoreProfile(post.vendorId, post.vendorName),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.darkGreen, const Color(0xFF4A1942).withValues(alpha: 0.7)],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: _getVendorColor(post.vendorId),
                        child: Text(
                          post.vendorName[0],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openStoreProfile(post.vendorId, post.vendorName),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.vendorName,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            if (vendor.isVerified) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppColors.darkGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 8, color: Colors.white),
                              ),
                            ],
                          ],
                        ),
                      Row(
                        children: [
                          Text(
                            _getTimeAgo(post.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (post.postType != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getPostTypeColor(post.postType!).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getPostTypeLabel(post.postType!),
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: _getPostTypeColor(post.postType!),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      ],
                    ),
                  ),
                ),
                _buildFollowButton(post.vendorId, isFollowing),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showMoreOptions(context, post),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Iconsax.more, size: 20, color: context.textSecondaryColor),
                  ),
                ),
              ],
            ),
          ),

          // Post Image Area
          GestureDetector(
            onDoubleTap: () => _toggleLike(post.id),
            child: Stack(
              children: [
                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _getPostGradient(index),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Post content preview
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            post.content,
                            textAlign: TextAlign.center,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // Discount Badge
                      if (post.hasDiscount && post.discountPercent != null)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Iconsax.discount_shape, size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  '${post.discountPercent}% OFF',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Promo Code Badge
                      if (post.promoCode != null)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: GestureDetector(
                            onTap: () => _copyPromoCode(post.promoCode!),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: context.primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      post.promoCode!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: context.primaryColor,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Iconsax.copy, size: 16, color: context.textSecondaryColor),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Expires badge
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Iconsax.clock, size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                _getExpiresIn(post.expiresAt),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons Row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                _buildActionButton(
                  icon: isLiked ? Iconsax.like_15 : Iconsax.like_1,
                  isActive: isLiked,
                  activeColor: const Color(0xFFEF4444),
                  onTap: () => _toggleLike(post.id),
                ),
                const SizedBox(width: 4),
                _buildActionButton(
                  icon: Iconsax.message_text_1,
                  onTap: () {},
                ),
                const SizedBox(width: 4),
                _buildActionButton(
                  icon: Iconsax.send_2,
                  onTap: () {},
                ),
                const Spacer(),
                _buildActionButton(
                  icon: isSaved ? Iconsax.archive_tick : Iconsax.archive_add,
                  isActive: isSaved,
                  activeColor: AppColors.darkGreen,
                  onTap: () => _toggleSave(post.id),
                ),
              ],
            ),
          ),

          // Likes Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${post.likes + (isLiked ? 1 : 0)} likes',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
          ),

          // Expandable Caption
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedCrossFade(
                  firstChild: Text(
                    post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: context.textPrimaryColor,
                      height: 1.4,
                    ),
                  ),
                  secondChild: Text(
                    post.content,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: context.textPrimaryColor,
                      height: 1.4,
                    ),
                  ),
                  crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
                if (post.content.length > 80)
                  GestureDetector(
                    onTap: () => _toggleExpand(post.id),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        isExpanded ? 'less' : 'more',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // View Comments
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: GestureDetector(
              onTap: () {},
              child: Text(
                'View all ${post.comments} comments',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: context.textSecondaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFollowButton(String vendorId, bool isFollowing) {
    return GestureDetector(
      onTap: () => _toggleFollow(vendorId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isFollowing
              ? null
              : const LinearGradient(colors: [AppColors.darkGreen, Color(0xFF2D5A45)]),
          color: isFollowing ? AppColors.surfaceVariant : null,
          borderRadius: BorderRadius.circular(20),
          border: isFollowing ? Border.all(color: AppColors.surfaceVariant) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFollowing ? Iconsax.tick_circle : Iconsax.add,
              size: 14,
              color: isFollowing ? AppColors.darkGreen : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              isFollowing ? 'Following' : 'Follow',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isFollowing ? AppColors.darkGreen : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    bool isActive = false,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: AnimatedScale(
          scale: isActive ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Icon(
            icon,
            size: 26,
            color: isActive ? activeColor : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  void _toggleLike(String postId) {
    setState(() {
      if (_likedPosts.contains(postId)) {
        _likedPosts.remove(postId);
      } else {
        _likedPosts.add(postId);
      }
    });
  }

  void _toggleSave(String postId) {
    setState(() {
      if (_savedPosts.contains(postId)) {
        _savedPosts.remove(postId);
      } else {
        _savedPosts.add(postId);
      }
    });
  }

  void _toggleFollow(String vendorId) {
    setState(() {
      if (_followedVendors.contains(vendorId)) {
        _followedVendors.remove(vendorId);
      } else {
        _followedVendors.add(vendorId);
      }
    });
  }

  void _toggleExpand(String postId) {
    setState(() {
      if (_expandedPosts.contains(postId)) {
        _expandedPosts.remove(postId);
      } else {
        _expandedPosts.add(postId);
      }
    });
  }

  void _copyPromoCode(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Promo code "$code" copied!'),
        backgroundColor: context.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showMoreOptions(BuildContext ctx, SocialPost post) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(Iconsax.shop, 'Visit store'),
            _buildOptionTile(Iconsax.link, 'Copy link'),
            _buildOptionTile(Iconsax.flag, 'Report post'),
            _buildOptionTile(Iconsax.slash, 'Not interested'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: () => Navigator.pop(context),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _getExpiresIn(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inHours < 1) return '${diff.inMinutes}m left';
    if (diff.inHours < 24) return '${diff.inHours}h left';
    return '${diff.inDays}d left';
  }

  Color _getPostTypeColor(String type) {
    switch (type) {
      case 'promo':
        return const Color(0xFFEF4444);
      case 'restock':
        return AppColors.darkGreen;
      case 'new_arrival':
        return const Color(0xFF8B5CF6);
      case 'announcement':
        return AppColors.darkGreen;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getPostTypeLabel(String type) {
    switch (type) {
      case 'promo':
        return 'SALE';
      case 'restock':
        return 'RESTOCK';
      case 'new_arrival':
        return 'NEW';
      case 'announcement':
        return 'NEWS';
      default:
        return type.toUpperCase();
    }
  }

  Color _getVendorColor(String vendorId) {
    final colors = [
      AppColors.darkGreen,
      const Color(0xFF4A1942),
      const Color(0xFF2D5A45),
      const Color(0xFF1E3A5F),
    ];
    return colors[vendorId.hashCode % colors.length];
  }

  List<Color> _getPostGradient(int index) {
    final gradients = [
      [const Color(0xFF1B4332), const Color(0xFF2D5A45)],
      [const Color(0xFF4A1942), const Color(0xFF6B2D5C)],
      [const Color(0xFF1E3A5F), const Color(0xFF2D5478)],
      [const Color(0xFF5D4037), const Color(0xFF795548)],
      [const Color(0xFF37474F), const Color(0xFF546E7A)],
      [const Color(0xFF4A148C), const Color(0xFF7B1FA2)],
    ];
    return gradients[index % gradients.length];
  }
}
