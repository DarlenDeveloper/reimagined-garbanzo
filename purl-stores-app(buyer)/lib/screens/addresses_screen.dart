import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  int _selectedIndex = 0;
  final List<_Address> _addresses = [
    _Address(id: '1', label: 'Home', name: 'John Doe', phone: '+1 234 567 8900', address: '200 W 45th St, Apt 4B', city: 'New York, NY 10036', isDefault: true),
    _Address(id: '2', label: 'Office', name: 'John Doe', phone: '+1 234 567 8901', address: '350 5th Avenue, Floor 21', city: 'New York, NY 10118', isDefault: false),
    _Address(id: '3', label: 'Parents', name: 'Robert Doe', phone: '+1 234 567 8902', address: '742 Evergreen Terrace', city: 'Springfield, IL 62701', isDefault: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBeige,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('My Addresses', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _addresses.length,
        itemBuilder: (context, index) => _buildAddressCard(_addresses[index], index),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _addNewAddress,
            icon: const Icon(Iconsax.add),
            label: Text('Add New Address', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(_Address addr, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.darkGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(addr.label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkGreen)),
                ),
                if (addr.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFFB800).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text('Default', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFFD4A000))),
                  ),
                ],
                const Spacer(),
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.darkGreen : Colors.transparent,
                  ),
                  child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceVariant)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(addr.name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(addr.phone, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(addr.address, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary)),
            Text(addr.city, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildActionButton(Iconsax.edit_2, 'Edit', () {}),
                const SizedBox(width: 12),
                _buildActionButton(Iconsax.trash, 'Delete', () => _deleteAddress(addr.id)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _addNewAddress() {}
  void _deleteAddress(String id) {
    setState(() => _addresses.removeWhere((a) => a.id == id));
  }
}

class _Address {
  final String id, label, name, phone, address, city;
  final bool isDefault;
  _Address({required this.id, required this.label, required this.name, required this.phone, required this.address, required this.city, required this.isDefault});
}
