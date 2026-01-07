import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key});

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  // Dummy pending requests
  final List<Map<String, dynamic>> _pendingRequests = [
    {
      'id': '1',
      'runner': 'Mike Johnson',
      'email': 'mike@store.com',
      'action': 'Process Refund',
      'amount': 45.00,
      'orderId': '#GC-1234',
      'reason': 'Customer requested refund - item damaged',
      'requestedAt': DateTime.now().subtract(const Duration(minutes: 5)),
    },
    {
      'id': '2',
      'runner': 'Sarah Williams',
      'email': 'sarah@store.com',
      'action': 'View Payments',
      'amount': null,
      'orderId': null,
      'reason': 'Need to check transaction history',
      'requestedAt': DateTime.now().subtract(const Duration(minutes: 12)),
    },
  ];

  // Access history
  final List<Map<String, dynamic>> _accessHistory = [
    {'runner': 'Mike Johnson', 'action': 'Process Refund', 'status': 'approved', 'amount': 25.00, 'reviewedAt': DateTime.now().subtract(const Duration(hours: 2))},
    {'runner': 'Sarah Williams', 'action': 'View Analytics', 'status': 'denied', 'amount': null, 'reviewedAt': DateTime.now().subtract(const Duration(hours: 5))},
    {'runner': 'Mike Johnson', 'action': 'Export Data', 'status': 'approved', 'amount': null, 'reviewedAt': DateTime.now().subtract(const Duration(days: 1))},
  ];

  void _approveRequest(Map<String, dynamic> request) {
    setState(() {
      _pendingRequests.remove(request);
      _accessHistory.insert(0, {
        'runner': request['runner'],
        'action': request['action'],
        'status': 'approved',
        'amount': request['amount'],
        'reviewedAt': DateTime.now(),
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Access approved for ${request['runner']}', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green[700],
      ),
    );
  }

  void _denyRequest(Map<String, dynamic> request) {
    setState(() {
      _pendingRequests.remove(request);
      _accessHistory.insert(0, {
        'runner': request['runner'],
        'action': request['action'],
        'status': 'denied',
        'amount': request['amount'],
        'reviewedAt': DateTime.now(),
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Access denied for ${request['runner']}', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red[700],
      ),
    );
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Iconsax.shield_tick, color: Colors.orange[700], size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Access Request', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(request['action'], style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _DetailRow(label: 'Requested by', value: request['runner']),
            _DetailRow(label: 'Email', value: request['email']),
            if (request['orderId'] != null) _DetailRow(label: 'Order', value: request['orderId']),
            if (request['amount'] != null) _DetailRow(label: 'Amount', value: '\$${request['amount'].toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            Text('Reason', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(request['reason'], style: GoogleFonts.poppins(fontSize: 14)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _denyRequest(request);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Center(
                        child: Text('Deny', style: GoogleFonts.poppins(color: Colors.red[700], fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _approveRequest(request);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text('Approve', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
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
        title: Text('Access Control', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pending requests section
            if (_pendingRequests.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Iconsax.notification_bing, color: Colors.orange[700], size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('Pending Requests', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_pendingRequests.length}',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...(_pendingRequests.map((request) => _PendingRequestCard(
                request: request,
                onTap: () => _showRequestDetails(request),
                onApprove: () => _approveRequest(request),
                onDeny: () => _denyRequest(request),
                formatTime: _formatTime,
              ))),
              const SizedBox(height: 24),
            ],
            // Quick access toggles
            Text('Quick Access Settings', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Control what runners can access', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 12),
            _AccessToggleCard(
              icon: Iconsax.wallet_2,
              title: 'Payments Page',
              subtitle: 'View transactions and process refunds',
              isEnabled: false,
              isLocked: true,
            ),
            _AccessToggleCard(
              icon: Iconsax.chart_2,
              title: 'Analytics',
              subtitle: 'View store performance metrics',
              isEnabled: false,
            ),
            _AccessToggleCard(
              icon: Iconsax.document_download,
              title: 'Export Data',
              subtitle: 'Download reports and data',
              isEnabled: false,
            ),
            _AccessToggleCard(
              icon: Iconsax.setting_2,
              title: 'Store Settings',
              subtitle: 'Modify store configuration',
              isEnabled: false,
              isLocked: true,
            ),
            const SizedBox(height: 24),
            // History section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Activity', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () {},
                  child: Text('View All', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...(_accessHistory.take(5).map((item) => _HistoryItem(
              item: item,
              formatTime: _formatTime,
            ))),
          ],
        ),
      ),
    );
  }
}


class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
          Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onDeny;
  final String Function(DateTime) formatTime;

  const _PendingRequestCard({
    required this.request,
    required this.onTap,
    required this.onApprove,
    required this.onDeny,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.orange[200],
                  child: Text(
                    request['runner'][0],
                    style: GoogleFonts.poppins(color: Colors.orange[800], fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request['runner'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      Text(request['action'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                    ],
                  ),
                ),
                Text(formatTime(request['requestedAt']), style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
            if (request['amount'] != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.dollar_circle, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 6),
                    Text('\$${request['amount'].toStringAsFixed(2)}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    if (request['orderId'] != null) ...[
                      const SizedBox(width: 8),
                      Text('• ${request['orderId']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onDeny,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Text('Deny', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onApprove,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text('Approve', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessToggleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isEnabled;
  final bool isLocked;

  const _AccessToggleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isEnabled,
    this.isLocked = false,
  });

  @override
  State<_AccessToggleCard> createState() => _AccessToggleCardState();
}

class _AccessToggleCardState extends State<_AccessToggleCard> {
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.isEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, color: Colors.grey[700], size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(widget.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                    if (widget.isLocked) ...[
                      const SizedBox(width: 6),
                      Icon(Iconsax.lock, size: 14, color: Colors.grey[500]),
                    ],
                  ],
                ),
                Text(widget.subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Switch(
            value: _isEnabled,
            onChanged: widget.isLocked ? null : (value) {
              setState(() => _isEnabled = value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${widget.title} ${value ? 'enabled' : 'disabled'} for runners',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.black,
                ),
              );
            },
            activeColor: Colors.black,
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final String Function(DateTime) formatTime;

  const _HistoryItem({required this.item, required this.formatTime});

  @override
  Widget build(BuildContext context) {
    final isApproved = item['status'] == 'approved';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isApproved ? Colors.green[50] : Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isApproved ? Iconsax.tick_circle : Iconsax.close_circle,
              color: isApproved ? Colors.green[600] : Colors.red[600],
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['runner'], style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13)),
                Text(
                  '${item['action']}${item['amount'] != null ? ' • \$${item['amount'].toStringAsFixed(2)}' : ''}',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isApproved ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isApproved ? 'Approved' : 'Denied',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isApproved ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(formatTime(item['reviewedAt']), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }
}
