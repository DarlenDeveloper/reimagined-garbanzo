import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';

class ChatDetailScreen extends StatefulWidget {
  final String userName;
  final String userAvatar;

  const ChatDetailScreen({
    super.key,
    required this.userName,
    required this.userAvatar,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showAttachments = false;

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: 'Hi Niki!',
      isMe: true,
      time: '9:32 PM',
    ),
    _ChatMessage(
      text: 'Are you coming to the gym later today?',
      isMe: true,
      time: '9:32 PM',
    ),
    _ChatMessage(
      text: "Hi Brian! Yeah, I'll be there around 5 PM. Do you want to join me?",
      isMe: false,
      time: '9:32 PM',
    ),
    _ChatMessage(
      text: 'I was thinking of doing a mix of cardio and strength training 💪. How about you?',
      isMe: true,
      time: '9:32 PM',
    ),
    _ChatMessage(
      text: 'I need to focus on my legs today. Maybe we can do strength exercises? 🏋️',
      isMe: false,
      time: '9:33 PM',
    ),
    _ChatMessage(
      text: 'Perfect! We can start with cardio and then move on to legs',
      isMe: true,
      time: '9:34 PM',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: context.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.darkGreen,
              child: Text(
                widget.userAvatar,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.limeAccent : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.userName,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Iconsax.video, color: context.textPrimaryColor),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Iconsax.call, color: context.textPrimaryColor),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Iconsax.more, color: context.textPrimaryColor),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Today',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: context.textSecondaryColor,
              ),
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),

          // Attachments Panel
          if (_showAttachments) _buildAttachmentsPanel(),

          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessage(_ChatMessage message) {
    final isDark = context.isDark;
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isMe 
                    ? context.primaryColor 
                    : (isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF5F5F5)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isMe ? 20 : 4),
                  bottomRight: Radius.circular(message.isMe ? 4 : 20),
                ),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: message.isMe ? (isDark ? Colors.black : Colors.white) : context.textPrimaryColor,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.time,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: context.textSecondaryColor,
                  ),
                ),
                if (message.isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Iconsax.tick_circle,
                    size: 14,
                    color: context.textSecondaryColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsPanel() {
    final attachments = [
      _AttachmentOption(icon: Iconsax.document, label: 'Document', color: context.primaryColor),
      _AttachmentOption(icon: Iconsax.camera, label: 'Camera', color: const Color(0xFFEF4444)),
      _AttachmentOption(icon: Iconsax.gallery, label: 'Gallery', color: const Color(0xFF8B5CF6)),
      _AttachmentOption(icon: Iconsax.microphone_2, label: 'Audio', color: const Color(0xFFF59E0B)),
      _AttachmentOption(icon: Iconsax.location, label: 'Location', color: const Color(0xFF22C55E)),
      _AttachmentOption(icon: Iconsax.profile_2user, label: 'Contact', color: context.primaryColor),
      _AttachmentOption(icon: Iconsax.chart, label: 'Polling', color: const Color(0xFF6366F1)),
      _AttachmentOption(icon: Iconsax.emoji_happy, label: 'GIF', color: const Color(0xFFEC4899)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return GestureDetector(
            onTap: () {},
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: attachment.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    attachment.icon,
                    color: attachment.color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  attachment.label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: this.context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    final isDark = context.isDark;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showAttachments = !_showAttachments),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _showAttachments ? context.primaryColor : context.surfaceVariantColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Iconsax.add,
                color: _showAttachments ? (isDark ? Colors.black : Colors.white) : context.textSecondaryColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.surfaceVariantColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.poppins(color: context.textPrimaryColor),
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  hintStyle: GoogleFonts.poppins(
                    color: context.textSecondaryColor,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.surfaceVariantColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Iconsax.microphone_2,
                color: context.textSecondaryColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Iconsax.send_1,
                color: isDark ? Colors.black : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(
        text: _messageController.text,
        isMe: true,
        time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} PM',
      ));
      _messageController.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}

class _ChatMessage {
  final String text;
  final bool isMe;
  final String time;

  _ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
  });
}

class _AttachmentOption {
  final IconData icon;
  final String label;
  final Color color;

  _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
  });
}
