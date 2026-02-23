import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBeige,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Privacy & Security', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Security', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            _buildMenuItem(Iconsax.key, 'Change Password', 'Update your password', () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Feature coming soon', style: GoogleFonts.poppins()),
                  backgroundColor: const Color(0xFFfb2a0a),
                ),
              );
            }),
            const SizedBox(height: 24),
            Text('Privacy', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            _buildMenuItem(Iconsax.eye, 'Profile Visibility', 'Control who sees your profile', () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Feature coming soon', style: GoogleFonts.poppins()),
                  backgroundColor: const Color(0xFFfb2a0a),
                ),
              );
            }),
            _buildMenuItem(Iconsax.location, 'Location Services', 'Manage location access', () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Feature coming soon', style: GoogleFonts.poppins()),
                  backgroundColor: const Color(0xFFfb2a0a),
                ),
              );
            }),
            _buildMenuItem(Iconsax.document, 'Data & Privacy', 'Download or delete your data', () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Feature coming soon', style: GoogleFonts.poppins()),
                  backgroundColor: const Color(0xFFfb2a0a),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: const Color(0xFFfb2a0a).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: const Color(0xFFfb2a0a)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
