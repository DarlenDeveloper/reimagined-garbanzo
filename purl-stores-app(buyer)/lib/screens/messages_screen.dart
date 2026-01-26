import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/messages_service.dart';
import '../theme/colors.dart';
import 'chat_detail_screen.dart';
import 'qr_scanner_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MessagesService _messagesService = MessagesService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final user = _auth.currentUser;
    setState(() {
      _userId = user?.uid;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _userId == null) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          backgroundColor: context.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Iconsax.arrow_left, color: context.textPrimaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Messages', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        ),
        body: const Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

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
            icon: Icon(Iconsax.scan_barcode, color: context.textPrimaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QRScannerScreen()),
              );
            },
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

          // Messages Section
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
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
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesService.getUserConversations(_userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.message, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No conversations yet', style: GoogleFonts.poppins(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text('Start chatting with stores', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13)),
                      ],
                    ),
                  );
                }

                final conversations = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) => _buildConversationTile(conversations[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    final isDark = context.isDark;
    final storeName = conversation['storeName'] ?? 'Store';
    final storeLogoUrl = conversation['storeLogoUrl'] as String?;
    final lastMessage = conversation['lastMessage'] ?? '';
    final lastMessageTime = conversation['lastMessageTime'] as Timestamp?;
    final unreadCount = (conversation['unreadCount'] as Map<String, dynamic>?)?[_userId] ?? 0;
    final timeAgo = lastMessageTime != null ? _messagesService.getTimeAgo(lastMessageTime) : '';

    return GestureDetector(
      onTap: () {
        // Mark as read in background (don't await)
        _messagesService.markAsRead(conversationId: conversation['id'], userId: _userId!);
        // Open chat immediately
        _openChat(conversation);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: isDark ? AppColors.darkSurfaceVariant : Colors.grey[200],
              backgroundImage: storeLogoUrl != null && storeLogoUrl.isNotEmpty ? NetworkImage(storeLogoUrl) : null,
              child: storeLogoUrl == null || storeLogoUrl.isEmpty
                  ? Icon(Iconsax.shop, size: 24, color: isDark ? AppColors.limeAccent : Colors.grey[600])
                  : null,
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
                        storeName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w500,
                          color: context.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: unreadCount > 0 
                          ? context.textPrimaryColor 
                          : context.textSecondaryColor,
                      fontWeight: unreadCount > 0 
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
                  timeAgo,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: context.textSecondaryColor,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
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

  void _openChat(Map<String, dynamic> conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ChatScreen(
          conversationId: conversation['id'],
          storeName: conversation['storeName'] ?? 'Store',
          storeLogoUrl: conversation['storeLogoUrl'],
          userId: _userId!,
        ),
      ),
    );
  }
}

class _ChatScreen extends StatefulWidget {
  final String conversationId;
  final String storeName;
  final String? storeLogoUrl;
  final String userId;

  const _ChatScreen({
    required this.conversationId,
    required this.storeName,
    this.storeLogoUrl,
    required this.userId,
  });

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final MessagesService _messagesService = MessagesService();

  @override
  void initState() {
    super.initState();
    // Mark as read when opening
    _messagesService.markAsRead(
      conversationId: widget.conversationId,
      userId: widget.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              backgroundImage: widget.storeLogoUrl != null && widget.storeLogoUrl!.isNotEmpty
                  ? NetworkImage(widget.storeLogoUrl!)
                  : null,
              child: widget.storeLogoUrl == null || widget.storeLogoUrl!.isEmpty
                  ? Icon(Iconsax.shop, size: 18, color: Colors.grey[600])
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.storeName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black)),
                Text('Store', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.message, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No messages yet', style: GoogleFonts.poppins(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text('Start the conversation', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13)),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == widget.userId;
                    final createdAt = message['createdAt'] as Timestamp?;
                    final time = createdAt != null ? _messagesService.getMessageTime(createdAt) : '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.black : Colors.grey[100],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                              ),
                              child: Text(message['text'] ?? '', style: GoogleFonts.poppins(fontSize: 14, color: isMe ? Colors.white : Colors.black)),
                            ),
                            const SizedBox(height: 4),
                            Text(time, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Iconsax.send_1, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await _messagesService.sendMessage(
      conversationId: widget.conversationId,
      senderId: widget.userId,
      text: _messageController.text.trim(),
    );

    _messageController.clear();
  }
}
