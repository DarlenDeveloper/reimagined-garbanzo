import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../services/store_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> with SingleTickerProviderStateMixin {
  final _storeService = StoreService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _teamMembers = [];
  final List<Map<String, dynamic>> _pendingInvites = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTeamMembers();
  }

  Future<void> _loadTeamMembers() async {
    try {
      final storeId = await _storeService.getUserStoreId();
      if (storeId != null) {
        final storeData = await _storeService.getStore(storeId);
        if (storeData != null) {
          final authorizedUsers = List<String>.from(storeData['authorizedUsers'] ?? []);
          final ownerId = storeData['ownerId'] as String?;
          _currentUserId = ownerId;
          
          List<Map<String, dynamic>> members = [];
          for (final uid in authorizedUsers) {
            // For now, show basic info - in production you'd fetch from a users collection
            final isOwner = uid == ownerId;
            members.add({
              'uid': uid,
              'name': isOwner ? 'You (Owner)' : 'Team Member',
              'email': uid.substring(0, 8) + '...',
              'role': isOwner ? 'Owner' : 'Runner',
              'status': 'active',
            });
          }
          
          if (mounted) {
            setState(() {
              _teamMembers = members;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showInviteRunnerSheet() {
    final emailController = TextEditingController();
    String? generatedCode;
    bool codeGenerated = false;
    bool isGenerating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
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
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600])),
                    ),
                    Text('Add Store Runner', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 60),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Email field
                    Text('Runner Email (Optional)', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                      child: TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !codeGenerated,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'email@example.com',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                          prefixIcon: Icon(Iconsax.sms, color: Colors.grey[500], size: 20),
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (!codeGenerated) ...[
                      // Generate code button
                      GestureDetector(
                        onTap: isGenerating ? null : () async {
                          setSheetState(() => isGenerating = true);
                          try {
                            final storeId = await _storeService.getUserStoreId();
                            if (storeId != null) {
                              final code = await _storeService.generateInviteCode(storeId);
                              setSheetState(() {
                                generatedCode = code;
                                codeGenerated = true;
                                isGenerating = false;
                              });
                            }
                          } catch (e) {
                            setSheetState(() => isGenerating = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to generate code', style: GoogleFonts.poppins()),
                                backgroundColor: Colors.red[700],
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isGenerating ? Colors.grey : Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: isGenerating
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Generate Access Code', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Show generated code
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            Icon(Iconsax.tick_circle, color: Colors.green[600], size: 48),
                            const SizedBox(height: 16),
                            Text('Access Code Generated', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text('Share this code with the store runner', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                            const SizedBox(height: 20),
                            // Code display
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: generatedCode!.split('').map((digit) => Container(
                                width: 56,
                                height: 64,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Center(
                                  child: Text(digit, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700)),
                                ),
                              )).toList(),
                            ),
                            const SizedBox(height: 16),
                            // Timer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.timer_1, color: Colors.green[700], size: 18),
                                const SizedBox(width: 6),
                                Text('Expires in 15 minutes', style: GoogleFonts.poppins(fontSize: 13, color: Colors.green[700], fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Copy code button
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: generatedCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Code copied to clipboard', style: GoogleFonts.poppins()),
                              backgroundColor: Colors.black,
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.copy, size: 20),
                              const SizedBox(width: 8),
                              Text('Copy Code', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Done button
                      GestureDetector(
                        onTap: () {
                          if (emailController.text.isNotEmpty) {
                            setState(() {
                              _pendingInvites.add({
                                'email': emailController.text,
                                'role': 'Runner',
                                'code': generatedCode,
                                'expiresAt': DateTime.now().add(const Duration(minutes: 15)),
                              });
                            });
                          }
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Invite code generated successfully', style: GoogleFonts.poppins()),
                              backgroundColor: Colors.black,
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                          child: Center(
                            child: Text('Done', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Info box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Iconsax.info_circle, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Runner Access', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.blue[900])),
                                const SizedBox(height: 4),
                                Text(
                                  'Store runners can view and manage orders, products, and inventory. Payment access requires admin approval.',
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue[800], height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMemberOptions(Map<String, dynamic> member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.black,
                  child: Text(member['name'][0], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member['name'], style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(member['email'], style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
                  child: Text(member['role'], style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (member['role'] != 'Owner') ...[
              _OptionTile(
                icon: Iconsax.shield_tick,
                label: 'Manage Permissions',
                onTap: () {
                  Navigator.pop(context);
                  _showPermissionsSheet(member);
                },
              ),
              _OptionTile(
                icon: Iconsax.refresh,
                label: 'Generate New Code',
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final storeId = await _storeService.getUserStoreId();
                    if (storeId != null) {
                      final newCode = await _storeService.generateInviteCode(storeId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('New code: $newCode (expires in 15 min)', style: GoogleFonts.poppins()),
                          backgroundColor: Colors.black,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to generate code'), backgroundColor: Colors.red),
                    );
                  }
                },
              ),
              _OptionTile(
                icon: Iconsax.user_remove,
                label: 'Remove from Team',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _showRemoveConfirmation(member);
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Iconsax.crown_1, color: Colors.amber[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Store Owner has full access and cannot be removed',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPermissionsSheet(Map<String, dynamic> member) {
    final permissions = {
      'Orders': true,
      'Products': true,
      'Inventory': true,
      'Analytics': false,
      'Payments': false,
      'Settings': false,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600]))),
                    Text('Permissions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Permissions updated', style: GoogleFonts.poppins()), backgroundColor: Colors.black),
                        );
                      },
                      child: Text('Save', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('${member['name']}\'s Access', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 16),
                    ...permissions.entries.map((entry) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(_getPermissionIcon(entry.key), size: 22, color: Colors.grey[700]),
                              const SizedBox(width: 12),
                              Text(entry.key, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Switch(
                            value: entry.value,
                            onChanged: entry.key == 'Payments' ? null : (value) {
                              setSheetState(() => permissions[entry.key] = value);
                            },
                            activeColor: Colors.black,
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(Iconsax.lock, color: Colors.green[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Payment access always requires admin approval for each transaction',
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.green[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPermissionIcon(String permission) {
    switch (permission) {
      case 'Orders': return Iconsax.receipt_2;
      case 'Products': return Iconsax.box;
      case 'Inventory': return Iconsax.archive_2;
      case 'Analytics': return Iconsax.chart_2;
      case 'Payments': return Iconsax.wallet_2;
      case 'Settings': return Iconsax.setting_2;
      default: return Iconsax.document;
    }
  }

  void _showRemoveConfirmation(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove Team Member?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to remove ${member['name']} from your team? They will lose access to the store immediately.',
          style: GoogleFonts.poppins(color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final storeId = await _storeService.getUserStoreId();
                if (storeId != null && member['uid'] != null) {
                  final success = await _storeService.removeUserFromStore(storeId, member['uid']);
                  if (success) {
                    setState(() => _teamMembers.remove(member));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${member['name']} removed from team', style: GoogleFonts.poppins()), backgroundColor: Colors.black),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to remove member', style: GoogleFonts.poppins()), backgroundColor: Colors.red),
                    );
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error removing member', style: GoogleFonts.poppins()), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('Remove', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _cancelInvite(Map<String, dynamic> invite) {
    setState(() => _pendingInvites.remove(invite));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invite cancelled', style: GoogleFonts.poppins()), backgroundColor: Colors.black),
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
        title: Text('Team', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey[500],
          indicatorColor: Colors.black,
          indicatorWeight: 2,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: [
            Tab(text: 'Members (${_teamMembers.length})'),
            Tab(text: 'Pending (${_pendingInvites.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteRunnerSheet,
        backgroundColor: Colors.black,
        icon: const Icon(Iconsax.user_add, color: Colors.white, size: 20),
        label: Text('Add Runner', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : TabBarView(
        controller: _tabController,
        children: [
          // Members tab
          _teamMembers.isEmpty
              ? _buildEmptyState('No team members', 'Add store runners to help manage your store')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _teamMembers.length,
                  itemBuilder: (context, index) {
                    final member = _teamMembers[index];
                    return _MemberCard(
                      member: member,
                      onTap: () => _showMemberOptions(member),
                    );
                  },
                ),
          // Pending tab
          _pendingInvites.isEmpty
              ? _buildEmptyState('No pending invites', 'Invite codes you generate will appear here')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingInvites.length,
                  itemBuilder: (context, index) {
                    final invite = _pendingInvites[index];
                    return _PendingInviteCard(
                      invite: invite,
                      onCancel: () => _cancelInvite(invite),
                      onCopyCode: () {
                        Clipboard.setData(ClipboardData(text: invite['code']));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Code copied', style: GoogleFonts.poppins()), backgroundColor: Colors.black),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: Icon(Iconsax.people, size: 48, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final VoidCallback onTap;

  const _MemberCard({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOwner = member['role'] == 'Owner';
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.black,
                  child: Text(
                    member['name'][0],
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                ),
                if (isOwner)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber[600],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[100]!, width: 2),
                      ),
                      child: const Icon(Iconsax.crown_15, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(member['email'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOwner ? Colors.amber[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    member['role'],
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isOwner ? Colors.amber[800] : Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: member['status'] == 'active' ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      member['status'] == 'active' ? 'Active' : 'Inactive',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Iconsax.arrow_right_3, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }
}

class _PendingInviteCard extends StatelessWidget {
  final Map<String, dynamic> invite;
  final VoidCallback onCancel;
  final VoidCallback onCopyCode;

  const _PendingInviteCard({required this.invite, required this.onCancel, required this.onCopyCode});

  String _getTimeRemaining() {
    final expiresAt = invite['expiresAt'] as DateTime;
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    return '${remaining.inMinutes} min left';
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = (invite['expiresAt'] as DateTime).isBefore(DateTime.now());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        border: isExpired ? Border.all(color: Colors.red[200]!) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isExpired ? Colors.red[100] : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Iconsax.sms,
                  color: isExpired ? Colors.red[400] : Colors.grey[600],
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invite['email'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          isExpired ? Iconsax.close_circle : Iconsax.timer_1,
                          size: 14,
                          color: isExpired ? Colors.red : Colors.green[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTimeRemaining(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isExpired ? Colors.red : Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Code display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('Code: ', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13)),
                    Text(
                      invite['code'],
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: isExpired ? Colors.grey : Colors.black,
                      ),
                    ),
                  ],
                ),
                if (!isExpired)
                  GestureDetector(
                    onTap: onCopyCode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Iconsax.copy, size: 16),
                          const SizedBox(width: 4),
                          Text('Copy', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Cancel button
          GestureDetector(
            onTap: onCancel,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isExpired ? Colors.red[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  isExpired ? 'Remove' : 'Cancel Invite',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isExpired ? Colors.red[700] : Colors.grey[700],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? Colors.red : Colors.grey[700], size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.red : Colors.black,
              ),
            ),
            const Spacer(),
            Icon(Iconsax.arrow_right_3, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }
}
