import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/verification_service.dart';
import '../services/flutterwave_service.dart';
import '../services/store_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

class StoreVerificationScreen extends StatefulWidget {
  final bool isRenewal;

  const StoreVerificationScreen({
    super.key,
    this.isRenewal = false,
  });

  @override
  State<StoreVerificationScreen> createState() => _StoreVerificationScreenState();
}

class _StoreVerificationScreenState extends State<StoreVerificationScreen> {
  final _verificationService = VerificationService();
  final _paymentService = FlutterwaveService();
  final _storeService = StoreService();
  final _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Form fields
  final _ownerNameController = TextEditingController();
  final _locationController = TextEditingController();
  File? _idDocumentFront;
  File? _idDocumentBack;
  File? _faceScan;
  bool _isLoadingLocation = false;
  String? _selectedLat;
  String? _selectedLng;

  // Payment fields
  String? _selectedPaymentLogo;
  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isProcessing = false;
  int _currentStep = 0; // 0: Form, 1: Payment

  static const double VERIFICATION_FEE = 4.99;
  static const double VERIFICATION_FEE_UGX = 18712.5; // 4.99 * 3750

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Set cardholder name from user profile
      _cardHolderController.text = user.displayName ?? '';
      
      // Load store name
      await _loadStoreName();
    }
  }

  Future<void> _loadStoreName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final storeDoc = await FirebaseFirestore.instance
            .collection('stores')
            .where('authorizedUsers', arrayContains: user.uid)
            .limit(1)
            .get();

        if (storeDoc.docs.isNotEmpty) {
          final storeData = storeDoc.docs.first.data();
          final storeName = storeData['name'] as String?;
          
          if (storeName != null && storeName.isNotEmpty) {
            setState(() {
              _ownerNameController.text = storeName;
            });
          }
        }
      }
    } catch (e) {
      print('❌ Error loading store name: $e');
    }
  }

  Future<void> _loadGPSLocation() async {
    // Google Places will handle location selection
    setState(() => _isLoadingLocation = false);
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _locationController.dispose();
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If status is pending or verified, show status screen instead of form
    if (widget.isRenewal == false) {
      return FutureBuilder<VerificationStatus>(
        future: _getVerificationStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Iconsax.arrow_left, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Get Verified',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                centerTitle: true,
              ),
              body: const Center(child: CircularProgressIndicator(color: Colors.black)),
            );
          }

          if (snapshot.data == VerificationStatus.pending) {
            return _buildPendingScreen();
          }

          if (snapshot.data == VerificationStatus.verified) {
            return _buildVerifiedScreen();
          }

          return _buildVerificationForm();
        },
      );
    }

    return _buildVerificationForm();
  }

  Future<VerificationStatus> _getVerificationStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return VerificationStatus.none;
      }

      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .where('authorizedUsers', arrayContains: user.uid)
          .limit(1)
          .get();

      if (storeDoc.docs.isEmpty) {
        print('❌ No store found for user');
        return VerificationStatus.none;
      }

      final storeId = storeDoc.docs.first.id;
      final status = await _verificationService.getVerificationStatus(storeId);
      print('✅ Verification status: $status');
      return status;
    } catch (e) {
      print('❌ Error getting verification status: $e');
      return VerificationStatus.none;
    }
  }

  Widget _buildPendingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verification Status',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.clock,
                  size: 64,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Verification Pending',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your verification request has been submitted and is being reviewed by our team.',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'This typically takes 24-48 hours. We\'ll notify you once your store is verified.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Back to Home',
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

  Widget _buildVerifiedScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getVerificationData(),
        builder: (context, snapshot) {
          final storeName = snapshot.data?['storeName'] ?? 'Your Store';
          final verifiedDate = snapshot.data?['verifiedDate'] ?? 'Recently';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Professional gradient card
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFb71000), // Button red
                          Color(0xFFfb2a0a), // Main red
                          Color(0xFFe02509), // Hover red
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFfb2a0a).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeName,
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Verified since $verifiedDate',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          'Trust is the cornerstone of our community, and identity verification is part of how we build it.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.85),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Info Text
                Text(
                  'Our identity verification process checks a store\'s information against trusted third-party sources or a government ID. The process has safeguards but doesn\'t guarantee that someone is who they say they are.',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.grey[800],
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 24),

                // Learn More Link
                GestureDetector(
                  onTap: () {
                    // TODO: Open learn more page
                  },
                  child: Text(
                    'Learn more',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: const Color(0xFFfb2a0a),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _getVerificationData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {};

      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .where('authorizedUsers', arrayContains: user.uid)
          .limit(1)
          .get();

      if (storeDoc.docs.isEmpty) return {};

      final storeData = storeDoc.docs.first.data();
      final storeName = storeData['name'] as String? ?? 'Your Store';
      
      // Try to get date from approvedAt first, then from lastVerificationPayment
      Timestamp? verifiedAt = storeData['verificationData']?['approvedAt'] as Timestamp?;
      
      if (verifiedAt == null) {
        // Try lastVerificationPayment.paidAt
        verifiedAt = storeData['lastVerificationPayment']?['paidAt'] as Timestamp?;
      }
      
      String verifiedDate;
      if (verifiedAt != null) {
        final date = verifiedAt.toDate();
        final monthNames = ['January', 'February', 'March', 'April', 'May', 'June',
                           'July', 'August', 'September', 'October', 'November', 'December'];
        verifiedDate = '${monthNames[date.month - 1]} ${date.year}';
      } else {
        // Fallback to current date
        final now = DateTime.now();
        final monthNames = ['January', 'February', 'March', 'April', 'May', 'June',
                           'July', 'August', 'September', 'October', 'November', 'December'];
        verifiedDate = '${monthNames[now.month - 1]} ${now.year}';
      }

      return {
        'storeName': storeName,
        'verifiedDate': verifiedDate,
      };
    } catch (e) {
      print('Error loading verification data: $e');
      return {};
    }
  }

  Widget _buildVerificationForm() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isRenewal ? 'Renew Verification' : 'Get Verified',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _currentStep == 0 ? _buildFormStep() : _buildPaymentStep(),
    );
  }

  Widget _buildFormStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.verify, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Store Verification',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '\$${VERIFICATION_FEE.toStringAsFixed(2)}/month • Get the verified badge',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (!widget.isRenewal) ...[
              // Store Name (read-only, auto-filled)
              Text(
                'Store Name',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ownerNameController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Loading store name...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: Icon(Icons.lock_outline, color: Colors.grey[400], size: 20),
                ),
              ),

              const SizedBox(height: 20),

              // Location (Google Places Autocomplete)
              Text(
                'Store Location',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GooglePlaceAutoCompleteTextField(
                textEditingController: _locationController,
                googleAPIKey: "AIzaSyAkTfLh7iFXsGJ4baSpRtzglNvlHhNmRHY",
                inputDecoration: InputDecoration(
                  hintText: 'Start typing your location...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: Icon(Iconsax.location, color: Colors.grey[600], size: 20),
                ),
                debounceTime: 800,
                countries: const ["ug"], // Uganda only
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  print('📍 Selected: ${prediction.description}');
                  print('📍 Lat: ${prediction.lat}, Lng: ${prediction.lng}');
                  setState(() {
                    _locationController.text = prediction.description ?? '';
                    _selectedLat = prediction.lat;
                    _selectedLng = prediction.lng;
                  });
                },
                itemClick: (Prediction prediction) {
                  _locationController.text = prediction.description ?? '';
                  _locationController.selection = TextSelection.fromPosition(
                    TextPosition(offset: prediction.description?.length ?? 0),
                  );
                },
                itemBuilder: (context, index, Prediction prediction) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Iconsax.location, size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            prediction.description ?? "",
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                seperatedBuilder: Divider(height: 1, color: Colors.grey[200]),
                isCrossBtnShown: true,
                containerHorizontalPadding: 0,
              ),

              const SizedBox(height: 20),

              // Face Scan
              Text(
                'Face Verification',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _startFaceScan,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    image: _faceScan != null
                        ? DecorationImage(
                            image: FileImage(_faceScan!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _faceScan == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.scan, size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to Start Face Scan',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '5 second scan',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              // ID Document Front
              Text(
                'ID Document (Front)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickIdDocument(isFront: true),
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    image: _idDocumentFront != null
                        ? DecorationImage(
                            image: FileImage(_idDocumentFront!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _idDocumentFront == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.document_upload, size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Upload Front Side',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Tap to select',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              // ID Document Back
              Text(
                'ID Document (Back)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickIdDocument(isFront: false),
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    image: _idDocumentBack != null
                        ? DecorationImage(
                            image: FileImage(_idDocumentBack!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _idDocumentBack == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.document_upload, size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Upload Back Side',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Tap to select',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 24),

              // Info box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your information will be reviewed by our team. Verification typically takes 24-48 hours.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (widget.isRenewal) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Iconsax.refresh, size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text(
                      'Renew Your Verification',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your verification has expired. Renew now to keep your verified badge.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Continue button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _continueToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continue to Payment',
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
    );
  }

  Future<void> _pickIdDocument({required bool isFront}) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        if (isFront) {
          _idDocumentFront = File(picked.path);
        } else {
          _idDocumentBack = File(picked.path);
        }
      });
    }
  }

  void _continueToPayment() {
    if (!widget.isRenewal) {
      if (!_formKey.currentState!.validate()) return;
      if (_idDocumentFront == null || _idDocumentBack == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please upload both front and back of your ID', style: GoogleFonts.poppins()),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (_faceScan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please complete face verification', style: GoogleFonts.poppins()),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    setState(() => _currentStep = 1);
  }

  Future<void> _startFaceScan() async {
    // TODO: Implement actual face scan with camera
    // For now, use image picker as placeholder
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );
    
    if (picked != null) {
      setState(() => _faceScan = File(picked.path));
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Face scan completed', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildPaymentStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Verification Fee',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '\$${VERIFICATION_FEE.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount (UGX)',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'UGX ${VERIFICATION_FEE_UGX.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Payment Method
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment Method',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('Add', style: GoogleFonts.poppins(fontSize: 14)),
                      style: TextButton.styleFrom(foregroundColor: Colors.black),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Payment logos
                Row(
                  children: [
                    _buildPaymentLogo('visa', 'assets/images/visa.jpeg'),
                    const SizedBox(width: 12),
                    _buildPaymentLogo('mastercard', 'assets/images/mastercard.jpeg'),
                    const SizedBox(width: 12),
                    _buildPaymentLogo('mtn', 'assets/images/mtn.jpeg'),
                    const SizedBox(width: 12),
                    _buildPaymentLogo('airtel', 'assets/images/airtel.jpeg'),
                  ],
                ),

                const SizedBox(height: 24),

                // Payment form
                if (_selectedPaymentLogo == 'visa' || _selectedPaymentLogo == 'mastercard')
                  _buildCardForm()
                else if (_selectedPaymentLogo == 'mtn' || _selectedPaymentLogo == 'airtel')
                  _buildMobileMoneyForm(),
              ],
            ),
          ),
        ),

        // Pay button
        if (_selectedPaymentLogo != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Pay UGX ${VERIFICATION_FEE_UGX.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentLogo(String method, String assetPath) {
    final isSelected = _selectedPaymentLogo == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentLogo = method),
      child: Container(
        width: 70,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(assetPath, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Details',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Card Holder Name
        TextFormField(
          controller: _cardHolderController,
          decoration: InputDecoration(
            labelText: 'Cardholder Name',
            labelStyle: GoogleFonts.poppins(fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        
        // Card Number
        TextFormField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _CardNumberFormatter(),
          ],
          decoration: InputDecoration(
            labelText: 'Card Number',
            labelStyle: GoogleFonts.poppins(fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Required';
            if (value!.replaceAll(' ', '').length < 16) return 'Invalid card number';
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Expiry and CVV
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryDateFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'MM/YY',
                  labelStyle: GoogleFonts.poppins(fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (value!.length < 5) return 'Invalid';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  labelText: 'CVV',
                  labelStyle: GoogleFonts.poppins(fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (value!.length < 3) return 'Invalid';
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileMoneyForm() {
    final networkName = _selectedPaymentLogo == 'mtn' ? 'MTN' : 'Airtel';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phone Number', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            hintText: '0700000000',
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            prefixText: '+256 ',
            prefixStyle: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w500),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You\'ll receive a prompt on your $networkName number to complete payment',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      if (_selectedPaymentLogo == 'visa' || _selectedPaymentLogo == 'mastercard') {
        await _processCardPayment();
      } else {
        await _processMobileMoneyPayment();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processCardPayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cardNumber = _cardNumberController.text.replaceAll(' ', '').replaceAll('-', '');
    final expiry = _expiryController.text.split('/');
    final expiryMonth = expiry[0].trim();
    final expiryYear = '20${expiry[1].trim()}';

    // Show processing dialog
    _showProcessingDialog();

    final result = await _paymentService.chargeCard(
      cardNumber: cardNumber,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      cvv: _cvvController.text,
      amount: VERIFICATION_FEE_UGX,
      currency: 'UGX',
      email: user.email ?? '',
      fullname: _cardHolderController.text,
      phoneNumber: user.phoneNumber,
    );

    if (mounted) {
      Navigator.of(context).pop(); // Close processing dialog
      
      // Check for errors first
      if (!result.success && result.error != null) {
        setState(() => _isProcessing = false);
        
        String errorMessage = result.error!;
        if (errorMessage.contains('limit') || errorMessage.contains('3000') || errorMessage.contains('amount')) {
          errorMessage = 'Test account limit exceeded. Please use \$1 or less for testing.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }
      
      // Check if redirect is needed for verification
      if (result.redirectUrl != null && result.redirectUrl!.isNotEmpty) {
        final verified = await _openVerificationWebview(
          result.redirectUrl!,
          result.txRef ?? '',
        );
        
        if (!verified) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment verification failed or cancelled', style: GoogleFonts.poppins()),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }
      
      setState(() => _isProcessing = false);
      
      if (result.success || result.status == 'successful') {
        await _completeVerification(result.transactionId ?? 'card_${DateTime.now().millisecondsSinceEpoch}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? result.message ?? 'Payment failed', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processMobileMoneyPayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final phone = '256${_phoneController.text}';
    final network = _selectedPaymentLogo == 'mtn' ? 'MTN' : 'AIRTEL';

    // Show processing dialog
    _showProcessingDialog();

    final result = await _paymentService.chargeMobileMoney(
      phoneNumber: phone,
      network: network,
      amount: VERIFICATION_FEE_UGX,
      currency: 'UGX',
      email: user.email ?? '',
      fullname: user.displayName ?? _cardHolderController.text,
    );

    if (mounted) {
      Navigator.of(context).pop(); // Close processing dialog
      
      // Check if redirect is needed for verification
      if (result.redirectUrl != null && result.redirectUrl!.isNotEmpty) {
        final verified = await _openVerificationWebview(
          result.redirectUrl!,
          result.txRef ?? '',
        );
        
        if (!verified) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment verification failed', style: GoogleFonts.poppins()),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } else {
        // No redirect - show message to check phone
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? 'Check your phone to approve the payment',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.grey[700],
            duration: const Duration(seconds: 5),
          ),
        );
        
        // Poll for payment status
        final verified = await _pollPaymentStatus(result.txRef ?? '');
        
        if (!verified) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment not completed', style: GoogleFonts.poppins()),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }
      
      setState(() => _isProcessing = false);
      
      if (result.success || result.status == 'pending') {
        await _completeVerification(result.transactionId ?? 'momo_${DateTime.now().millisecondsSinceEpoch}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? result.message ?? 'Payment failed', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.black),
                const SizedBox(height: 20),
                Text(
                  'Processing Payment',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _completeVerification(String transactionId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get store ID
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .where('authorizedUsers', arrayContains: user.uid)
          .limit(1)
          .get();

      if (storeDoc.docs.isEmpty) {
        throw Exception('Store not found');
      }

      final storeId = storeDoc.docs.first.id;

      if (widget.isRenewal) {
        // Renew verification
        await _verificationService.renewVerification(
          storeId: storeId,
          transactionId: transactionId,
          amount: VERIFICATION_FEE,
        );
      } else {
        // Submit verification and record payment
        await _verificationService.submitVerification(
          storeId: storeId,
          ownerName: _ownerNameController.text,
          idDocumentFront: _idDocumentFront!,
          idDocumentBack: _idDocumentBack!,
          faceScan: _faceScan!,
          location: _locationController.text,
        );
        
        await _verificationService.recordVerificationPayment(
          storeId: storeId,
          transactionId: transactionId,
          amount: VERIFICATION_FEE,
        );
      }

      // Show success
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.green[700], size: 48),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.isRenewal ? 'Verification Renewed!' : 'Payment Successful!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isRenewal
                      ? 'Your verification has been renewed for 30 days.'
                      : 'Your verification request has been submitted. We\'ll review it within 24-48 hours.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Done', style: GoogleFonts.poppins()),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _openVerificationWebview(String redirectUrl, String txRef) async {
    bool urlOpened = false;
    try {
      final uri = Uri.parse(redirectUrl);
      urlOpened = await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('❌ Error opening URL: $e');
    }
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Complete Verification', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.security, size: 48, color: Colors.black),
            const SizedBox(height: 16),
            Text(
              urlOpened 
                ? 'Verification page opened in browser'
                : 'Please open this link in your browser:',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (!urlOpened) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  try {
                    final uri = Uri.parse(redirectUrl);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    print('Error: $e');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    redirectUrl,
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Complete the verification and return here',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              final verified = await _verifyPaymentStatus(txRef);
              Navigator.of(context).pop(verified);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: Text('I Completed It', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _verifyPaymentStatus(String txRef) async {
    final result = await _paymentService.verifyPayment(txRef: txRef);
    return result.success && result.status == 'successful';
  }

  Future<bool> _pollPaymentStatus(String txRef) async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PollingDialog(
        txRef: txRef,
        paymentService: _paymentService,
      ),
    );
    
    return result ?? false;
  }
}

// Card number formatter
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Expiry date formatter
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Polling Dialog for Mobile Money
class _PollingDialog extends StatefulWidget {
  final String txRef;
  final FlutterwaveService paymentService;

  const _PollingDialog({
    required this.txRef,
    required this.paymentService,
  });

  @override
  State<_PollingDialog> createState() => _PollingDialogState();
}

class _PollingDialogState extends State<_PollingDialog> {
  int _attempts = 0;
  final int _maxAttempts = 20;
  bool _isPolling = true;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  Future<void> _startPolling() async {
    while (_isPolling && _attempts < _maxAttempts) {
      await Future.delayed(const Duration(seconds: 3));
      
      if (!_isPolling || !mounted) break;
      
      _attempts++;
      
      final result = await widget.paymentService.verifyPayment(txRef: widget.txRef);
      
      if (!mounted) break;
      
      if (result.success && result.status == 'successful') {
        Navigator.of(context).pop(true);
        return;
      }
      
      if (result.status == 'failed') {
        Navigator.of(context).pop(false);
        return;
      }
    }
    
    if (mounted && _isPolling) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  void dispose() {
    _isPolling = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.black),
              const SizedBox(height: 20),
              Text(
                'Waiting for Payment',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please approve the payment on your phone',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _isPolling = false;
                  Navigator.of(context).pop(false);
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
