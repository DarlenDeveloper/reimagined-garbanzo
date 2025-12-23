import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class SocialsScreen extends StatefulWidget {
  const SocialsScreen({super.key});

  @override
  State<SocialsScreen> createState() => _SocialsScreenState();
}

class _SocialsScreenState extends State<SocialsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<Map<String, dynamic>> _posts = [
    {'content': 'New arrivals just dropped! Check out our latest collection 🔥', 'likes': 245, 'comments': 42, 'shares': 18, 'views': 1250, 'time': '2h ago', 'image': true, 'isPremium': false, 'expires': '22h left'},
    {'content': 'Flash sale this weekend! Up to 50% off selected items 🛍️', 'likes': 528, 'comments': 89, 'shares': 156, 'views': 3420, 'time': '1d ago', 'image': true, 'isPremium': true, 'expires': '6d left'},
    {'content': 'Thank you for 1000 followers! 🎉 Stay tuned for exclusive deals', 'likes': 892, 'comments': 234, 'shares': 67, 'views': 4500, 'time': '3d ago', 'image': false, 'isPremium': false, 'expires': 'Expired'},
  ];

  final List<Map<String, dynamic>> _stories = [
    {'title': 'Add Story', 'isAdd': true},
    {'title': 'New Drop', 'views': 234, 'isAdd': false},
    {'title': 'Sale!', 'views': 567, 'isAdd': false},
    {'title': 'BTS', 'views': 123, 'isAdd': false},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      builder: (context) => _CreatePostSheet(onPost: (content, isPremium) {
        setState(() {
          _posts.insert(0, {
            'content': content,
            'likes': 0, 'comments': 0, 'shares': 0, 'views': 0,
            'time': 'Just now',
            'image': false,
            'isPremium': isPremium,
            'expires': isPremium ? '7d left' : '24h left',
          });
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      floatingActionButton: FloatingActionButton(onPressed: _showCreatePostSheet, backgroundColor: Colors.black, child: const Icon(Iconsax.add, color: Colors.white)),
      body: Column(
        children: [
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _miniStat('1.2K', 'Followers'),
                _miniStat('${_posts.length}', 'Posts'),
                _miniStat('8.5%', 'Engagement'),
                _miniStat('12.4K', 'Reach'),
              ],
            ),
          ),
          // Stories
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _stories.length,
              itemBuilder: (context, index) {
                final story = _stories[index];
                return _StoryItem(
                  title: story['title'],
                  views: story['views'],
                  isAdd: story['isAdd'] ?? false,
                  onTap: story['isAdd'] == true ? () => _showAddStorySheet() : null,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Tabs
          Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              tabs: const [Tab(text: 'Posts'), Tab(text: 'Scheduled')],
            ),
          ),
          // Posts
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsList(),
                _buildScheduledList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      itemBuilder: (context, index) => _PostCard(post: _posts[index], onTap: () => _showPostDetails(_posts[index])),
    );
  }

  Widget _buildScheduledList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.calendar, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No scheduled posts', style: GoogleFonts.poppins(color: Colors.grey[600])),
          const SizedBox(height: 8),
          TextButton(onPressed: _showCreatePostSheet, child: Text('Schedule a post', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  void _showInsights() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Insights', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(children: [_insightCard('Total Views', '24.5K', '+12%', Colors.blue), const SizedBox(width: 12), _insightCard('Engagement', '8.5%', '+3%', Colors.green)]),
            const SizedBox(height: 12),
            Row(children: [_insightCard('New Followers', '+156', 'This week', Colors.purple), const SizedBox(width: 12), _insightCard('Profile Visits', '892', '+24%', Colors.orange)]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _insightCard(String label, String value, String change, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
            Text(change, style: GoogleFonts.poppins(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showAddStorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Story', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            Row(
              children: [
                _storyOption(Iconsax.camera, 'Camera', Colors.blue),
                const SizedBox(width: 16),
                _storyOption(Iconsax.gallery, 'Gallery', Colors.purple),
                const SizedBox(width: 16),
                _storyOption(Iconsax.text, 'Text', Colors.orange),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _storyOption(IconData icon, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            ],
          ),
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
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Post Performance', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem(Iconsax.eye, '${post['views']}', 'Views'),
                _statItem(Iconsax.heart, '${post['likes']}', 'Likes'),
                _statItem(Iconsax.message, '${post['comments']}', 'Comments'),
                _statItem(Iconsax.send_2, '${post['shares']}', 'Shares'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _actionBtn(Iconsax.edit, 'Edit', () => Navigator.pop(context))),
                const SizedBox(width: 12),
                Expanded(child: _actionBtn(Iconsax.chart, 'Boost', () => Navigator.pop(context))),
                const SizedBox(width: 12),
                Expanded(child: _actionBtn(Iconsax.trash, 'Delete', () => Navigator.pop(context), isDestructive: true)),
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
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: isDestructive ? Colors.red.withAlpha(25) : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
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
}

class _StoryItem extends StatelessWidget {
  final String title;
  final int? views;
  final bool isAdd;
  final VoidCallback? onTap;

  const _StoryItem({required this.title, this.views, required this.isAdd, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isAdd ? Colors.grey[100] : Colors.black,
                shape: BoxShape.circle,
                border: isAdd ? Border.all(color: Colors.grey[300]!, width: 2, strokeAlign: BorderSide.strokeAlignOutside) : null,
                
              ),
              child: isAdd
                  ? const Icon(Iconsax.add, color: Colors.black)
                  : Center(child: Text(title[0], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20))),
            ),
            const SizedBox(height: 4),
            Text(title, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
            if (!isAdd) Text('${views} views', style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;

  const _PostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post['image'] == true)
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(child: Icon(Iconsax.image, size: 48, color: Colors.grey[400])),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (post['isPremium'] == true)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.purple.withAlpha(25), borderRadius: BorderRadius.circular(4)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.crown, size: 12, color: Colors.purple),
                              const SizedBox(width: 4),
                              Text('Premium', style: GoogleFonts.poppins(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: post['expires'] == 'Expired' ? Colors.grey.withAlpha(25) : Colors.orange.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(post['expires'], style: GoogleFonts.poppins(fontSize: 10, color: post['expires'] == 'Expired' ? Colors.grey : Colors.orange)),
                      ),
                      const Spacer(),
                      Text(post['time'], style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(post['content'], style: GoogleFonts.poppins(fontSize: 14, height: 1.4)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _engagementStat(Iconsax.eye, '${post['views']}'),
                      _engagementStat(Iconsax.heart, '${post['likes']}'),
                      _engagementStat(Iconsax.message, '${post['comments']}'),
                      _engagementStat(Iconsax.send_2, '${post['shares']}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _engagementStat(IconData icon, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  final Function(String content, bool isPremium) onPost;
  const _CreatePostSheet({required this.onPost});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _contentController = TextEditingController();
  bool _isPremium = false;
  bool _hasImage = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600]))),
                Text('Create Post', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: () {
                    if (_contentController.text.isNotEmpty) {
                      widget.onPost(_contentController.text, _isPremium);
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Post', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  height: 150,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: _contentController,
                    maxLines: 6,
                    decoration: InputDecoration.collapsed(hintText: "What's happening at your store?", hintStyle: GoogleFonts.poppins(color: Colors.grey[400])),
                    style: GoogleFonts.poppins(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _mediaBtn(Iconsax.image, 'Photo', () => setState(() => _hasImage = !_hasImage), _hasImage),
                    const SizedBox(width: 12),
                    _mediaBtn(Iconsax.video, 'Video', () {}, false),
                    const SizedBox(width: 12),
                    _mediaBtn(Iconsax.link, 'Link', () {}, false),
                  ],
                ),
                if (_hasImage) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Icon(Iconsax.gallery_add, size: 32, color: Colors.grey[400])),
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.purple.withAlpha(15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purple.withAlpha(50))),
                  child: Row(
                    children: [
                      const Icon(Iconsax.crown, color: Colors.purple, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Premium Post', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            Text('Visible for 7 days instead of 24h', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isPremium,
                        onChanged: (v) => setState(() => _isPremium = v),
                        activeTrackColor: Colors.purple.withAlpha(100),
                        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.purple : Colors.grey),
                      ),
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

  Widget _mediaBtn(IconData icon, String label, VoidCallback onTap, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isActive ? Colors.black : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isActive ? Colors.white : Colors.black),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.poppins(fontSize: 13, color: isActive ? Colors.white : Colors.black)),
            ],
          ),
        ),
      ),
    );
  }
}
