import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text('Inventory', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Iconsax.search_normal, color: Colors.black), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStockDialog(context),
        backgroundColor: Colors.black,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: Text('Add Stock', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.orange.withAlpha(25), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withAlpha(50))),
            child: Row(
              children: [
                const Icon(Iconsax.warning_2, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Low Stock Alert', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      Text('3 products need restocking', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                TextButton(onPressed: () {}, child: Text('View', style: GoogleFonts.poppins(color: Colors.orange, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _InventoryItem(name: 'Wireless Earbuds', sku: 'WE-001', stock: 45, lowStock: false, onEdit: () => _showEditStockDialog(context, 'Wireless Earbuds', 45)),
          _InventoryItem(name: 'Phone Case', sku: 'PC-002', stock: 5, lowStock: true, onEdit: () => _showEditStockDialog(context, 'Phone Case', 5)),
          _InventoryItem(name: 'USB Cable', sku: 'UC-003', stock: 120, lowStock: false, onEdit: () => _showEditStockDialog(context, 'USB Cable', 120)),
          _InventoryItem(name: 'Screen Protector', sku: 'SP-004', stock: 3, lowStock: true, onEdit: () => _showEditStockDialog(context, 'Screen Protector', 3)),
          _InventoryItem(name: 'Power Bank', sku: 'PB-005', stock: 28, lowStock: false, onEdit: () => _showEditStockDialog(context, 'Power Bank', 28)),
        ],
      ),
    );
  }

  void _showAddStockDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Stock', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(decoration: InputDecoration(labelText: 'Product Name', labelStyle: GoogleFonts.poppins(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 16),
            TextField(decoration: InputDecoration(labelText: 'SKU', labelStyle: GoogleFonts.poppins(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 16),
            TextField(keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Quantity', labelStyle: GoogleFonts.poppins(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Add Stock', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditStockDialog(BuildContext context, String name, int currentStock) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update Stock', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(name, style: GoogleFonts.poppins(color: Colors.grey[600])),
            const SizedBox(height: 20),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'New Quantity', hintText: currentStock.toString(), labelStyle: GoogleFonts.poppins(), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Update', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryItem extends StatelessWidget {
  final String name;
  final String sku;
  final int stock;
  final bool lowStock;
  final VoidCallback onEdit;

  const _InventoryItem({required this.name, required this.sku, required this.stock, required this.lowStock, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Text(sku, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: lowStock ? Colors.red.withAlpha(25) : Colors.green.withAlpha(25), borderRadius: BorderRadius.circular(8)),
            child: Text('$stock in stock', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: lowStock ? Colors.red : Colors.green)),
          ),
          const SizedBox(width: 8),
          IconButton(icon: Icon(Iconsax.edit_2, color: Colors.grey[600], size: 20), onPressed: onEdit),
        ],
      ),
    );
  }
}
