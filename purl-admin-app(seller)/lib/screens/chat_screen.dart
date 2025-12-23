import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _agentActive = true;
  final TextEditingController _promptController = TextEditingController(
    text: 'You are a helpful customer service agent for our store. Help customers with order inquiries, product questions, returns, and general support. Be friendly, professional, and concise.',
  );

  final List<Map<String, dynamic>> _callHistory = [
    {'phone': '+233 24 123 4567', 'summary': 'Customer inquired about order #GC-1245 delivery status. Provided tracking information and estimated delivery date.', 'date': 'Dec 22, 2024', 'time': '10:32 AM', 'duration': '4:23', 'resolved': true},
    {'phone': '+233 50 987 6543', 'summary': 'Refund request for damaged item. Escalated to human agent for approval.', 'date': 'Dec 22, 2024', 'time': '09:15 AM', 'duration': '6:45', 'resolved': false},
    {'phone': '+233 27 456 7890', 'summary': 'Product availability check for Wireless Earbuds. Confirmed stock and provided purchase link.', 'date': 'Dec 21, 2024', 'time': '03:45 PM', 'duration': '2:12', 'resolved': true},
    {'phone': '+233 24 111 2222', 'summary': 'Payment issue - card declined. Guided customer through alternative payment methods.', 'date': 'Dec 21, 2024', 'time': '11:20 AM', 'duration': '5:30', 'resolved': true},
    {'phone': '+233 55 333 4444', 'summary': 'Complaint about late delivery. Apologized and offered discount code for next purchase.', 'date': 'Dec 20, 2024', 'time': '02:10 PM', 'duration': '7:15', 'resolved': true},
    {'phone': '+233 20 555 6666', 'summary': 'Return policy inquiry. Explained 30-day return policy and process.', 'date': 'Dec 20, 2024', 'time': '10:05 AM', 'duration': '3:45', 'resolved': true},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promptController.dispose();
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
        title: Text('AI Customer Care', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
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
              tabs: const [Tab(text: 'Agent Management'), Tab(text: 'Call History')],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildAgentManagementTab(), _buildCallHistoryTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Agent Status Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Iconsax.cpu, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Voice Agent', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text('Handles customer calls 24/7', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _agentActive,
                      onChanged: (v) => setState(() => _agentActive = v),
                      activeColor: Colors.white,
                      activeTrackColor: Colors.grey[600],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(Iconsax.tick_circle, color: _agentActive ? Colors.green : Colors.grey, size: 20),
                      const SizedBox(width: 10),
                      Text(_agentActive ? 'Agent is Active' : 'Agent is Inactive', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Assigned Phone Number
          Text('Assigned Phone Number', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Iconsax.call, color: Colors.black, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('+233 30 123 4567', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
                      Text('Customers call this number for support', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Iconsax.copy, color: Colors.grey[600], size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // AI Prompt
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AI Prompt', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              GestureDetector(
                onTap: () => _showEditPromptSheet(),
                child: Text('Edit', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Iconsax.message_text, color: Colors.grey[600], size: 18),
                    const SizedBox(width: 8),
                    Text('System Prompt', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_promptController.text, style: GoogleFonts.poppins(fontSize: 13, color: Colors.black, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Quick Stats
          Text('Today\'s Stats', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard('Total Calls', '24', Iconsax.call_calling),
              const SizedBox(width: 12),
              _statCard('Resolved', '21', Iconsax.tick_circle),
              const SizedBox(width: 12),
              _statCard('Avg Duration', '4:32', Iconsax.timer_1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: Colors.black, size: 22),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildCallHistoryTab() {
    final resolved = _callHistory.where((c) => c['resolved'] == true).length;
    final unresolved = _callHistory.where((c) => c['resolved'] == false).length;

    return Column(
      children: [
        // Summary Stats
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Text('$resolved', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.black)),
                      Text('Resolved', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Text('$unresolved', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.black)),
                      Text('Unresolved', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Text('${_callHistory.length}', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.black)),
                      Text('Total', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Call History List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _callHistory.length,
            itemBuilder: (context, index) => _buildCallHistoryItem(_callHistory[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCallHistoryItem(Map<String, dynamic> call) {
    return GestureDetector(
      onTap: () => _showCallDetails(call),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Iconsax.call_incoming, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(call['phone'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black)),
                      Text('${call['date']} • ${call['time']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: call['resolved'] ? Colors.black : Colors.grey[300], borderRadius: BorderRadius.circular(6)),
                  child: Text(call['resolved'] ? 'Resolved' : 'Unresolved', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: call['resolved'] ? Colors.white : Colors.grey[700])),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(call['summary'], style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700], height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Iconsax.timer_1, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(call['duration'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCallDetails(Map<String, dynamic> call) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Iconsax.call, color: Colors.black, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(call['phone'], style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
                      Text('${call['date']} at ${call['time']}', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: call['resolved'] ? Colors.black : Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                  child: Text(call['resolved'] ? 'Resolved' : 'Unresolved', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: call['resolved'] ? Colors.white : Colors.grey[700])),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Call Summary', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Text(call['summary'], style: GoogleFonts.poppins(fontSize: 14, color: Colors.black, height: 1.5)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Icon(Iconsax.timer_1, color: Colors.grey[600], size: 20),
                        const SizedBox(height: 8),
                        Text(call['duration'], style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Duration', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Icon(Iconsax.cpu, color: Colors.grey[600], size: 20),
                        const SizedBox(height: 8),
                        Text('AI', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Handled By', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!call['resolved'])
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text('Mark as Resolved', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
                ),
              ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  void _showEditPromptSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  Text('Edit AI Prompt', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                  GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Iconsax.close_circle, color: Colors.grey[400])),
                ],
              ),
              const SizedBox(height: 8),
              Text('Customize how your AI agent responds to customers', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 20),
              TextField(
                controller: _promptController,
                maxLines: 6,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
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
                onTap: () {
                  setState(() {});
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text('Save Changes', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}
