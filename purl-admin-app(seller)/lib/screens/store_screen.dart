import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../services/store_service.dart';
import '../services/followers_service.dart';
import '../services/order_service.dart';
import 'qr_code_screen.dart';
import 'socials_screen.dart';

class StoreScreen extends StatefulWidget {
  final bool showBackButton;
  
  const StoreScreen({super.key, this.showBackButton = false});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final _storeService = StoreService();
  final _followersService = FollowersService();
  final _orderService = OrderService();

  String? _storeId;
  Map<String, dynamic>? _storeData;
  int _followersCount = 0;
  int _salesCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    try {
      final storeId = await _storeService.getUserStoreId();
      if (storeId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final storeData = await _storeService.getStore(storeId);
      final followersCount = await _followersService.getFollowerCount(storeId);
      
      // Get sales count from orders
      _orderService.getStoreOrdersStream().listen((orders) {
        if (mounted) {
          setState(() {
            _salesCount = orders.length;
          });
        }
      });

      setState(() {
        _storeId = storeId;
        _storeData = storeData;
        _followersCount = followersCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showQRCode() {
    if (_storeData == null || _storeId == null) return;
    
    final slug = _storeData!['slug'] as String? ?? _storeId!;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRCodeScreen(
          storeId: _storeId!,
          storeName: _storeData!['name'] as String,
          storeSlug: slug,
        ),
      ),
    );
  }

  void _viewStore() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SocialsScreen(),
      ),
    );
  }

  Future<void> _shareStore() async {
    if (_storeData == null || _storeId == null) return;
    
    final slug = _storeData!['slug'] as String? ?? _storeId!;
    final storeUrl = 'https://purlecom.com/stores/$slug';
    
    await Clipboard.setData(ClipboardData(text: storeUrl));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Store link copied to clipboard', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFfb2a0a),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: const Color(0xFFfb2a0a)),
        ),
      );
    }

    final storeName = _storeData?['name'] as String? ?? 'My Store';
    final logoUrl = _storeData?['logoUrl'] as String?;
    final slug = _storeData?['slug'] as String? ?? _storeId ?? '';

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
                    if (widget.showBackButton) ...[
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Iconsax.arrow_left, color: const Color(0xFFfb2a0a), size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text('My Store', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFfb2a0a),
                  borderRadius: BorderRadius.circular(20),
                  image: logoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(logoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: logoUrl == null
                    ? const Icon(Iconsax.shop, color: Colors.white, size: 40)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(storeName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black)),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _StoreStatCard(icon: Iconsax.star_1, value: '0', label: 'Rating')),
                    const SizedBox(width: 12),
                    Expanded(child: _StoreStatCard(icon: Iconsax.people, value: _formatCount(_followersCount), label: 'Followers')),
                    const SizedBox(width: 12),
                    Expanded(child: _StoreStatCard(icon: Iconsax.shopping_bag, value: _formatCount(_salesCount), label: 'Sales')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _QuickLinkItem(
                      icon: Iconsax.eye,
                      label: 'View Store',
                      subtitle: 'See how customers see your store',
                      onTap: _viewStore,
                    ),
                    _QuickLinkItem(
                      icon: Iconsax.share,
                      label: 'Share Store',
                      subtitle: 'Share your store link',
                      onTap: _shareStore,
                    ),
                    _QuickLinkItem(
                      icon: Iconsax.scan_barcode,
                      label: 'Store QR Code',
                      subtitle: 'Download your store QR code',
                      onTap: _showQRCode,
                    ),
                    _QuickLinkItem(
                      icon: Iconsax.message_question,
                      label: 'Support',
                      subtitle: 'Get help with your store',
                      onTap: () {},
                    ),
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
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
          Icon(icon, color: const Color(0xFFfb2a0a), size: 24),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFFfb2a0a))),
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
  final VoidCallback? onTap;

  const _QuickLinkItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFFfb2a0a), size: 22),
        ),
        title: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        trailing: Icon(Iconsax.arrow_right_3, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}
