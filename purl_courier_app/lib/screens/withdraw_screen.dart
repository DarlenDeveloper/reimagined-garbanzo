import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  double _availableBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final userId = AuthService().currentUser?.uid;
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('couriers')
        .doc(userId)
        .get();
    
    final data = doc.data();
    if (data != null) {
      setState(() {
        _availableBalance = (data['totalEarnings'] ?? 0.0).toDouble();
      });
    }
  }

  Future<void> _submitWithdrawRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (amount > _availableBalance) {
      _showError('Insufficient balance');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = AuthService().currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Create withdraw request
      await FirebaseFirestore.instance.collection('withdrawRequests').add({
        'courierId': userId,
        'amount': amount,
        'recipientName': _nameController.text.trim(),
        'mobileMoneyNumber': _phoneController.text.trim(),
        'status': 'pending', // pending, approved, rejected, completed
        'requestedAt': FieldValue.serverTimestamp(),
        'processedAt': null,
        'processedBy': null,
        'notes': '',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Withdraw request submitted successfully'),
            backgroundColor: Color(0xFFfb2a0a),
          ),
        );
        context.pop();
      }
    } catch (e) {
      _showError('Failed to submit request: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Withdraw Funds'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Available Balance Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFfb2a0a),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Available Balance',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'UGX ${_availableBalance.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Amount Field
                Text(
                  'Withdrawal Amount',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Enter amount',
                    prefixIcon: Icon(Iconsax.wallet),
                    prefixText: 'UGX ',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    if (amount > _availableBalance) {
                      return 'Insufficient balance';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Name Field
                Text(
                  'Recipient Name',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter recipient name',
                    prefixIcon: Icon(Iconsax.user),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter recipient name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Mobile Money Number Field
                Text(
                  'Mobile Money Number',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Enter mobile money number',
                    prefixIcon: Icon(Iconsax.mobile),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter mobile money number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Info Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.info_circle, color: Colors.grey[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Withdrawal requests are processed within 24-48 hours',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[700],
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitWithdrawRequest,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Submit Request'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
