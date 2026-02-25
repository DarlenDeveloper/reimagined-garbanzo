import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/messages_service.dart';
import '../theme/colors.dart';
import 'chat_detail_screen.dart';
import 'qr_scanner_screen.dart';
import 'product_detail_screen.dart';

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
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFfb2a0a))), // Main red
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
              height: 48,
              decoration: BoxDecoration(
                color: context.surfaceVariantColor,
                borderRadius: BorderRadius.circular(24), // height / 2
              ),
              clipBehavior: Clip.antiAlias,
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
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  filled: false,
                ),
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild to filter conversations
                },
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
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFfb2a0a))); // Main red
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
                
                // Filter conversations offline based on search query
                final searchQuery = _searchController.text.toLowerCase().trim();
                final filteredConversations = searchQuery.isEmpty
                    ? conversations
                    : conversations.where((conv) {
                        final storeName = (conv['storeName'] ?? '').toString().toLowerCase();
                        final lastMessage = (conv['lastMessage'] ?? '').toString().toLowerCase();
                        return storeName.contains(searchQuery) || lastMessage.contains(searchQuery);
                      }).toList();
                
                if (filteredConversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.search_status, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty ? 'No conversations yet' : 'No results found',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          searchQuery.isEmpty ? 'Start chatting with stores' : 'Try a different search term',
                          style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredConversations.length,
                  itemBuilder: (context, index) => _buildConversationTile(filteredConversations[index]),
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
                      color: const Color(0xFFfb2a0a), // Main red
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
        builder: (context) => ChatScreen(
          conversationId: conversation['id'],
          storeName: conversation['storeName'] ?? 'Store',
          storeLogoUrl: conversation['storeLogoUrl'],
          userId: _userId!,
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String storeName;
  final String? storeLogoUrl;
  final String userId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.storeName,
    this.storeLogoUrl,
    required this.userId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final MessagesService _messagesService = MessagesService();
  final FocusNode _messageFocusNode = FocusNode();
  final ValueNotifier<bool> _hasTextNotifier = ValueNotifier<bool>(false);
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _storeProducts = [];
  List<Map<String, dynamic>> _taggedProducts = [];

  @override
  void initState() {
    super.initState();
    // Mark as read when opening
    _messagesService.markAsRead(
      conversationId: widget.conversationId,
      userId: widget.userId,
    );
    
    // Listen to text changes using ValueNotifier to avoid rebuilding entire widget
    _messageController.addListener(_onTextChanged);
    
    // Load store products
    _loadStoreProducts();
  }
  
  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    _hasTextNotifier.value = hasText;
  }
  
  Future<void> _loadStoreProducts() async {
    try {
      print('🔍 ConversationId: ${widget.conversationId}');
      print('🔍 UserId: ${widget.userId}');
      
      // Extract storeId from conversationId (format: storeId_userId or userId_storeId)
      final parts = widget.conversationId.split('_');
      print('🔍 Parts: $parts');
      
      if (parts.length < 2) {
        print('❌ Invalid conversationId format: ${widget.conversationId}');
        return;
      }
      
      // Try both parts to find which one is the storeId
      String? storeId;
      for (final part in parts) {
        if (part != widget.userId) {
          storeId = part;
          break;
        }
      }
      
      if (storeId == null) {
        print('❌ Could not extract storeId from conversationId: ${widget.conversationId}');
        return;
      }
      
      print('✅ Loading products for store: $storeId');
      
      // Try without filters first to see if there are any products
      final allProductsSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .limit(5)
          .get();
      
      print('📦 Total products in store: ${allProductsSnapshot.docs.length}');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .where('isActive', isEqualTo: true)
          .limit(50)
          .get();
      
      print('✅ Found ${snapshot.docs.length} active products');
      
      // Update products list without setState to avoid flicker
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
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();
    
    // Show bottom sheet like WhatsApp
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProductPickerSheet(),
    );
  }
  
  void _selectProduct(Map<String, dynamic> product) {
    // Add product to tagged list
    if (!_taggedProducts.any((p) => p['id'] == product['id'])) {
      setState(() => _taggedProducts.add(product));
    }
    
    // Close the bottom sheet
    Navigator.pop(context);
    
    // Focus back on text field
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _messagesService.getMessages(widget.conversationId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFfb2a0a))); // Main red
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
                  reverse: true, // Show newest at bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // Messages come oldest first, so reverse to show newest at bottom
                    final message = messages[messages.length - 1 - index];
                    final isMe = message['senderId'] == widget.userId;
                    final taggedProductIds = message['taggedProductIds'] as List<dynamic>?;
                    final hasTaggedProducts = taggedProductIds != null && taggedProductIds.isNotEmpty;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            // Message text bubble
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFFfb2a0a) : Colors.grey[100], // Main red for sent messages
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
                            
                            // Tagged products
                            if (hasTaggedProducts) ...[
                              const SizedBox(height: 6),
                              _buildTaggedProducts(taggedProductIds!.cast<String>()),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Message input
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
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(24),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: TextField(
                              controller: _messageController,
                              focusNode: _messageFocusNode,
                              style: GoogleFonts.poppins(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                filled: false,
                              ),
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
    
    // Clear tagged products without setState to avoid flicker
    if (_taggedProducts.isNotEmpty) {
      _taggedProducts.clear();
      // Only rebuild if there were tagged products
      if (mounted) setState(() {});
    }

    await _messagesService.sendMessage(
      conversationId: widget.conversationId,
      senderId: widget.userId,
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
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
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
          
          // Products list
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
  
  Widget _buildTaggedProducts(List<String> productIds) {
    // Extract storeId from conversationId
    final parts = widget.conversationId.split('_');
    String? storeId;
    for (final part in parts) {
      if (part != widget.userId) {
        storeId = part;
        break;
      }
    }
    
    if (storeId == null) return const SizedBox.shrink();
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchTaggedProducts(storeId, productIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final products = snapshot.data!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: products.map((product) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      productId: product['id'],
                      storeId: storeId!,
                      productName: product['name'],
                      storeName: widget.storeName,
                    ),
                  ),
                );
              },
              child: Container(
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
                    
                    // Arrow icon
                    Icon(Iconsax.arrow_right_3, size: 16, color: Colors.grey[600]),
                  ],
                ),
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
}
