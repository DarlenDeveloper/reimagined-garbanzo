import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBeige,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Help & Support', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            Text('FAQ', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            _buildFaqSection(),
            const SizedBox(height: 24),
            _buildContactSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search for help...',
          hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
          border: InputBorder.none,
          icon: const Icon(Iconsax.search_normal, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildQuickAction(Iconsax.box, 'Track Order'),
        const SizedBox(width: 12),
        _buildQuickAction(Iconsax.refresh_left_square, 'Returns'),
        const SizedBox(width: 12),
        _buildQuickAction(Iconsax.message_question, 'Chat'),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppColors.darkGreen),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection() {
    final faqs = [
      ('How do I track my order?', 'Go to Orders > Select order > Track'),
      ('How to return an item?', 'Orders > Select order > Request Return'),
      ('Payment methods accepted?', 'Cards, PayPal, Mobile Money, BNPL'),
      ('How to contact seller?', 'Product page > Message Store'),
      ('Delivery time?', 'Usually 2-5 business days'),
    ];
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: faqs.asMap().entries.map((e) => _buildFaqItem(e.value.$1, e.value.$2, e.key < faqs.length - 1)).toList(),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer, bool showDivider) {
    return Column(
      children: [
        ExpansionTile(
          title: Text(question, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          iconColor: AppColors.darkGreen,
          collapsedIconColor: AppColors.textSecondary,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(answer, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
            ),
          ],
        ),
        if (showDivider) Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: AppColors.surfaceVariant),
      ],
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text('Still need help?', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Our support team is available 24/7', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildContactButton(Iconsax.message, 'Live Chat')),
              const SizedBox(width: 12),
              Expanded(child: _buildContactButton(Iconsax.call, 'Call Us')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
        ],
      ),
    );
  }
}
