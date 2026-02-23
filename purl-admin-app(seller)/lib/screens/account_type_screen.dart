import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class AccountTypeScreen extends StatelessWidget {
  const AccountTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset('assets/images/popstoreslogo.PNG', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to POP',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How would you like to continue?',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              // Create Store Option
              _AccountTypeCard(
                icon: Iconsax.shop,
                title: 'Create My Store',
                subtitle: 'Start selling your products on POP',
                features: const [
                  'Set up your own store',
                  'Add products & manage inventory',
                  'Accept payments & track orders',
                ],
                isPrimary: true,
                onTap: () => context.go('/store-setup'),
              ),
              const SizedBox(height: 16),
              // Join Store Option
              _AccountTypeCard(
                icon: Iconsax.user_tag,
                title: 'Join a Store',
                subtitle: 'Work as a store runner for an existing store',
                features: const [
                  'Help manage orders & products',
                  'Access granted by store admin',
                  'Enter 4-digit invite code',
                ],
                isPrimary: false,
                onTap: () => context.go('/runner-code'),
              ),
              const Spacer(),
              // Logout option
              TextButton(
                onPressed: () => context.go('/login'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.logout, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Sign out',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}


class _AccountTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> features;
  final bool isPrimary;
  final VoidCallback onTap;

  const _AccountTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFFfb2a0a) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPrimary ? Colors.white.withOpacity(0.15) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? Colors.white : Colors.black,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isPrimary ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isPrimary ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Iconsax.arrow_right_3,
                  color: isPrimary ? Colors.white54 : Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Iconsax.tick_circle,
                    size: 16,
                    color: isPrimary ? Colors.white60 : Colors.grey[500],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    feature,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isPrimary ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
