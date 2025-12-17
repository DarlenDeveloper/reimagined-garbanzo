import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBeige,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('About', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(24)),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/images/mainlogo.png', fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Text('GlowCart', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text('Version 1.0.0', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildMenuItem(context, Iconsax.document_text, 'Terms of Service', () {}),
                  _buildDivider(),
                  _buildMenuItem(context, Iconsax.shield_tick, 'Privacy Policy', () {}),
                  _buildDivider(),
                  _buildMenuItem(context, Iconsax.document, 'Licenses', () {}),
                  _buildDivider(),
                  _buildMenuItem(context, Iconsax.star, 'Rate Us', () {}),
                  _buildDivider(),
                  _buildMenuItem(context, Iconsax.share, 'Share App', () {}),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Text('Follow Us', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialIconButton(Iconsax.message_text),
                      const SizedBox(width: 16),
                      _buildSocialIconButton(Iconsax.link_2),
                      const SizedBox(width: 16),
                      _buildSocialIconButton(Iconsax.people),
                      const SizedBox(width: 16),
                      _buildSocialIconButton(Iconsax.camera),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Made with ❤️ by GlowCart Team', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('© 2024 GlowCart. All rights reserved.', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.darkGreen),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
            const Icon(Iconsax.arrow_right_3, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: AppColors.surfaceVariant);
  }

  Widget _buildSocialIconButton(IconData icon) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 20, color: AppColors.darkGreen),
    );
  }
}
