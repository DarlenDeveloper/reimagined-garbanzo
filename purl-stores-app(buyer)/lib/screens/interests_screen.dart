import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';

class InterestsScreen extends StatefulWidget {
  final bool isOnboarding;
  const InterestsScreen({super.key, this.isOnboarding = true});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final Set<String> _selectedInterests = {};

  final List<_Interest> _interests = [
    _Interest(id: 'electronics', name: 'Electronics', icon: Iconsax.mobile, color: const Color(0xFF3B82F6)),
    _Interest(id: 'fashion', name: 'Fashion', icon: Iconsax.shopping_bag, color: const Color(0xFFEC4899)),
    _Interest(id: 'home', name: 'Home & Living', icon: Iconsax.home_2, color: const Color(0xFFF59E0B)),
    _Interest(id: 'beauty', name: 'Beauty', icon: Iconsax.brush_1, color: const Color(0xFFEF4444)),
    _Interest(id: 'sports', name: 'Sports & Fitness', icon: Iconsax.weight, color: const Color(0xFF22C55E)),
    _Interest(id: 'books', name: 'Books & Stationery', icon: Iconsax.book, color: const Color(0xFF8B5CF6)),
    _Interest(id: 'gaming', name: 'Gaming', icon: Iconsax.game, color: const Color(0xFF06B6D4)),
    _Interest(id: 'groceries', name: 'Groceries', icon: Iconsax.shopping_cart, color: const Color(0xFF84CC16)),
    _Interest(id: 'health', name: 'Health & Wellness', icon: Iconsax.health, color: const Color(0xFFF43F5E)),
    _Interest(id: 'automotive', name: 'Automotive', icon: Iconsax.car, color: const Color(0xFF6366F1)),
    _Interest(id: 'jewelry', name: 'Jewelry & Accessories', icon: Iconsax.diamonds, color: const Color(0xFFD946EF)),
    _Interest(id: 'pets', name: 'Pet Supplies', icon: Iconsax.pet, color: const Color(0xFF14B8A6)),
    _Interest(id: 'kids', name: 'Kids & Baby', icon: Iconsax.lovely, color: const Color(0xFFFF6B6B)),
    _Interest(id: 'outdoor', name: 'Outdoor & Garden', icon: Iconsax.tree, color: const Color(0xFF10B981)),
    _Interest(id: 'art', name: 'Art & Crafts', icon: Iconsax.paintbucket, color: const Color(0xFFA855F7)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSection(),
                    const SizedBox(height: 24),
                    _buildInterestsGrid(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }


  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          if (!widget.isOnboarding)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Iconsax.arrow_left, size: 20, color: AppColors.textPrimary),
              ),
            ),
          if (!widget.isOnboarding) const SizedBox(width: 12),
          Text(
            widget.isOnboarding ? 'Welcome!' : 'My Interests',
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const Spacer(),
          if (widget.isOnboarding)
            TextButton(
              onPressed: () => _continueToApp(),
              child: Text('Skip', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.darkGreen, Color(0xFF2D5A45)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isOnboarding ? 'What are you into?' : 'Personalize your feed',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select your interests to see relevant stores and products in your feed.',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Iconsax.magic_star, size: 28, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Choose at least 3', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _selectedInterests.length >= 3 ? AppColors.success.withValues(alpha: 0.1) : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_selectedInterests.length} selected',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _selectedInterests.length >= 3 ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _interests.length,
          itemBuilder: (context, index) => _buildInterestCard(_interests[index]),
        ),
      ],
    );
  }

  Widget _buildInterestCard(_Interest interest) {
    final isSelected = _selectedInterests.contains(interest.id);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedInterests.remove(interest.id);
          } else {
            _selectedInterests.add(interest.id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.darkGreen.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.2) : interest.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(interest.icon, size: 22, color: isSelected ? Colors.white : interest.color),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      interest.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 12, color: AppColors.darkGreen),
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildBottomBar() {
    final canContinue = _selectedInterests.length >= 3;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!canContinue)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.info_circle, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Select ${3 - _selectedInterests.length} more to continue',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canContinue ? () => _continueToApp() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canContinue ? AppColors.darkGreen : AppColors.surfaceVariant,
                foregroundColor: canContinue ? Colors.white : AppColors.textSecondary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                widget.isOnboarding ? 'Continue' : 'Save Interests',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _continueToApp() {
    // In a real app, save interests to user profile/backend
    // For now, just navigate to main app
    if (widget.isOnboarding) {
      context.go('/home');
    } else {
      Navigator.pop(context, _selectedInterests.toList());
    }
  }
}

class _Interest {
  final String id, name;
  final IconData icon;
  final Color color;

  _Interest({required this.id, required this.name, required this.icon, required this.color});
}
