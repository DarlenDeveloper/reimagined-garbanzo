import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final List<Map<String, dynamic>> _users = [
    {'name': 'John Doe', 'email': 'john@store.com', 'role': 'Owner', 'isActive': true},
    {'name': 'Jane Smith', 'email': 'jane@store.com', 'role': 'Admin', 'isActive': true},
    {'name': 'Mike Johnson', 'email': 'mike@store.com', 'role': 'Manager', 'isActive': true},
    {'name': 'Sarah Williams', 'email': 'sarah@store.com', 'role': 'Staff', 'isActive': false},
  ];

  void _showInviteUserSheet() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = 'Staff';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600]))),
                  Text('Invite Team Member', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                        setState(() {
                          _users.add({'name': nameController.text, 'email': emailController.text, 'role': selectedRole, 'isActive': true});
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invitation sent', style: GoogleFonts.poppins()), backgroundColor: Colors.black));
                      }
                    },
                    child: Text('Invite', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildField('Full Name', nameController, 'Enter name'),
                  const SizedBox(height: 16),
                  _buildField('Email Address', emailController, 'email@example.com', keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  Text('Role', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  StatefulBuilder(
                    builder: (context, setDropdownState) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          isExpanded: true,
                          style: GoogleFonts.poppins(color: Colors.black),
                          items: ['Admin', 'Manager', 'Staff'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: (v) => setDropdownState(() => selectedRole = v!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Role Permissions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Admin: Full access except billing\nManager: Products, orders, inventory\nStaff: Orders only', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], height: 1.5)),
                      ],
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

  Widget _buildField(String label, TextEditingController controller, String hint, {TextInputType? keyboardType}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text('Team', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showInviteUserSheet, backgroundColor: Colors.black, child: const Icon(Iconsax.user_add, color: Colors.white)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: Colors.black, child: Text(user['name'][0], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      Text(user['email'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                      child: Text(user['role'], style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Iconsax.tick_circle, size: 12, color: user['isActive'] ? Colors.green : Colors.grey),
                        const SizedBox(width: 4),
                        Text(user['isActive'] ? 'Active' : 'Inactive', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
