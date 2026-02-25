import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/messages_service.dart';

class StoreChatScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  final String? storeLogoUrl;

  const StoreChatScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    this.storeLogoUrl,
  });

  @override
  State<StoreChatScreen> createState() => _StoreChatScreenState();
}

class _StoreChatScreenState extends State<StoreChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final MessagesService _messagesService = MessagesService();
  final ScrollController _scrollController = ScrollController();
  
  String? _conversationId;
  String? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _userId = user.uid);

    final conversationId = await _messagesService.getOrCreateConversation(
      storeId: widget.storeId,
      storeName: widget.storeName,
      storeLogoUrl: widget.storeLogoUrl,
      userId: user.uid,
      userName: user.displayName ?? 'User',
      userPhotoUrl: user.photoURL,
    );

    await _messagesService.markAsRead(
      conversationId: conversationId,
      userId: user.uid,
    );

    setState(() {
      _conversationId = conversationId;
      _isLoading = false;
    });
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
              backgroundColor: Colors.black,
              backgroundImage: widget.storeLogoUrl != null 
                  ? NetworkImage(widget.storeLogoUrl!) 
                  : null,
              child: widget.storeLogoUrl == null
                  ? Text(
                      widget.storeName.isNotEmpty ? widget.storeName[0] : 'S',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              widget.storeName,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _userId == null
              ? Center(
                  child: Text(
                    'Please sign in to chat',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _messagesService.getMessages(_conversationId!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: Colors.black),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Iconsax.message, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No messages yet',
                                    style: GoogleFonts.poppins(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }

                          final messages = snapshot.data!;
                          return ListView.builder(
                            controller: _scrollController,
                            reverse: true, // Show newest messages at bottom
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isMe = message['senderId'] == _userId;
                              final createdAt = message['createdAt'] as Timestamp?;
                              final time = createdAt != null
                                  ? _messagesService.getMessageTime(createdAt)
                                  : '';

                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isMe ? const Color(0xFFfb2a0a) : Colors.grey[100],
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(16),
                                            topRight: const Radius.circular(16),
                                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                                            bottomRight: Radius.circular(isMe ? 4 : 16),
                                          ),
                                        ),
                                        child: Text(
                                          message['text'] ?? '',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: isMe ? Colors.white : Colors.black,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        time,
                                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                                      ),
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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Colors.grey[200]!)),
                      ),
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
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () async {
                              if (_messageController.text.trim().isEmpty || _conversationId == null) return;

                              await _messagesService.sendMessage(
                                conversationId: _conversationId!,
                                senderId: _userId!,
                                text: _messageController.text.trim(),
                              );

                              _messageController.clear();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFFb71000),
                                shape: BoxShape.circle,
                              ),
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
}
