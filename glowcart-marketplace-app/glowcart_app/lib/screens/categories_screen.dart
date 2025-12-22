import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final Set<String> _selectedCategories = {};

  final List<_Category> _categories = [
    _Category(id: '1', name: 'Electronics', icon: Iconsax.mobile),
    _Category(id: '2', name: 'Fashion', icon: Iconsax.shopping_bag),
    _Category(id: '3', name: 'Home & Living', icon: Iconsax.home_2),
    _Category(id: '4', name: 'Beauty', icon: Iconsax.brush_1),
    _Category(id: '5', name: 'Sports', icon: Iconsax.weight),
    _Category(id: '6', name: 'Books', icon: Iconsax.book),
    _Category(id: '7', name: 'Toys & Games', icon: Iconsax.game),
    _Category(id: '8', name: 'Groceries', icon: Iconsax.shopping_cart),
    _Category(id: '9', name: 'Health', icon: Iconsax.health),
    _Category(id: '10', name: 'Automotive', icon: Iconsax.car),
    _Category(id: '11', name: 'Jewelry', icon: Iconsax.diamonds),
    _Category(id: '12', name: 'Pet Supplies', icon: Iconsax.pet),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text('Categories', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Select categories you\'re interested in', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.9, crossAxisSpacing: 12, mainAxisSpacing: 12),
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
      onTap: () => setState(() => isSelected ? _selectedCategories.remove(category.id) : _selectedCategories.add(category.id)),
      child: Container(
        decoration: BoxDecoration(color: isSelected ? Colors.black : Colors.grey[100], borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.grey[200], borderRadius: BorderRadius.circular(14)),
                    child: Icon(category.icon, size: 24, color: isSelected ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(category.name, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : Colors.black)),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 14, color: Colors.black),
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
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: Text('Save ${_selectedCategories.length} Categories', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _Category {
  final String id, name;
  final IconData icon;
  _Category({required this.id, required this.name, required this.icon});
}
