import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedVehicleType = 'motorcycle'; // motorcycle or car
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      
      // Load existing courier data for old users
      try {
        final courierDoc = await FirebaseFirestore.instance
            .collection('couriers')
            .doc(user.uid)
            .get();
        
        if (courierDoc.exists) {
          final data = courierDoc.data();
          if (data != null) {
            setState(() {
              _nameController.text = data['fullName'] ?? user.displayName ?? '';
              _phoneController.text = data['phone'] ?? '';
              _selectedVehicleType = data['vehicleType'] ?? 'motorcycle';
            });
          }
        }
      } catch (e) {
        print('Error loading courier data: $e');
      }
    }
  }

  Future<void> _completeProfile() async {
    if (_isLoading) return;
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final uid = _authService.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      // Update courier profile with name and phone
      await FirebaseFirestore.instance.collection('couriers').doc(uid).update({
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'vehicleType': _selectedVehicleType, // Add vehicle type
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) context.push('/phone-verification');
    } catch (e) {
      _showError('Failed to update profile. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () async {
            // Sign out and go back to welcome
            await _authService.signOut();
            if (mounted) context.go('/welcome');
          },
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: const Text('Complete Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete Your Profile',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'We need a few more details to set up your courier account',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              
              const SizedBox(height: 40),
              
              // Full Name
              Text(
                'Full Name',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'John Doe',
                  prefixIcon: Icon(Iconsax.user),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Vehicle Type
              Text(
                'Vehicle Type',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              
              // Motorcycle Option
              GestureDetector(
                onTap: () => setState(() => _selectedVehicleType = 'motorcycle'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedVehicleType == 'motorcycle' ? const Color(0xFFb71000) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedVehicleType == 'motorcycle' ? const Color(0xFFb71000) : Colors.grey[300]!,
                      width: _selectedVehicleType == 'motorcycle' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.driving5,
                        size: 24,
                        color: _selectedVehicleType == 'motorcycle' ? Colors.white : Colors.black,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Motorcycle',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _selectedVehicleType == 'motorcycle' ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              'For standard packages (under 15 kg)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _selectedVehicleType == 'motorcycle' ? Colors.white70 : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedVehicleType == 'motorcycle')
                        const Icon(Iconsax.tick_circle5, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Car Option
              GestureDetector(
                onTap: () => setState(() => _selectedVehicleType = 'car'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedVehicleType == 'car' ? const Color(0xFFb71000) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedVehicleType == 'car' ? const Color(0xFFb71000) : Colors.grey[300]!,
                      width: _selectedVehicleType == 'car' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.car5,
                        size: 24,
                        color: _selectedVehicleType == 'car' ? Colors.white : Colors.black,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Car/Vehicle',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _selectedVehicleType == 'car' ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              'For bulky packages (over 15 kg)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _selectedVehicleType == 'car' ? Colors.white70 : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedVehicleType == 'car')
                        const Icon(Iconsax.tick_circle5, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              Text(
                'Phone Number',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '+256 700 000 000',
                  prefixIcon: Icon(Iconsax.call),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeProfile,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
