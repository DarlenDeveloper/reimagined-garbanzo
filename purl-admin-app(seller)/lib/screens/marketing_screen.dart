import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text('Marketing', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Stats Overview
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Iconsax.magicpen, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Text('Guerrilla Marketing', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('AI-powered outreach to boost your sales', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStatItem('Reach', '12.4K', Iconsax.people),
                    const SizedBox(width: 16),
                    _buildStatItem('Conversions', '847', Iconsax.chart_success),
                    const SizedBox(width: 16),
                    _buildStatItem('ROI', '324%', Iconsax.trend_up),
                  ],
                ),
              ],
            ),
          ),
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              indicator: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Iconsax.sms, size: 16), SizedBox(width: 4), Text('SMS')])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Iconsax.sms_edit, size: 16), SizedBox(width: 4), Text('Email')])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Iconsax.call, size: 16), SizedBox(width: 4), Text('Calls')])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Iconsax.notification, size: 16), SizedBox(width: 4), Text('Push')])),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildSmsTab(), _buildEmailTab(), _buildCallsTab(), _buildPushTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            Text(label, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // SMS TAB - Manual
  Widget _buildSmsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Manual Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.user, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Text('Manual Campaign', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700])),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Quick Stats
          Row(
            children: [
              _buildQuickStat('Sent Today', '156', Iconsax.send_2),
              const SizedBox(width: 12),
              _buildQuickStat('Delivered', '148', Iconsax.tick_circle),
              const SizedBox(width: 12),
              _buildQuickStat('Responses', '23', Iconsax.message_text),
            ],
          ),
          const SizedBox(height: 24),
          // Compose SMS
          Text('Compose SMS', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildTextField('Recipients', 'Select customer segment or enter numbers', icon: Iconsax.people),
          const SizedBox(height: 12),
          _buildTextField('Message', 'Type your promotional message...', maxLines: 4, icon: Iconsax.message_text),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Characters: 0/160', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
              Row(
                children: [
                  _buildTemplateChip('Sale'),
                  const SizedBox(width: 8),
                  _buildTemplateChip('New Arrival'),
                  const SizedBox(width: 8),
                  _buildTemplateChip('Discount'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Send Button
          GestureDetector(
            onTap: () => _showSendConfirmation('SMS'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.send_1, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Send SMS Campaign', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Recent Campaigns
          Text('Recent SMS Campaigns', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildCampaignItem('Flash Sale Alert', '2,450 sent', '89% delivered', '2 hours ago', Iconsax.sms),
          _buildCampaignItem('Weekend Promo', '1,820 sent', '92% delivered', 'Yesterday', Iconsax.sms),
          _buildCampaignItem('New Product Launch', '3,100 sent', '87% delivered', '3 days ago', Iconsax.sms),
        ],
      ),
    );
  }

  // EMAIL TAB - AI Powered
  Widget _buildEmailTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.cpu, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text('AI-Powered', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // AI Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Iconsax.cpu, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Email Agent', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text('Automatically sends personalized emails', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Switch(value: true, onChanged: (_) {}, activeColor: Colors.black),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Quick Stats
          Row(
            children: [
              _buildQuickStat('Sent', '4,280', Iconsax.send_2),
              const SizedBox(width: 12),
              _buildQuickStat('Opened', '2,156', Iconsax.eye),
              const SizedBox(width: 12),
              _buildQuickStat('Clicked', '847', Iconsax.mouse),
            ],
          ),
          const SizedBox(height: 24),
          // AI Email Settings
          Text('AI Email Settings', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildAiSettingItem('Welcome Emails', 'Send to new subscribers', true),
          _buildAiSettingItem('Abandoned Cart', 'Remind customers about cart items', true),
          _buildAiSettingItem('Re-engagement', 'Win back inactive customers', true),
          _buildAiSettingItem('Product Recommendations', 'Personalized product suggestions', false),
          _buildAiSettingItem('Order Follow-up', 'Request reviews after delivery', true),
          const SizedBox(height: 24),
          // AI Prompt
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AI Email Tone', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              GestureDetector(
                onTap: () => _showEditPromptSheet('Email'),
                child: Text('Edit', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: Text(
              'Write friendly, professional emails that highlight product benefits. Use customer\'s name, mention their past purchases, and include a clear call-to-action.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700], height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          // Recent AI Emails
          Text('Recent AI Emails', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildEmailItem('Welcome to Purl!', 'john@email.com', '52% open rate', '1 hour ago'),
          _buildEmailItem('You left something behind...', 'sarah@email.com', 'Opened', '3 hours ago'),
          _buildEmailItem('Products you might love', 'mike@email.com', 'Clicked', 'Yesterday'),
        ],
      ),
    );
  }

  // CALLS TAB - AI Powered
  Widget _buildCallsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.cpu, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text('AI-Powered', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // AI Call Agent Status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Iconsax.call_calling, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Call Agent', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
                          Text('Outbound marketing calls', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Switch(value: true, onChanged: (_) {}, activeColor: Colors.black),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(Iconsax.call, color: Colors.grey[600], size: 18),
                      const SizedBox(width: 10),
                      Text('Assigned: ', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                      Text('+233 30 987 6543', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Quick Stats
          Row(
            children: [
              _buildQuickStat('Calls Made', '342', Iconsax.call_outgoing),
              const SizedBox(width: 12),
              _buildQuickStat('Answered', '287', Iconsax.call_received),
              const SizedBox(width: 12),
              _buildQuickStat('Converted', '89', Iconsax.shopping_cart),
            ],
          ),
          const SizedBox(height: 24),
          // AI Call Settings
          Text('AI Call Campaigns', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildAiSettingItem('Promotional Calls', 'Announce sales and offers', true),
          _buildAiSettingItem('Follow-up Calls', 'Check on recent purchases', true),
          _buildAiSettingItem('Win-back Calls', 'Re-engage dormant customers', false),
          _buildAiSettingItem('Survey Calls', 'Collect customer feedback', true),
          const SizedBox(height: 24),
          // Call Script
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AI Call Script', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              GestureDetector(
                onTap: () => _showEditPromptSheet('Call'),
                child: Text('Edit', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: Text(
              'Greet the customer warmly, introduce yourself as calling from the store. Mention any current promotions briefly. Ask if they have questions about products. Thank them for their time.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700], height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          // Recent Calls
          Text('Recent AI Calls', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildCallItem('+233 24 123 4567', 'Promotional - Flash Sale', '3:24', 'Interested', '30 min ago'),
          _buildCallItem('+233 50 987 6543', 'Follow-up - Order #1234', '2:15', 'Completed', '1 hour ago'),
          _buildCallItem('+233 27 456 7890', 'Promotional - New Arrivals', '1:45', 'Callback', '2 hours ago'),
        ],
      ),
    );
  }

  // PUSH TAB - Followers Only
  Widget _buildPushTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Followers Only Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.people, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text('Followers Only', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Followers Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Iconsax.people, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1,247', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 28)),
                      Text('Store Followers', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Iconsax.trend_up, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text('+48', style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Text('this week', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Quick Stats
          Row(
            children: [
              _buildQuickStat('Sent', '3,420', Iconsax.send_2),
              const SizedBox(width: 12),
              _buildQuickStat('Delivered', '3,156', Iconsax.tick_circle),
              const SizedBox(width: 12),
              _buildQuickStat('Opened', '2,847', Iconsax.eye),
            ],
          ),
          const SizedBox(height: 24),
          // Compose Push Notification
          Text('Send Push Notification', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildTextField('Title', 'Enter notification title', icon: Iconsax.text),
          const SizedBox(height: 12),
          _buildTextField('Message', 'Enter your message to followers...', maxLines: 3, icon: Iconsax.message_text),
          const SizedBox(height: 16),
          // Notification Type
          Text('Notification Type', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildNotificationTypeChip('Promotion', Iconsax.discount_shape, true),
              const SizedBox(width: 10),
              _buildNotificationTypeChip('New Arrival', Iconsax.box, false),
              const SizedBox(width: 10),
              _buildNotificationTypeChip('Flash Sale', Iconsax.flash_1, false),
            ],
          ),
          const SizedBox(height: 16),
          // Schedule Option
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Iconsax.clock, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Schedule for later', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
                      Text('Send at optimal time', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Switch(value: false, onChanged: (_) {}, activeColor: Colors.black),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Send Button
          GestureDetector(
            onTap: () => _showSendPushConfirmation(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.notification, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Send to 1,247 Followers', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Recent Push Notifications
          Text('Recent Push Notifications', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildPushItem('🔥 Flash Sale Alert!', 'Up to 50% off on all items', '1,180 opened', '2 hours ago'),
          _buildPushItem('✨ New Arrivals', 'Check out our latest collection', '956 opened', 'Yesterday'),
          _buildPushItem('🎁 Exclusive for You', 'Special discount code inside', '1,024 opened', '2 days ago'),
        ],
      ),
    );
  }

  Widget _buildNotificationTypeChip(String label, IconData icon, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 20),
              const SizedBox(height: 6),
              Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : Colors.grey[700])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPushItem(String title, String message, String opened, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Iconsax.notification, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(message, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
                child: Text(opened, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 4),
              Text(time, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  void _showSendPushConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Send Push Notification?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will send a push notification to all 1,247 followers of your store.', style: GoogleFonts.poppins(color: Colors.grey[600])),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Iconsax.people, size: 18),
                  const SizedBox(width: 8),
                  Text('1,247 followers will receive this', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600]))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Push notification sent to 1,247 followers!', style: GoogleFonts.poppins()),
                  backgroundColor: Colors.black,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Text('Send', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: Colors.black, size: 20),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {int maxLines = 1, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            prefixIcon: icon != null ? Icon(icon, color: Colors.grey[400], size: 20) : null,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateChip(String label) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700])),
      ),
    );
  }

  Widget _buildCampaignItem(String title, String sent, String delivered, String time, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('$sent • $delivered', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Text(time, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildAiSettingItem(String title, String subtitle, bool enabled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: (_) {}, activeColor: Colors.black),
        ],
      ),
    );
  }

  Widget _buildEmailItem(String subject, String recipient, String status, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Iconsax.sms_edit, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(recipient, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
                child: Text(status, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 4),
              Text(time, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCallItem(String phone, String campaign, String duration, String outcome, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Iconsax.call_outgoing, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(phone, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(campaign, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Iconsax.timer_1, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(duration, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
                child: Text(outcome, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSendConfirmation(String type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Send $type Campaign?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('This will send your message to the selected recipients.', style: GoogleFonts.poppins(color: Colors.grey[600])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600]))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$type campaign sent successfully!', style: GoogleFonts.poppins()),
                  backgroundColor: Colors.black,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Text('Send', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showEditPromptSheet(String type) {
    final controller = TextEditingController(
      text: type == 'Email'
          ? 'Write friendly, professional emails that highlight product benefits. Use customer\'s name, mention their past purchases, and include a clear call-to-action.'
          : 'Greet the customer warmly, introduce yourself as calling from the store. Mention any current promotions briefly. Ask if they have questions about products. Thank them for their time.',
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit AI $type Prompt', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                  GestureDetector(onTap: () => Navigator.pop(ctx), child: Icon(Iconsax.close_circle, color: Colors.grey[400])),
                ],
              ),
              const SizedBox(height: 8),
              Text('Customize how your AI agent communicates', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLines: 5,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter your AI prompt...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text('Save Changes', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
                ),
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}
