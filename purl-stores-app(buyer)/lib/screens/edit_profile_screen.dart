import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/colors.dart';
import '../services/currency_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _currencyService = CurrencyService();
  
  String _selectedGender = 'Male';
  String _selectedCurrency = 'UGX';
  DateTime? _selectedDate;
  bool _isLoading = true;

  final List<Map<String, String>> _currencies = [
    {'code': 'UGX', 'name': 'Ugandan Shilling', 'symbol': 'UGX'},
    {'code': 'KES', 'name': 'Kenyan Shilling', 'symbol': 'KES'},
    {'code': 'TZS', 'name': 'Tanzanian Shilling', 'symbol': 'TZS'},
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Load from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _emailController.text = user.email ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _selectedGender = data['gender'] ?? 'Male';
          _selectedCurrency = data['currency'] ?? 'UGX';
          
          if (data['dateOfBirth'] != null) {
            _selectedDate = (data['dateOfBirth'] as Timestamp).toDate();
          }
          
          _isLoading = false;
        });
      } else {
        // Fallback to Firebase Auth data
        setState(() {
          _emailController.text = user.email ?? '';
          if (user.displayName != null) {
            final parts = user.displayName!.split(' ');
            _firstNameController.text = parts.first;
            if (parts.length > 1) {
              _lastNameController.text = parts.sublist(1).join(' ');
            }
          }
          if (user.phoneNumber != null) {
            _phoneController.text = user.phoneNumber!;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBeige,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text('Save', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGreen)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProfilePicture(),
              const SizedBox(height: 32),
              _buildInputField('First Name', _firstNameController, Iconsax.user),
              const SizedBox(height: 16),
              _buildInputField('Last Name', _lastNameController, Iconsax.user),
              const SizedBox(height: 16),
              _buildInputField('Email', _emailController, Iconsax.sms, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildInputField('Phone Number', _phoneController, Iconsax.call, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildCurrencySelector(),
              const SizedBox(height: 16),
              _buildGenderSelector(),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildInputField('Bio', _bioController, Iconsax.edit, maxLines: 3),
              const SizedBox(height: 32),
              _buildDeleteAccountButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100, height: 100,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: const Center(child: Icon(Iconsax.user, size: 40, color: Colors.white)),
          ),
          Positioned(
            right: 0, bottom: 0,
            child: GestureDetector(
              onTap: _changeProfilePicture,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Iconsax.camera, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: AppColors.darkGreen),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: ['Male', 'Female', 'Other'].map((gender) => Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = gender),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedGender == gender ? AppColors.darkGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(gender, style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: _selectedGender == gender ? Colors.white : AppColors.textSecondary,
                    )),
                  ),
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preferred Currency', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: DropdownButtonFormField<String>(
            value: _selectedCurrency,
            decoration: const InputDecoration(
              prefixIcon: Icon(Iconsax.money, size: 20, color: AppColors.darkGreen),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            dropdownColor: Colors.white,
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
            items: _currencies.map((currency) {
              return DropdownMenuItem<String>(
                value: currency['code'],
                child: Text('${currency['symbol']} ${currency['name']}', style: GoogleFonts.poppins(fontSize: 14)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCurrency = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of Birth', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Icon(Iconsax.calendar, size: 20, color: AppColors.darkGreen),
                const SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Select date of birth',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _selectedDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                const Icon(Iconsax.arrow_down_1, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteAccountButton() {
    return GestureDetector(
      onTap: _showDeleteDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.trash, size: 20, color: AppColors.error),
            const SizedBox(width: 10),
            Text('Delete Account', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error)),
          ],
        ),
      ),
    );
  }

  void _changeProfilePicture() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('Change Profile Picture', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 24),
            _buildPhotoOption(Iconsax.camera, 'Take Photo', () => Navigator.pop(ctx)),
            const SizedBox(height: 12),
            _buildPhotoOption(Iconsax.gallery, 'Choose from Gallery', () => Navigator.pop(ctx)),
            const SizedBox(height: 12),
            _buildPhotoOption(Iconsax.trash, 'Remove Photo', () => Navigator.pop(ctx), isDestructive: true),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDestructive ? AppColors.error.withValues(alpha: 0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: isDestructive ? AppColors.error : AppColors.darkGreen),
            const SizedBox(width: 14),
            Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: isDestructive ? AppColors.error : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.darkGreen, onPrimary: Colors.white, surface: Colors.white, onSurface: AppColors.textPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName = '$firstName $lastName';

      // Update Firebase Auth display name
      await user.updateDisplayName(fullName);

      // Prepare data to save
      final Map<String, dynamic> userData = {
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'phoneNumber': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'gender': _selectedGender,
        'currency': _selectedCurrency,
        'email': user.email,
        'updatedAt': Timestamp.now(),
      };

      // Only add dateOfBirth if it's set
      if (_selectedDate != null) {
        userData['dateOfBirth'] = Timestamp.fromDate(_selectedDate!);
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      // Update currency service cache immediately
      await _currencyService.updateUserCurrency(_selectedCurrency);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: AppColors.darkGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        content: Text('Are you sure you want to delete your account? This action cannot be undone.', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Delete', style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
