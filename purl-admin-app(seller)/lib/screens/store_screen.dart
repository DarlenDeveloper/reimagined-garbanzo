import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class StoreScreen extends StatelessWidget {
  final bool showBackButton;
  
  const StoreScreen({super.key, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (showBackButton) ...[
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Iconsax.arrow_left, color: Colors.black, size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text('My Store', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                      child: Icon(Iconsax.edit_2, color: Colors.grey[700], size: 22),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Iconsax.shop, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text('My Awesome Store', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black)),
              Text('mystore.purl.com', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.tick_circle, color: Colors.grey[700], size: 14),
                    const SizedBox(width: 6),
                    Text('Online', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _StoreStatCard(icon: Iconsax.star_1, value: '4.8', label: 'Rating')),
                    const SizedBox(width: 12),
                    Expanded(child: _StoreStatCard(icon: Iconsax.people, value: '1.2K', label: 'Followers')),
                    const SizedBox(width: 12),
                    Expanded(child: _StoreStatCard(icon: Iconsax.shopping_bag, value: '856', label: 'Sales')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _QuickLinkItem(icon: Iconsax.eye, label: 'View Store', subtitle: 'See how customers see your store'),
                    _QuickLinkItem(icon: Iconsax.share, label: 'Share Store', subtitle: 'Share your store link'),
                    _QuickLinkItem(icon: Iconsax.scan_barcode, label: 'Store QR Code', subtitle: 'Download your store QR code'),
                    _QuickLinkItem(icon: Iconsax.message_question, label: 'Support', subtitle: 'Get help with your store'),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StoreStatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: Colors.black, size: 24),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _QuickLinkItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _QuickLinkItem({required this.icon, required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.black, size: 22),
        ),
        title: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        trailing: Icon(Iconsax.arrow_right_3, color: Colors.grey[400]),
        onTap: () {},
      ),
    );
  }
}
