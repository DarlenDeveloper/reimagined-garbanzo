import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedConversationId;

  final List<Map<String, dynamic>> _conversations = [
    {'id': '1', 'name': 'John Doe', 'avatar': 'J', 'lastMessage': 'Is the wireless earbuds still available?', 'time': '2 min ago', 'unread': 2, 'isOnline': true},
    {'id': '2', 'name': 'Sarah Williams', 'avatar': 'S', 'lastMessage': 'Thank you for the quick delivery!', 'time': '15 min ago', 'unread': 0, 'isOnline': true},
    {'id': '3', 'name': 'Mike Johnson', 'avatar': 'M', 'lastMessage': 'Can I get a discount on bulk orders?', 'time': '1 hour ago', 'unread': 1, 'isOnline': false},
    {'id': '4', 'name': 'Emily Brown', 'avatar': 'E', 'lastMessage': 'When will my order be shipped?', 'time': '3 hours ago', 'unread': 0, 'isOnline': false},
    {'id': '5', 'name': 'David Lee', 'avatar': 'D', 'lastMessage': 'Perfect! I will place the order now.', 'time': 'Yesterday', 'unread': 0, 'isOnline': false},
    {'id': '6', 'name': 'Lisa Chen', 'avatar': 'L', 'lastMessage': 'Do you have this in blue color?', 'time': 'Yesterday', 'unread': 0, 'isOnline': true},
  ];

  final List<Map<String, dynamic>> _messages = [
    {'id': '1', 'text': 'Hi! I saw your wireless earbuds listing.', 'isMe': false, 'time': '10:30 AM'},
    {'id': '2', 'text': 'Hello! Yes, how can I help you?', 'isMe': true, 'time': '10:31 AM'},
    {'id': '3', 'text': 'Is the wireless earbuds still available?', 'isMe': false, 'time': '10:32 AM'},
    {'id': '4', 'text': 'Yes, we have 15 units in stock right now.', 'isMe': true, 'time': '10:33 AM'},
    {'id': '5', 'text': 'Great! What colors do you have?', 'isMe': false, 'time': '10:34 AM'},
    {'id': '6', 'text': 'We have Black, White, and Navy Blue available.', 'isMe': true, 'time': '10:35 AM'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text('Messages', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Iconsax.search_normal, color: Colors.black), onPressed: () {}),
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
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) => _buildConversationItem(_conversations[index]),
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
    return GestureDetector(
      onTap: () {
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
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.black,
                  child: Text(conversation['avatar'], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                ),
                if (conversation['isOnline'])
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(conversation['name'], style: GoogleFonts.poppins(fontWeight: conversation['unread'] > 0 ? FontWeight.w600 : FontWeight.w500, fontSize: 14)),
                      Text(conversation['time'], style: GoogleFonts.poppins(fontSize: 11, color: conversation['unread'] > 0 ? Colors.black : Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation['lastMessage'],
                          style: GoogleFonts.poppins(fontSize: 13, color: conversation['unread'] > 0 ? Colors.black : Colors.grey[600], fontWeight: conversation['unread'] > 0 ? FontWeight.w500 : FontWeight.w400),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation['unread'] > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
                          child: Text('${conversation['unread']}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
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

  Widget _buildChatArea() {
    final conversation = _conversations.firstWhere((c) => c['id'] == _selectedConversationId);
    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
          child: Row(
            children: [
              CircleAvatar(radius: 20, backgroundColor: Colors.black, child: Text(conversation['avatar'], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(conversation['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(conversation['isOnline'] ? 'Online' : 'Offline', style: GoogleFonts.poppins(fontSize: 12, color: conversation['isOnline'] ? Colors.green : Colors.grey[500])),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Iconsax.call), onPressed: () {}),
              IconButton(icon: const Icon(Iconsax.more), onPressed: () {}),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
          ),
        ),
        // Input
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    return Align(
      alignment: message['isMe'] ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
        child: Column(
          crossAxisAlignment: message['isMe'] ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message['isMe'] ? Colors.black : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message['isMe'] ? 16 : 4),
                  bottomRight: Radius.circular(message['isMe'] ? 4 : 16),
                ),
              ),
              child: Text(message['text'], style: GoogleFonts.poppins(fontSize: 14, color: message['isMe'] ? Colors.white : Colors.black)),
            ),
            const SizedBox(height: 4),
            Text(message['time'], style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
              child: const Icon(Iconsax.add, color: Colors.black, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
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
            onTap: () {},
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

  void _openChatDetail(Map<String, dynamic> conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _ChatDetailScreen(conversation: conversation, messages: _messages)),
    );
  }
}

class _ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> conversation;
  final List<Map<String, dynamic>> messages;

  const _ChatDetailScreen({required this.conversation, required this.messages});

  @override
  State<_ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<_ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  late List<Map<String, dynamic>> _messages;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.messages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: Colors.black), onPressed: () => Navigator.pop(context)),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(radius: 18, backgroundColor: Colors.black, child: Text(widget.conversation['avatar'], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
                if (widget.conversation['isOnline'])
                  Positioned(bottom: 0, right: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.conversation['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black)),
                Text(widget.conversation['isOnline'] ? 'Online' : 'Offline', style: GoogleFonts.poppins(fontSize: 11, color: widget.conversation['isOnline'] ? Colors.green : Colors.grey[500])),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Iconsax.call, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Iconsax.more, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message['isMe'] ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Column(
                      crossAxisAlignment: message['isMe'] ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: message['isMe'] ? Colors.black : Colors.grey[100],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(message['isMe'] ? 16 : 4),
                              bottomRight: Radius.circular(message['isMe'] ? 4 : 16),
                            ),
                          ),
                          child: Text(message['text'], style: GoogleFonts.poppins(fontSize: 14, color: message['isMe'] ? Colors.white : Colors.black)),
                        ),
                        const SizedBox(height: 4),
                        Text(message['time'], style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
            child: Row(
              children: [
                GestureDetector(onTap: () {}, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)), child: const Icon(Iconsax.add, color: Colors.black, size: 22))),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(hintText: 'Type a message...', hintStyle: GoogleFonts.poppins(color: Colors.grey[400]), filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)), child: const Icon(Iconsax.send_1, color: Colors.white, size: 20)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({'id': '${_messages.length + 1}', 'text': _messageController.text, 'isMe': true, 'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}'});
      _messageController.clear();
    });
  }
}
