import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class VehicleInfoScreen extends StatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  String _selectedVehicleType = 'motorcycle';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleType();
  }

  Future<void> _loadVehicleType() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('couriers').doc(uid).get();
    final vehicleType = doc.data()?['vehicleType'] as String?;
    
    setState(() {
      _selectedVehicleType = vehicleType ?? 'motorcycle';
      _isLoading = false;
    });
  }

  Future<void> _saveVehicleType() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      final uid = AuthService().currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      await FirebaseFirestore.instance.collection('couriers').doc(uid).update({
        'vehicleType': _selectedVehicleType,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle type updated successfully'),
            backgroundColor: const Color(0xFFb71000),
          ),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update vehicle type'),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          'Vehicle Information',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select your vehicle type',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This determines which deliveries you can accept',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Motorcycle Option
                    GestureDetector(
                      onTap: () => setState(() => _selectedVehicleType = 'motorcycle'),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _selectedVehicleType == 'motorcycle' ? const Color(0xFFb71000) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedVehicleType == 'motorcycle' ? const Color(0xFFb71000) : Colors.grey[300]!,
                            width: _selectedVehicleType == 'motorcycle' ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_selectedVehicleType == 'motorcycle' ? const Color(0xFFb71000) : Colors.black)
                                  .withOpacity(_selectedVehicleType == 'motorcycle' ? 0.15 : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: _selectedVehicleType == 'motorcycle' 
                                    ? Colors.white.withOpacity(0.2) 
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  Iconsax.driving5,
                                  size: 32,
                                  color: _selectedVehicleType == 'motorcycle' ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Motorcycle',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedVehicleType == 'motorcycle' ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Standard packages under 15 kg',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: _selectedVehicleType == 'motorcycle' 
                                          ? Colors.white.withOpacity(0.85) 
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedVehicleType == 'motorcycle')
                              const Icon(Iconsax.tick_circle5, color: Colors.white, size: 24),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Car Option
                    GestureDetector(
                      onTap: () => setState(() => _selectedVehicleType = 'car'),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _selectedVehicleType == 'car' ? const Color(0xFFb71000) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedVehicleType == 'car' ? const Color(0xFFb71000) : Colors.grey[300]!,
                            width: _selectedVehicleType == 'car' ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_selectedVehicleType == 'car' ? const Color(0xFFb71000) : Colors.black)
                                  .withOpacity(_selectedVehicleType == 'car' ? 0.15 : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: _selectedVehicleType == 'car' 
                                    ? Colors.white.withOpacity(0.2) 
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  Iconsax.car5,
                                  size: 32,
                                  color: _selectedVehicleType == 'car' ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Car/Vehicle',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedVehicleType == 'car' ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'All packages including bulky items',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: _selectedVehicleType == 'car' 
                                          ? Colors.white.withOpacity(0.85) 
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedVehicleType == 'car')
                              const Icon(Iconsax.tick_circle5, color: Colors.white, size: 24),
                          ],
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveVehicleType,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFb71000),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          disabledBackgroundColor: Colors.grey[400],
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
