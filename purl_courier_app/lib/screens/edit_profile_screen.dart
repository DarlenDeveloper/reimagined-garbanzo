import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isLoading = true;
  String _fullName = '';
  String _phone = '';
  String _email = '';
  String _vehicleType = '';
  String _status = '';
  String _rating = '';
  String _totalDeliveries = '';
  String _totalEarnings = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('couriers').doc(uid).get();
    final data = doc.data();
    
    if (data != null) {
      setState(() {
        _fullName = data['fullName'] ?? '';
        _phone = data['phone'] ?? '';
        _email = data['email'] ?? '';
        _vehicleType = data['vehicleType'] ?? '';
        _status = data['status'] ?? '';
        _rating = (data['rating'] ?? 0.0).toStringAsFixed(1);
        _totalDeliveries = (data['totalDeliveries'] ?? 0).toString();
        _totalEarnings = 'UGX ${(data['totalEarnings'] ?? 0.0).toStringAsFixed(0)}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildReadOnlyField('Full Name', _fullName),
                const SizedBox(height: 16),
                _buildReadOnlyField('Phone Number', _phone),
                const SizedBox(height: 16),
                _buildReadOnlyField('Email', _email),
                const SizedBox(height: 16),
                _buildReadOnlyField('Vehicle Type', _vehicleType == 'motorcycle' ? 'Motorcycle' : _vehicleType == 'car' ? 'Car/Vehicle' : 'Not Set'),
                const SizedBox(height: 16),
                _buildReadOnlyField('Status', _status.replaceAll('_', ' ').toUpperCase()),
                const SizedBox(height: 16),
                _buildReadOnlyField('Rating', _rating),
                const SizedBox(height: 16),
                _buildReadOnlyField('Total Deliveries', _totalDeliveries),
                const SizedBox(height: 16),
                _buildReadOnlyField('Total Earnings', _totalEarnings),
              ],
            ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value.isEmpty ? 'Not Set' : value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
