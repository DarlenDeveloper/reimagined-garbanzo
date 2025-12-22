import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import '../data/dummy_data.dart';
import '../models/models.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'store_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _likedPosts = {};
  final Set<String> _savedPosts = {};
  final Set<String> _followedVendors = {'vendor-1'};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar()),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = DummyData.socialPosts[index % DummyData.socialPosts.length];
                  return _buildPostCard(post);
                },
                childCount: DummyData.socialPosts.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('G', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
          ),
          const SizedBox(width: 8),
          Text('GlowCart', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
          const Spacer(),
          _buildHeaderIcon(Iconsax.search_normal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()))),
          const SizedBox(width: 16),
          _buildHeaderIcon(Iconsax.notification, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())), badge: 3),
          const SizedBox(width: 16),
          _buildHeaderIcon(Iconsax.message, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen())), badge: 5),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap, {int badge = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Icon(icon, size: 24, color: Colors.black),
          if (badge > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                child: Center(child: Text('$badge', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white))),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostCard(SocialPost post) {
    final isLiked = _likedPosts.contains(post.id);
    final isSaved = _savedPosts.contains(post.id);
    final isFollowing = _followedVendors.contains(post.vendorId);
    final vendor = DummyData.vendors.firstWhere((v) => v.id == post.vendorId, orElse: () => DummyData.vendors.first);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          GestureDetector(
            onTap: () => _openStoreProfile(post.vendorId, post.vendorName),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              child: Text(post.vendorName[0], style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
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
                      onTap: () => _openStoreProfile(post.vendorId, post.vendorName),
                      child: Text(post.vendorName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                    ),
                    if (vendor.isVerified) ...[
                      const SizedBox(width: 4),
                      _buildVerifiedBadge(vendor),
                    ],
                    const SizedBox(width: 6),
                    Text('· ${_getTimeAgo(post.createdAt)}', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
                    const Spacer(),
                    if (!isFollowing)
                      GestureDetector(
                        onTap: () => _toggleFollow(post.vendorId),
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
                Text(post.content, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black, height: 1.4)),
                // Promo/Discount badges
                if (post.hasDiscount || post.promoCode != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (post.hasDiscount && post.discountPercent != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.discount_shape, size: 14, color: Colors.black),
                              const SizedBox(width: 4),
                              Text('${post.discountPercent}% OFF', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black)),
                            ],
                          ),
                        ),
                      if (post.promoCode != null)
                        GestureDetector(
                          onTap: () => _copyPromoCode(post.promoCode!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(post.promoCode!, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black, letterSpacing: 0.5)),
                                const SizedBox(width: 4),
                                Icon(Iconsax.copy, size: 12, color: Colors.grey[600]),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                // Image placeholder (smaller, rounded)
                if (post.hasDiscount) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 160,
                      width: double.infinity,
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
                    ),
                  ),
                ],
                // Action buttons - like, save, share, DM
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      _buildActionBtn(isLiked ? Iconsax.heart5 : Iconsax.heart, '${post.likes + (isLiked ? 1 : 0)}', () => _toggleLike(post.id), isActive: isLiked),
                      const SizedBox(width: 24),
                      _buildActionBtn(isSaved ? Iconsax.archive_tick : Iconsax.archive_add, '', () => _toggleSave(post.id), isActive: isSaved),
                      const SizedBox(width: 24),
                      _buildActionBtn(Iconsax.share, '', () => _sharePost(post)),
                      const Spacer(),
                      _buildActionBtn(Iconsax.direct_send, '', () => _sendDM(post.vendorId, post.vendorName)),
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

  void _toggleLike(String postId) => setState(() => _likedPosts.contains(postId) ? _likedPosts.remove(postId) : _likedPosts.add(postId));
  void _toggleSave(String postId) => setState(() => _savedPosts.contains(postId) ? _savedPosts.remove(postId) : _savedPosts.add(postId));
  void _toggleFollow(String vendorId) => setState(() => _followedVendors.contains(vendorId) ? _followedVendors.remove(vendorId) : _followedVendors.add(vendorId));

  void _copyPromoCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Promo code "$code" copied!', style: GoogleFonts.poppins()), backgroundColor: Colors.black, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
  }

  void _sharePost(SocialPost post) {
    final shareText = '${post.vendorName}: ${post.content}${post.promoCode != null ? '\n\nUse code: ${post.promoCode}' : ''}${post.hasDiscount && post.discountPercent != null ? '\n${post.discountPercent}% OFF!' : ''}\n\nShop on GlowCart';
    Share.share(shareText);
  }

  void _sendDM(String vendorId, String vendorName) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen()));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Start a conversation with $vendorName', style: GoogleFonts.poppins()), backgroundColor: Colors.black, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
  }

  void _showMoreOptions(BuildContext ctx, SocialPost post) {
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

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }

  Widget _buildVerifiedBadge(Vendor vendor) {
    // Blue = standard verified, Gold = premium/top seller, Black = official/brand
    Color badgeColor;
    if (vendor.id == 'vendor-1') {
      badgeColor = const Color(0xFFFFD700); // Gold
    } else if (vendor.id == 'vendor-2') {
      badgeColor = const Color(0xFF1DA1F2); // Blue
    } else {
      badgeColor = Colors.black; // Black
    }
    
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
      child: Icon(Icons.check, size: 10, color: badgeColor == const Color(0xFFFFD700) ? Colors.black : Colors.white),
    );
  }
}
