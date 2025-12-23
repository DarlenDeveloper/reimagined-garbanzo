import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<_OnlineFriend> _onlineFriends = [
    _OnlineFriend(id: '1', name: 'vernadare', avatar: 'V', isOnline: true),
    _OnlineFriend(id: '2', name: 'nikizefanya', avatar: 'N', isOnline: true),
    _OnlineFriend(id: '3', name: 'zahiralian', avatar: 'Z', isOnline: true),
    _OnlineFriend(id: '4', name: 'sarah_m', avatar: 'S', isOnline: true),
    _OnlineFriend(id: '5', name: 'fatima_', avatar: 'F', isOnline: true),
  ];

  final List<_Conversation> _conversations = [
    _Conversation(
      id: '1',
      name: 'vernadare',
      avatar: 'V',
      lastMessage: 'Recently online, chat now!',
      time: '9:41 PM',
      isOnline: true,
      unreadCount: 0,
    ),
    _Conversation(
      id: '2',
      name: 'nikizefanya',
      avatar: 'N',
      lastMessage: 'Perfect! We can start with cardio and t...',
      time: '9:34 PM',
      isOnline: true,
      unreadCount: 0,
      isVerified: true,
    ),
    _Conversation(
      id: '3',
      name: 'trenton_cole49',
      avatar: 'T',
      lastMessage: 'Awesome 👍, will contact you soon!',
      time: 'Yesterday',
      unreadCount: 2,
    ),
    _Conversation(
      id: '4',
      name: 'liisaa',
      avatar: 'L',
      lastMessage: 'Got it! Thank you, Brian 🙏',
      time: 'Monday',
      unreadCount: 0,
    ),
    _Conversation(
      id: '5',
      name: 'kretyastudio',
      avatar: 'K',
      lastMessage: 'Mention you in story',
      time: 'Sunday',
      unreadCount: 6,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: context.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Iconsax.edit, color: context.textPrimaryColor),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: context.surfaceVariantColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(color: context.textPrimaryColor),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: GoogleFonts.poppins(
                    color: context.textSecondaryColor,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Iconsax.search_normal, size: 20, color: context.textSecondaryColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Online Friends Section
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 12),
            child: Text(
              'Online friends',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
          ),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _onlineFriends.length,
              itemBuilder: (context, index) => _buildOnlineFriend(_onlineFriends[index]),
            ),
          ),

          const SizedBox(height: 16),

          // Messages Section
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'Messages',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
          ),

          // Conversations List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _conversations.length,
              itemBuilder: (context, index) => _buildConversationTile(_conversations[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineFriend(_OnlineFriend friend) {
    final isDark = context.isDark;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _openChat(friend.name, friend.avatar),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isDark ? AppColors.darkSurfaceVariant : _getAvatarColor(friend.id),
                  child: Text(
                    friend.avatar,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.limeAccent : Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: context.surfaceColor, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 60,
              child: Text(
                friend.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: context.textPrimaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(_Conversation conversation) {
    final isDark = context.isDark;
    return GestureDetector(
      onTap: () => _openChat(conversation.name, conversation.avatar),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: isDark ? AppColors.darkSurfaceVariant : _getAvatarColor(conversation.id),
                  child: Text(
                    conversation.avatar,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.limeAccent : Colors.white,
                    ),
                  ),
                ),
                if (conversation.isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: context.surfaceColor, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Message Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        conversation.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: conversation.unreadCount > 0 ? FontWeight.w600 : FontWeight.w500,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      if (conversation.isVerified) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: context.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check, size: 8, color: context.isDark ? Colors.black : Colors.white),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: conversation.unreadCount > 0 
                          ? context.textPrimaryColor 
                          : context.textSecondaryColor,
                      fontWeight: conversation.unreadCount > 0 
                          ? FontWeight.w500 
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            // Time & Unread
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conversation.time,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: context.textSecondaryColor,
                  ),
                ),
                if (conversation.unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(String name, String avatar) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(userName: name, userAvatar: avatar),
      ),
    );
  }

  Color _getAvatarColor(String id) {
    final colors = [
      AppColors.darkGreen,
      const Color(0xFF4A1942),
      const Color(0xFF1E3A5F),
      const Color(0xFF5D4037),
      const Color(0xFF37474F),
    ];
    return colors[id.hashCode % colors.length];
  }
}

class _OnlineFriend {
  final String id;
  final String name;
  final String avatar;
  final bool isOnline;

  _OnlineFriend({
    required this.id,
    required this.name,
    required this.avatar,
    this.isOnline = false,
  });
}

class _Conversation {
  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final String time;
  final bool isOnline;
  final int unreadCount;
  final bool isVerified;

  _Conversation({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    this.isOnline = false,
    this.unreadCount = 0,
    this.isVerified = false,
  });
}
