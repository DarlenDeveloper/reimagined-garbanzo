import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final Set<String> _selectedCategories = {};

  final List<_Category> _categories = [
    _Category(id: '1', name: 'Electronics', icon: Iconsax.mobile, color: const Color(0xFF3B82F6)),
    _Category(id: '2', name: 'Fashion', icon: Iconsax.shopping_bag, color: const Color(0xFFEC4899)),
    _Category(id: '3', name: 'Home & Living', icon: Iconsax.home_2, color: const Color(0xFFF59E0B)),
    _Category(id: '4', name: 'Beauty', icon: Iconsax.brush_1, color: const Color(0xFFEF4444)),
    _Category(id: '5', name: 'Sports', icon: Iconsax.weight, color: const Color(0xFF22C55E)),
    _Category(id: '6', name: 'Books', icon: Iconsax.book, color: const Color(0xFF8B5CF6)),
    _Category(id: '7', name: 'Toys & Games', icon: Iconsax.game, color: const Color(0xFF06B6D4)),
    _Category(id: '8', name: 'Groceries', icon: Iconsax.shopping_cart, color: const Color(0xFF84CC16)),
    _Category(id: '9', name: 'Health', icon: Iconsax.health, color: const Color(0xFFF43F5E)),
    _Category(id: '10', name: 'Automotive', icon: Iconsax.car, color: const Color(0xFF6366F1)),
    _Category(id: '11', name: 'Jewelry', icon: Iconsax.diamonds, color: const Color(0xFFD946EF)),
    _Category(id: '12', name: 'Pet Supplies', icon: Iconsax.pet, color: const Color(0xFF14B8A6)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBeige,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Categories', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Select categories you\'re interested in', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.9,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) => _buildCategoryCard(_categories[index]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedCategories.isNotEmpty ? _buildBottomBar() : null,
    );
  }

  Widget _buildCategoryCard(_Category category) {
    final isSelected = _selectedCategories.contains(category.id);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedCategories.remove(category.id);
          } else {
            _selectedCategories.add(category.id);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.2) : category.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(category.icon, size: 24, color: isSelected ? Colors.white : category.color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 14, color: AppColors.darkGreen),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('Save ${_selectedCategories.length} Categories', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _Category {
  final String id, name;
  final IconData icon;
  final Color color;
  _Category({required this.id, required this.name, required this.icon, required this.color});
}
