import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final List<Map<String, dynamic>> _products = [
    {'name': 'Wireless Earbuds', 'price': '\$150.00', 'stock': 24, 'status': 'Active', 'image': '🎧'},
    {'name': 'Phone Case', 'price': '\$45.00', 'stock': 5, 'status': 'Low Stock', 'image': '📱'},
    {'name': 'Smart Watch', 'price': '\$320.00', 'stock': 12, 'status': 'Active', 'image': '⌚'},
    {'name': 'Laptop Stand', 'price': '\$89.00', 'stock': 0, 'status': 'Out of Stock', 'image': '💻'},
  ];

  void _showAddProductSheet() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    String selectedCategory = 'Electronics';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600]))),
                  Text('Add Product', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty) {
                        setState(() {
                          _products.insert(0, {
                            'name': nameController.text,
                            'price': '\$${priceController.text}',
                            'stock': int.tryParse(stockController.text) ?? 0,
                            'status': 'Active',
                            'image': '📦',
                          });
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Product added', style: GoogleFonts.poppins()), backgroundColor: Colors.black),
                        );
                      }
                    },
                    child: Text('Save', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTextField('Product Name', nameController, 'Enter product name'),
                  const SizedBox(height: 16),
                  _buildTextField('Price (USD)', priceController, '0.00', keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  _buildTextField('Stock Quantity', stockController, '0', keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  Text('Category', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  StatefulBuilder(
                    builder: (context, setDropdownState) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          style: GoogleFonts.poppins(color: Colors.black),
                          items: ['Electronics', 'Clothing', 'Accessories', 'Home', 'Beauty'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setDropdownState(() => selectedCategory = v!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.gallery_add, size: 32, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('Add Product Images', style: GoogleFonts.poppins(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Description', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    height: 100,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      maxLines: 4,
                      decoration: InputDecoration.collapsed(hintText: 'Enter product description...', hintStyle: GoogleFonts.poppins(color: Colors.grey[400])),
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: GoogleFonts.poppins(color: Colors.grey[400])),
            style: GoogleFonts.poppins(),
          ),
        ),
      ],
    );
  }

  void _showProductDetails(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(product['image'], style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product['name'], style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(product['price'], style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _actionButton(Iconsax.edit, 'Edit', () => Navigator.pop(context))),
                const SizedBox(width: 12),
                Expanded(child: _actionButton(Iconsax.copy, 'Duplicate', () => Navigator.pop(context))),
                const SizedBox(width: 12),
                Expanded(child: _actionButton(Iconsax.trash, 'Delete', () {
                  setState(() => _products.remove(product));
                  Navigator.pop(context);
                }, isDestructive: true)),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withAlpha(25) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isDestructive ? Colors.red : Colors.black, size: 22),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, color: isDestructive ? Colors.red : Colors.black)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductSheet,
        backgroundColor: Colors.black,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Products', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Iconsax.search_normal, color: Colors.black, size: 22),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Iconsax.filter, color: Colors.black, size: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _products.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _products.length,
                      itemBuilder: (context, index) => _ProductItem(
                        product: _products[index],
                        onTap: () => _showProductDetails(_products[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: Icon(Iconsax.box, size: 48, color: Colors.grey[400]),
            ),
            const SizedBox(height: 32),
            Text('Add your products', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black)),
            const SizedBox(height: 8),
            Text(
              'To start selling on GlowCart, add your products or import from another platform.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _showAddProductSheet,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Add your products', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductItem extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const _ProductItem({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = product['status'] as String;
    final statusColor = status == 'Active' ? Colors.black : status == 'Low Stock' ? Colors.grey[700]! : Colors.grey[500]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(product['image'], style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${product['price']} • ${product['stock']} in stock', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withAlpha(25), borderRadius: BorderRadius.circular(6)),
              child: Text(status, style: GoogleFonts.poppins(color: statusColor, fontSize: 11, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
