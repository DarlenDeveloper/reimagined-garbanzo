import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import 'camera_capture_screen.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _authService = AuthService();
  final _idNumberController = TextEditingController();
  final _vehicleNameController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _nextOfKinNameController = TextEditingController();
  final _nextOfKinPhoneController = TextEditingController();
  final _nextOfKinNINController = TextEditingController();
  
  String? _idFrontPath;
  String? _idBackPath;
  String? _faceVideoPath;
  
  bool _isLoading = false;

  Future<void> _captureIdPhoto(String type) async {
    // Show bottom sheet with options
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Choose Photo Source',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Iconsax.camera),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera to capture ID'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Iconsax.gallery),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select existing photo'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      String? result;
      
      if (source == ImageSource.camera) {
        // Use custom camera screen
        result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => CameraCaptureScreen(
              title: type == 'front' ? 'Capture ID Front' : 'Capture ID Back',
              type: 'photo',
            ),
          ),
        );
      } else {
        // Use image picker for gallery
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        result = image?.path;
      }
      
      if (result != null) {
        setState(() {
          if (type == 'front') {
            _idFrontPath = result;
          } else if (type == 'back') {
            _idBackPath = result;
          }
        });
      }
    } catch (e) {
      _showError('Failed to get photo');
    }
  }

  Future<void> _captureFaceScan() async {
    try {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const CameraCaptureScreen(
            title: 'Face Scan',
            type: 'face_scan',
            maxDuration: 10,
          ),
        ),
      );
      
      if (result != null) {
        setState(() => _faceVideoPath = result);
      }
    } catch (e) {
      _showError('Failed to record face scan');
    }
  }

  Future<String?> _uploadFile(String filePath, String storagePath) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      await ref.putFile(File(filePath));
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _submitVerification() async {
    if (_isLoading) return;
    
    // Validate all fields
    if (_idNumberController.text.isEmpty ||
        _vehicleNameController.text.isEmpty ||
        _plateNumberController.text.isEmpty ||
        _nextOfKinNameController.text.isEmpty ||
        _nextOfKinPhoneController.text.isEmpty ||
        _nextOfKinNINController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    if (_idFrontPath == null || _idBackPath == null || _faceVideoPath == null) {
      _showError('Please capture all required documents');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final uid = _authService.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      // Upload files
      final idFrontUrl = await _uploadFile(
        _idFrontPath!,
        'couriers/$uid/id_front.jpg',
      );
      final idBackUrl = await _uploadFile(
        _idBackPath!,
        'couriers/$uid/id_back.jpg',
      );
      final faceVideoUrl = await _uploadFile(
        _faceVideoPath!,
        'couriers/$uid/face_scan.mp4',
      );

      if (idFrontUrl == null || idBackUrl == null || faceVideoUrl == null) {
        throw Exception('Failed to upload documents');
      }

      // Submit verification
      await _authService.submitVerification(
        idNumber: _idNumberController.text.trim(),
        vehicleName: _vehicleNameController.text.trim(),
        plateNumber: _plateNumberController.text.trim(),
        nextOfKinName: _nextOfKinNameController.text.trim(),
        nextOfKinPhone: _nextOfKinPhoneController.text.trim(),
        nextOfKinNIN: _nextOfKinNINController.text.trim(),
        idFrontUrl: idFrontUrl,
        idBackUrl: idBackUrl,
        faceVideoUrl: faceVideoUrl,
      );

      if (mounted) {
        context.go('/pending-verification');
      }
    } catch (e) {
      _showError('Failed to submit verification. Please try again.');
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
    _idNumberController.dispose();
    _vehicleNameController.dispose();
    _plateNumberController.dispose();
    _nextOfKinNameController.dispose();
    _nextOfKinPhoneController.dispose();
    _nextOfKinNINController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: const Text('Verification'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify Your Identity',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'We need to verify your documents to ensure safety',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              
              const SizedBox(height: 32),
              
              // Personal Information Section
              _buildSectionTitle('Personal Information'),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _idNumberController,
                label: 'National ID Number (NIN)',
                hint: 'CM1234567890123',
                icon: Iconsax.card,
              ),
              
              const SizedBox(height: 32),
              
              // Vehicle Information Section
              _buildSectionTitle('Vehicle Information'),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _vehicleNameController,
                label: 'Vehicle Name/Model',
                hint: 'Honda CB 125',
                icon: Iconsax.car,
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _plateNumberController,
                label: 'Number Plate',
                hint: 'UAX 123A',
                icon: Iconsax.hashtag,
              ),
              
              const SizedBox(height: 32),
              
              // Next of Kin Section
              _buildSectionTitle('Next of Kin'),
              const SizedBox(height: 8),
              Text(
                'Emergency contact information',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _nextOfKinNameController,
                label: 'Full Name',
                hint: 'Jane Doe',
                icon: Iconsax.user,
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _nextOfKinPhoneController,
                label: 'Phone Number',
                hint: '+256 700 000 000',
                icon: Iconsax.call,
                keyboardType: TextInputType.phone,
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _nextOfKinNINController,
                label: 'National ID Number (NIN)',
                hint: 'CM1234567890123',
                icon: Iconsax.card,
              ),
              
              const SizedBox(height: 32),
              
              // Document Upload Section
              _buildSectionTitle('Upload Documents'),
              const SizedBox(height: 16),
              
              _buildCaptureButton(
                'ID Front Photo',
                _idFrontPath != null,
                () => _captureIdPhoto('front'),
                Iconsax.card,
              ),
              
              const SizedBox(height: 12),
              
              _buildCaptureButton(
                'ID Back Photo',
                _idBackPath != null,
                () => _captureIdPhoto('back'),
                Iconsax.card,
              ),
              
              const SizedBox(height: 12),
              
              _buildCaptureButton(
                'Face Scan Video (10 seconds)',
                _faceVideoPath != null,
                _captureFaceScan,
                Iconsax.video_circle,
              ),
              
              const SizedBox(height: 40),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitVerification,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Submit Application'),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'By submitting, you agree that all information provided is accurate and can be verified.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptureButton(
    String label,
    bool captured,
    VoidCallback onTap,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: captured ? const Color(0xFFfb2a0a).withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: captured ? const Color(0xFFfb2a0a) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              captured ? Iconsax.tick_circle : icon,
              color: captured ? const Color(0xFFfb2a0a) : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                captured ? '$label ✓' : label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: captured ? const Color(0xFFfb2a0a) : Colors.black,
                    ),
              ),
            ),
            Icon(
              Iconsax.camera,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
