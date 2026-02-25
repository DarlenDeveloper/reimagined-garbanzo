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
  final TextEditingController _messageController = TextEditingController();
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
    _messageController.dispose();
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
          leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: const Color(0xFFfb2a0a)), onPressed: () => Navigator.pop(context)),
          title: Text('Messages', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
        ),
        body: const Center(child: CircularProgressIndicator(color: const Color(0xFFfb2a0a))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: const Color(0xFFfb2a0a)), onPressed: () => Navigator.pop(context)),
        title: Text('Messages', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Iconsax.scan_barcode, color: const Color(0xFFfb2a0a)), onPressed: () {}),
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
                              return const Center(child: CircularProgressIndicator(color: const Color(0xFFfb2a0a)));
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
                  backgroundColor: const Color(0xFFfb2a0a),
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
                          Text(timeAgo, style: GoogleFonts.poppins(fontSize: 11, color: unreadCount > 0 ? const Color(0xFFfb2a0a) : Colors.grey[500])),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage,
                              style: GoogleFonts.poppins(fontSize: 13, color: unreadCount > 0 ? const Color(0xFFfb2a0a) : Colors.grey[600], fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.w400),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFfb2a0a), borderRadius: BorderRadius.circular(10)),
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
          return const Center(child: CircularProgressIndicator(color: const Color(0xFFfb2a0a)));
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
                        backgroundColor: const Color(0xFFfb2a0a),
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
                        return const Center(child: CircularProgressIndicator(color: const Color(0xFFfb2a0a)));
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
    final taggedProductIds = message['taggedProductIds'] as List<dynamic>?;
    final hasTaggedProducts = taggedProductIds != null && taggedProductIds.isNotEmpty;

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
                color: isMe ? const Color(0xFFfb2a0a) : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Text(message['text'] ?? '', style: GoogleFonts.poppins(fontSize: 14, color: isMe ? Colors.white : Colors.black)),
            ),
            
            // Tagged products
            if (hasTaggedProducts) ...[
              const SizedBox(height: 6),
              _buildTaggedProducts(taggedProductIds!.cast<String>()),
            ],
            
            const SizedBox(height: 4),
            Text(time, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTaggedProducts(List<String> productIds) {
    if (_storeId == null) return const SizedBox.shrink();
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchTaggedProducts(_storeId!, productIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final products = snapshot.data!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: products.map((product) {
            return Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  // Product image
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: product['imageUrl'] != null && product['imageUrl'].isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product['imageUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Iconsax.box, size: 24, color: Colors.grey[400]);
                              },
                            ),
                          )
                        : Icon(Iconsax.box, size: 24, color: Colors.grey[400]),
                  ),
                  const SizedBox(width: 10),
                  
                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] ?? 'Product',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${product['currency'] ?? 'UGX'} ${(product['price'] ?? 0.0).toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFFfb2a0a),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tag icon
                  Icon(Iconsax.tag, size: 16, color: Colors.grey[600]),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
  
  Future<List<Map<String, dynamic>>> _fetchTaggedProducts(String storeId, List<String> productIds) async {
    try {
      final List<Map<String, dynamic>> products = [];
      
      for (final productId in productIds) {
        final doc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(storeId)
            .collection('products')
            .doc(productId)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          final imageUrl = data['images'] != null && (data['images'] as List).isNotEmpty
              ? (data['images'] as List)[0]['url'] ?? ''
              : '';
          
          products.add({
            'id': doc.id,
            'name': data['name'],
            'price': data['price'],
            'currency': data['currency'],
            'imageUrl': imageUrl,
          });
        }
      }
      
      return products;
    } catch (e) {
      print('❌ Error fetching tagged products: $e');
      return [];
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
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
            onTap: () async {
              if (_messageController.text.trim().isEmpty || _selectedConversationId == null) return;
              
              final messageText = _messageController.text.trim();
              _messageController.clear();
              
              await _messagesService.sendMessage(
                conversationId: _selectedConversationId!,
                senderId: _storeId!,
                text: messageText,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFb71000), borderRadius: BorderRadius.circular(12)),
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
      return const Center(child: CircularProgressIndicator(color: const Color(0xFFfb2a0a)));
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
  final FocusNode _messageFocusNode = FocusNode();
  final ValueNotifier<bool> _hasTextNotifier = ValueNotifier<bool>(false);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  String? _resolvedUserName;
  List<Map<String, dynamic>> _storeProducts = [];
  List<Map<String, dynamic>> _taggedProducts = [];

  @override
  void initState() {
    super.initState();
    // Mark as read when opening
    widget.messagesService.markAsRead(
      conversationId: widget.conversation['id'],
      userId: widget.storeId,
    );
    _resolveUserName();
    _messageController.addListener(_onTextChanged);
    _loadStoreProducts();
  }
  
  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    _hasTextNotifier.value = hasText;
  }
  
  Future<void> _loadStoreProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('products')
          .where('isActive', isEqualTo: true)
          .limit(50)
          .get();
      
      _storeProducts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error loading products: $e');
    }
  }
  
  void _showProductPickerOverlay() {
    FocusScope.of(context).unfocus();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProductPickerSheet(),
    );
  }
  
  void _selectProduct(Map<String, dynamic> product) {
    if (!_taggedProducts.any((p) => p['id'] == product['id'])) {
      setState(() => _taggedProducts.add(product));
    }
    Navigator.pop(context);
    _messageFocusNode.requestFocus();
  }
  
  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _messageFocusNode.dispose();
    _hasTextNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
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
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: const Color(0xFFfb2a0a)), onPressed: () => Navigator.pop(context)),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFfb2a0a),
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
          IconButton(icon: const Icon(Iconsax.more, color: const Color(0xFFfb2a0a)), onPressed: _showOptions),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: widget.messagesService.getMessages(widget.conversation['id']),
                builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: const Color(0xFFfb2a0a)));
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
                
                // Auto-scroll to bottom when messages change
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == widget.storeId;
                    final createdAt = message['createdAt'] as Timestamp?;
                    final time = createdAt != null ? widget.messagesService.getMessageTime(createdAt) : '';
                    final taggedProductIds = message['taggedProductIds'] as List<dynamic>?;
                    final hasTaggedProducts = taggedProductIds != null && taggedProductIds.isNotEmpty;

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
                                color: isMe ? const Color(0xFFfb2a0a) : Colors.grey[100],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                              ),
                              child: Text(message['text'] ?? '', style: GoogleFonts.poppins(fontSize: 14, color: isMe ? Colors.white : Colors.black)),
                            ),
                            
                            // Tagged products
                            if (hasTaggedProducts) ...[
                              const SizedBox(height: 6),
                              _buildTaggedProductsDetail(taggedProductIds!.cast<String>()),
                            ],
                            
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
            child: Column(
              children: [
                // Tagged products preview
                if (_taggedProducts.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _taggedProducts.map((product) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFfb2a0a).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFfb2a0a).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.tag, size: 12, color: const Color(0xFFfb2a0a)),
                              const SizedBox(width: 4),
                              Text(
                                product['name'] ?? 'Product',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFfb2a0a),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  setState(() => _taggedProducts.removeWhere((p) => p['id'] == product['id']));
                                },
                                child: Icon(Icons.close, size: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                
                // Message input row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
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
                    // Tag or Send button
                    ValueListenableBuilder<bool>(
                      valueListenable: _hasTextNotifier,
                      builder: (context, hasText, child) {
                        return GestureDetector(
                          onTap: hasText ? _sendMessage : _showProductPickerOverlay,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFb71000),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              hasText ? Icons.arrow_upward_rounded : Iconsax.tag,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        );
                      },
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
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    final taggedIds = _taggedProducts.map((p) => p['id'] as String).toList();
    
    _messageController.clear();
    
    if (_taggedProducts.isNotEmpty) {
      _taggedProducts.clear();
      if (mounted) setState(() {});
    }

    await widget.messagesService.sendMessage(
      conversationId: widget.conversation['id'],
      senderId: widget.storeId,
      text: messageText,
      taggedProductIds: taggedIds,
    );
  }
  
  Widget _buildProductPickerSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFfb2a0a),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Iconsax.tag, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  'Tag a Product',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: Colors.grey[200]),
          
          Expanded(
            child: _storeProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.box, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No products available',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _storeProducts.length,
                    itemBuilder: (context, index) {
                      final product = _storeProducts[index];
                      final imageUrl = product['images'] != null && (product['images'] as List).isNotEmpty
                          ? (product['images'] as List)[0]['url'] ?? ''
                          : '';
                      final isSelected = _taggedProducts.any((p) => p['id'] == product['id']);
                      
                      return ListTile(
                        onTap: () => _selectProduct(product),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Iconsax.box, size: 24, color: Colors.grey[400]);
                                    },
                                  ),
                                )
                              : Icon(Iconsax.box, size: 24, color: Colors.grey[400]),
                        ),
                        title: Text(
                          product['name'] ?? 'Product',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${product['currency'] ?? 'UGX'} ${(product['price'] ?? 0.0).toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFFfb2a0a),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Iconsax.tick_circle5,
                                color: Color(0xFFfb2a0a),
                                size: 24,
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
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
  
  Widget _buildTaggedProductsDetail(List<String> productIds) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchTaggedProductsDetail(productIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final products = snapshot.data!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: products.map((product) {
            return Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  // Product image
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: product['imageUrl'] != null && product['imageUrl'].isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product['imageUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Iconsax.box, size: 24, color: Colors.grey[400]);
                              },
                            ),
                          )
                        : Icon(Iconsax.box, size: 24, color: Colors.grey[400]),
                  ),
                  const SizedBox(width: 10),
                  
                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] ?? 'Product',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${product['currency'] ?? 'UGX'} ${(product['price'] ?? 0.0).toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFFfb2a0a),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tag icon
                  Icon(Iconsax.tag, size: 16, color: Colors.grey[600]),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
  
  Future<List<Map<String, dynamic>>> _fetchTaggedProductsDetail(List<String> productIds) async {
    try {
      final List<Map<String, dynamic>> products = [];
      
      for (final productId in productIds) {
        final doc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(widget.storeId)
            .collection('products')
            .doc(productId)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          final imageUrl = data['images'] != null && (data['images'] as List).isNotEmpty
              ? (data['images'] as List)[0]['url'] ?? ''
              : '';
          
          products.add({
            'id': doc.id,
            'name': data['name'],
            'price': data['price'],
            'currency': data['currency'],
            'imageUrl': imageUrl,
          });
        }
      }
      
      return products;
    } catch (e) {
      print('❌ Error fetching tagged products: $e');
      return [];
    }
  }
}
