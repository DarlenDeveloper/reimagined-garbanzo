import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/messages_service.dart';
import '../services/store_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MessagesService _messagesService = MessagesService();
  final StoreService _storeService = StoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _selectedConversationId;
  String? _storeId;
  bool _isLoading = true;
  final Map<String, String> _userNameCache = {};
  String _searchQuery = '';
  List<Map<String, dynamic>>? _searchResults;

  @override
  void initState() {
    super.initState();
    _loadStoreId();
    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase().trim();
      if (query != _searchQuery) {
        setState(() {
          _searchQuery = query;
          _searchResults = null; // Clear old results immediately
        });
        if (_searchQuery.isNotEmpty) {
          _performSearch();
        }
      }
    });
  }

  Future<void> _performSearch() async {
    if (_storeId == null || _searchQuery.isEmpty) return;
    
    final searchQuery = _searchQuery.toLowerCase().trim(); // Use local variable
    
    final conversations = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: _storeId)
        .get();
    
    // Check if query changed while we were fetching
    if (searchQuery != _searchQuery.toLowerCase().trim()) return;
    
    List<Map<String, dynamic>> results = [];
    
    for (var convDoc in conversations.docs) {
      // Check again if query changed
      if (searchQuery != _searchQuery.toLowerCase().trim()) return;
      
      final conv = convDoc.data();
      conv['id'] = convDoc.id;
      
      // Get userName and resolve it if needed
      final userName = conv['userName']?.toString() ?? 'User';
      final userId = conv['userId']?.toString() ?? '';
      final resolvedName = _userNameCache[userId] ?? userName;
      
      bool foundMatch = false;
      
      // Search in name first
      if (resolvedName.toLowerCase().contains(searchQuery)) {
        foundMatch = true;
      }
      
      // If not found in name, search in all messages
      if (!foundMatch) {
        final messagesSnapshot = await _firestore
            .collection('conversations')
            .doc(convDoc.id)
            .collection('messages')
            .get();
        
        // Check again if query changed
        if (searchQuery != _searchQuery.toLowerCase().trim()) return;
        
        for (var msgDoc in messagesSnapshot.docs) {
          final msgText = msgDoc.data()['text']?.toString().toLowerCase() ?? '';
          if (msgText.contains(searchQuery)) {
            foundMatch = true;
            break;
          }
        }
      }
      
      if (foundMatch) {
        results.add(conv);
      }
    }
    
    // Only update if query hasn't changed
    if (searchQuery == _searchQuery.toLowerCase().trim()) {
      setState(() => _searchResults = results);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreId() async {
    final storeId = await _storeService.getUserStoreId();
    setState(() {
      _storeId = storeId;
      _isLoading = false;
    });
  }

  Future<String> _resolveUserName(String userId, String fallbackName) async {
    // Check cache first
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }

    String userName = fallbackName;

    // If fallback is "User", try to resolve from Firestore or Firebase Auth
    if (userName == 'User') {
      try {
        // Try Firestore users collection
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          // Try firstName first, then fall back to name
          if (userData?['firstName'] != null && userData!['firstName'].toString().isNotEmpty) {
            userName = userData['firstName'];
          } else if (userData?['name'] != null && userData!['name'].toString().isNotEmpty) {
            userName = userData['name'];
          }
        }
      } catch (e) {
        print('Error fetching user from Firestore: $e');
      }

      // If still "User", try Firebase Auth (only if it's the current user)
      if (userName == 'User') {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.uid == userId) {
          if (currentUser.displayName != null && currentUser.displayName!.isNotEmpty) {
            userName = currentUser.displayName!;
          } else if (currentUser.email != null && currentUser.email!.isNotEmpty) {
            userName = currentUser.email!.split('@')[0];
          }
        }
      }
    }

    // Cache the result
    _userNameCache[userId] = userName;
    return userName;
  }

  Future<String> _resolveAndUpdateUserName(String conversationId, String userId, String fallbackName) async {
    final resolvedName = await _resolveUserName(userId, fallbackName);
    
    // If we found a better name than "User", update the conversation document
    if (resolvedName != 'User' && fallbackName == 'User') {
      _messagesService.updateConversationUserName(conversationId, resolvedName);
    }
    
    return resolvedName;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _storeId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: Colors.black), onPressed: () => Navigator.pop(context)),
          title: Text('Messages', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
        ),
        body: const Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text('Messages', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Iconsax.scan_barcode, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: Row(
        children: [
          // Conversations List
          Container(
            width: MediaQuery.of(context).size.width > 600 ? 320 : MediaQuery.of(context).size.width,
            decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey[200]!))),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search conversations...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                      prefixIcon: Icon(Iconsax.search_normal, color: Colors.grey[400], size: 20),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                // Conversations
                Expanded(
                  child: _searchQuery.isNotEmpty && _searchResults != null
                      ? _buildSearchResults()
                      : StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _messagesService.getStoreConversations(_storeId!),
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
                                  ],
                                ),
                              );
                            }

                            final conversations = snapshot.data!;
                            return ListView.builder(
                              itemCount: conversations.length,
                              itemBuilder: (context, index) => _buildConversationItem(conversations[index]),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          // Chat Area (for larger screens)
          if (MediaQuery.of(context).size.width > 600)
            Expanded(
              child: _selectedConversationId != null
                  ? _buildChatArea()
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.message, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('Select a conversation', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 16)),
                        ],
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> conversation) {
    final isSelected = _selectedConversationId == conversation['id'];
    final userName = conversation['userName'] ?? 'User';
    final userId = conversation['userId'] ?? '';
    final conversationId = conversation['id'] ?? '';
    final userPhotoUrl = conversation['userPhotoUrl'] as String?;
    final lastMessage = conversation['lastMessage'] ?? '';
    final lastMessageTime = conversation['lastMessageTime'] as Timestamp?;
    final unreadCount = (conversation['unreadCount'] as Map<String, dynamic>?)?[_storeId] ?? 0;
    final timeAgo = lastMessageTime != null ? _messagesService.getTimeAgo(lastMessageTime) : '';

    return FutureBuilder<String>(
      future: _resolveAndUpdateUserName(conversationId, userId, userName),
      initialData: userName,
      builder: (context, snapshot) {
        final resolvedName = snapshot.data ?? userName;

        return GestureDetector(
          onTap: () {
            // Mark as read
            _messagesService.markAsRead(conversationId: conversation['id'], userId: _storeId!);
            
            if (MediaQuery.of(context).size.width > 600) {
              setState(() => _selectedConversationId = conversation['id']);
            } else {
              _openChatDetail(conversation);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.grey[100] : Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.black,
                  backgroundImage: userPhotoUrl != null && userPhotoUrl.isNotEmpty ? NetworkImage(userPhotoUrl) : null,
                  child: userPhotoUrl == null || userPhotoUrl.isEmpty
                      ? const Icon(Iconsax.user, color: Colors.white, size: 24)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(resolvedName, style: GoogleFonts.poppins(fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w500, fontSize: 14)),
                          Text(timeAgo, style: GoogleFonts.poppins(fontSize: 11, color: unreadCount > 0 ? Colors.black : Colors.grey[500])),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage,
                              style: GoogleFonts.poppins(fontSize: 13, color: unreadCount > 0 ? Colors.black : Colors.grey[600], fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.w400),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
                              child: Text('$unreadCount', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatArea() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _messagesService.getStoreConversations(_storeId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }

        final conversation = snapshot.data!.firstWhere(
          (c) => c['id'] == _selectedConversationId,
          orElse: () => {},
        );

        if (conversation.isEmpty) {
          return const Center(child: Text('Conversation not found'));
        }

        final userName = conversation['userName'] ?? 'User';
        final userId = conversation['userId'] ?? '';
        final userPhotoUrl = conversation['userPhotoUrl'] as String?;

        return FutureBuilder<String>(
          future: _resolveUserName(userId, userName),
          initialData: userName,
          builder: (context, nameSnapshot) {
            final resolvedName = nameSnapshot.data ?? userName;

            return Column(
              children: [
                // Chat Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.black,
                        backgroundImage: userPhotoUrl != null && userPhotoUrl.isNotEmpty ? NetworkImage(userPhotoUrl) : null,
                        child: userPhotoUrl == null || userPhotoUrl.isEmpty
                            ? const Icon(Iconsax.user, color: Colors.white, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(resolvedName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                            Text('Buyer', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Iconsax.more), onPressed: () => _showConversationOptions(conversation)),
                    ],
                  ),
                ),
                // Messages
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _messagesService.getMessages(_selectedConversationId!),
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
                            ],
                          ),
                        );
                      }

                      final messages = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) => _buildMessageBubble(messages[index]),
                      );
                    },
                  ),
                ),
                // Input
                _buildMessageInput(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['senderId'] == _storeId;
    final createdAt = message['createdAt'] as Timestamp?;
    final time = createdAt != null ? _messagesService.getMessageTime(createdAt) : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
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
  }

  Widget _buildMessageInput() {
    final messageController = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
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
            onTap: () async {
              if (messageController.text.trim().isEmpty || _selectedConversationId == null) return;
              
              await _messagesService.sendMessage(
                conversationId: _selectedConversationId!,
                senderId: _storeId!,
                text: messageController.text.trim(),
              );
              
              messageController.clear();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Iconsax.send_1, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showConversationOptions(Map<String, dynamic> conversation) {
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
              title: Text('Delete Conversation', style: GoogleFonts.poppins(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _messagesService.deleteConversation(conversation['id']);
                setState(() => _selectedConversationId = null);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openChatDetail(Map<String, dynamic> conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChatDetailScreen(
          conversation: conversation,
          storeId: _storeId!,
          messagesService: _messagesService,
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    if (_searchResults!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.search_normal, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No conversations found', style: GoogleFonts.poppins(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Try searching for a different name or message', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) => _buildConversationItem(_searchResults![index]),
    );
  }
}

class _ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> conversation;
  final String storeId;
  final MessagesService messagesService;

  const _ChatDetailScreen({
    required this.conversation,
    required this.storeId,
    required this.messagesService,
  });

  @override
  State<_ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<_ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _resolvedUserName;

  @override
  void initState() {
    super.initState();
    // Mark as read when opening
    widget.messagesService.markAsRead(
      conversationId: widget.conversation['id'],
      userId: widget.storeId,
    );
    _resolveUserName();
  }

  Future<void> _resolveUserName() async {
    final userName = widget.conversation['userName'] ?? 'User';
    final userId = widget.conversation['userId'] ?? '';

    if (userName == 'User' && userId.isNotEmpty) {
      try {
        // Try Firestore users collection
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData?['name'] != null && userData!['name'].toString().isNotEmpty) {
            setState(() => _resolvedUserName = userData['name']);
            return;
          }
        }
      } catch (e) {
        print('Error fetching user from Firestore: $e');
      }
    }

    setState(() => _resolvedUserName = userName);
  }

  @override
  Widget build(BuildContext context) {
    final userName = _resolvedUserName ?? widget.conversation['userName'] ?? 'User';
    final userPhotoUrl = widget.conversation['userPhotoUrl'] as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: Colors.black), onPressed: () => Navigator.pop(context)),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.black,
              backgroundImage: userPhotoUrl != null && userPhotoUrl.isNotEmpty ? NetworkImage(userPhotoUrl) : null,
              child: userPhotoUrl == null || userPhotoUrl.isEmpty
                  ? const Icon(Iconsax.user, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black)),
                Text('Buyer', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Iconsax.more, color: Colors.black), onPressed: _showOptions),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.messagesService.getMessages(widget.conversation['id']),
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
                    final isMe = message['senderId'] == widget.storeId;
                    final createdAt = message['createdAt'] as Timestamp?;
                    final time = createdAt != null ? widget.messagesService.getMessageTime(createdAt) : '';

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

    await widget.messagesService.sendMessage(
      conversationId: widget.conversation['id'],
      senderId: widget.storeId,
      text: _messageController.text.trim(),
    );

    _messageController.clear();
  }

  void _showOptions() {
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
              title: Text('Delete Conversation', style: GoogleFonts.poppins(color: Colors.red)),
              onTap: () async {
                await widget.messagesService.deleteConversation(widget.conversation['id']);
                if (mounted) {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.pop(context); // Close chat screen
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
