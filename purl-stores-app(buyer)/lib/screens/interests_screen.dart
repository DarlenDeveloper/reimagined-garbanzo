import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InterestsScreen extends StatefulWidget {
  final bool isOnboarding;
  const InterestsScreen({super.key, this.isOnboarding = true});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final Set<String> _selectedInterests = {};
  bool _isSaving = false;

  final List<_Interest> _interests = [
    _Interest(id: 'electronics', name: 'Electronics', icon: Iconsax.mobile),
    _Interest(id: 'fashion', name: 'Fashion', icon: Iconsax.shopping_bag),
    _Interest(id: 'home', name: 'Home & Living', icon: Iconsax.home_2),
    _Interest(id: 'beauty', name: 'Beauty', icon: Iconsax.brush_1),
    _Interest(id: 'sports', name: 'Sports & Fitness', icon: Iconsax.weight),
    _Interest(id: 'books', name: 'Books & Stationery', icon: Iconsax.book),
    _Interest(id: 'gaming', name: 'Gaming', icon: Iconsax.game),
    _Interest(id: 'groceries', name: 'Groceries', icon: Iconsax.shopping_cart),
    _Interest(id: 'health', name: 'Health & Wellness', icon: Iconsax.health),
    _Interest(id: 'automotive', name: 'Automotive', icon: Iconsax.car),
    _Interest(id: 'jewelry', name: 'Jewelry & Accessories', icon: Iconsax.diamonds),
    _Interest(id: 'pets', name: 'Pet Supplies', icon: Iconsax.pet),
    _Interest(id: 'kids', name: 'Kids & Baby', icon: Iconsax.lovely),
    _Interest(id: 'outdoor', name: 'Outdoor & Garden', icon: Iconsax.tree),
    _Interest(id: 'art', name: 'Art & Crafts', icon: Iconsax.paintbucket),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: const Icon(Iconsax.arrow_left, size: 20, color: Colors.black),
              ),
            ),
          if (!widget.isOnboarding) const SizedBox(width: 12),
          Text(
            widget.isOnboarding ? 'Welcome!' : 'My Interests',
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black),
          ),
          const Spacer(),
          if (widget.isOnboarding)
            TextButton(
              onPressed: () => _continueToApp(),
              child: Text('Skip', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
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
        color: Colors.black,
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
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
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
            Text('Choose at least 3', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _selectedInterests.length >= 3 ? Colors.black : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_selectedInterests.length} selected',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _selectedInterests.length >= 3 ? Colors.white : Colors.grey[600],
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
          color: isSelected ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
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
                      color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(interest.icon, size: 22, color: isSelected ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      interest.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : Colors.black),
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
                  child: const Icon(Icons.check, size: 12, color: Colors.black),
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
                  Icon(Iconsax.info_circle, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    'Select ${3 - _selectedInterests.length} more to continue',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          GestureDetector(
            onTap: (canContinue && !_isSaving) ? () => _continueToApp() : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: (canContinue && !_isSaving) ? Colors.black : Colors.grey[200],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        widget.isOnboarding ? 'Continue' : 'Save Interests',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: canContinue ? Colors.white : Colors.grey[500],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _continueToApp() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      // Save interests to buyerInterests collection
      await FirebaseFirestore.instance
          .collection('buyerInterests')
          .doc(user.uid)
          .set({
        'userId': user.uid,
        'interests': _selectedInterests.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        if (widget.isOnboarding) {
          context.go('/complete-profile');
        } else {
          Navigator.pop(context, _selectedInterests.toList());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save interests', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExistingInterests();
  }

  Future<void> _loadExistingInterests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('buyerInterests')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()?['interests'] != null) {
        setState(() {
          _selectedInterests.addAll(List<String>.from(doc.data()!['interests']));
        });
      }
    } catch (e) {
      // Ignore errors loading existing interests
    }
  }
}

class _Interest {
  final String id, name;
  final IconData icon;

  _Interest({required this.id, required this.name, required this.icon});
}
