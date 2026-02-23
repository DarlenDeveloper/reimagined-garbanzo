import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final userId = authService.currentUser?.uid;
    final userEmail = authService.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Iconsax.setting_2),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('couriers')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final fullName = data?['fullName'] ?? 'Courier';
          final phone = data?['phone'] ?? '';
          final verified = data?['verified'] ?? false;
          final rating = (data?['rating'] ?? 0.0).toDouble();
          final totalDeliveries = data?['totalDeliveries'] ?? 0;
          final totalEarnings = (data?['totalEarnings'] ?? 0.0).toDouble();

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.black,
                            child: const Icon(Iconsax.user, color: Colors.white, size: 40),
                          ),
                          if (verified)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fullName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.star5, color: Colors.black, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            ' ($totalDeliveries deliveries)',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Stats Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Iconsax.truck_fast,
                          label: 'Deliveries',
                          value: '$totalDeliveries',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                      icon: Iconsax.wallet_2,
                      label: 'Earnings',
                      value: 'UGX ${(totalEarnings / 1000).toStringAsFixed(0)}K',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Menu Items
            _buildMenuSection(
              context,
              title: 'Activity',
              items: [
                _MenuItem(
                  icon: Iconsax.truck_fast,
                  title: 'My Deliveries',
                  onTap: () {
                    context.push('/deliveries');
                  },
                ),
                _MenuItem(
                  icon: Iconsax.star,
                  title: 'Ratings & Reviews',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildMenuSection(
              context,
              title: 'Account',
              items: [
                _MenuItem(
                  icon: Iconsax.user_edit,
                  title: 'Edit Profile',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Iconsax.car,
                  title: 'Vehicle Information',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Iconsax.card,
                  title: 'Payment Methods',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Iconsax.document_text,
                  title: 'Documents',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildMenuSection(
              context,
              title: 'Support',
              items: [
                _MenuItem(
                  icon: Iconsax.message_question,
                  title: 'Help Center',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Iconsax.shield_tick,
                  title: 'Safety',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Iconsax.document,
                  title: 'Terms & Conditions',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Iconsax.lock,
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildMenuSection(
              context,
              title: 'App',
              items: [
                _MenuItem(
                  icon: Iconsax.notification,
                  title: 'Notifications',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Iconsax.language_square,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Iconsax.info_circle,
                  title: 'About',
                  subtitle: 'Version 1.0.0',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Show confirmation dialog
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      // Navigate immediately for better UX
                      context.go('/welcome');
                      // Sign out in background
                      authService.signOut();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Iconsax.logout),
                  label: const Text('Logout'),
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      );
    },
  ),
);
}

Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.grey[700]),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
            ),
          ),
          ...items.map((item) => _buildMenuItem(context, item)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 22, color: Colors.grey[700]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
