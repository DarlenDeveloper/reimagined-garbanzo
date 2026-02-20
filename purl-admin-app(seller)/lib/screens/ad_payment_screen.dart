import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/flutterwave_service.dart';
import 'ad_payment_success_screen.dart';

class AdPaymentScreen extends StatefulWidget {
  final String adId;
  final double budgetUSD;
  final String adTitle;

  const AdPaymentScreen({
    super.key,
    required this.adId,
    required this.budgetUSD,
    required this.adTitle,
  });

  @override
  State<AdPaymentScreen> createState() => _AdPaymentScreenState();
}

class _AdPaymentScreenState extends State<AdPaymentScreen> {
  final FlutterwaveService _paymentService = FlutterwaveService();
  final _formKey = GlobalKey<FormState>();
  
  // Payment method selection
  String? _selectedPaymentLogo; // 'visa', 'mastercard', 'mtn', 'airtel'
  
  // Card payment fields
  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  
  // Mobile money fields
  final _phoneController = TextEditingController();
  
  bool _isProcessing = false;
  
  // Exchange rate: 1 USD = 3750 UGX
  static const double USD_TO_UGX = 3750.0;

  double get amountUGX => widget.budgetUSD * USD_TO_UGX;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _cardHolderController.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Ad Payment',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ad Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.adTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(widget.budgetUSD * 1024).toStringAsFixed(0)} views',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Payment Summary - matching buyer checkout style
                    _buildSummaryRow('Budget (USD)', widget.budgetUSD, prefix: '\$', isGrey: true),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Amount (UGX)', amountUGX, prefix: 'UGX ', isBold: true),
                    
                    const SizedBox(height: 32),
                    
                    // Payment Method Header - matching buyer checkout
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
                          label: Text(
                            'Add',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Payment Method Icons - matching buyer checkout
                    Row(
                      children: [
                        _buildPaymentMethodLogo('visa', 'assets/images/visa.jpeg'),
                        const SizedBox(width: 12),
                        _buildPaymentMethodLogo('mastercard', 'assets/images/mastercard.jpeg'),
                        const SizedBox(width: 12),
                        _buildPaymentMethodLogo('mtn', 'assets/images/mtn.jpeg'),
                        const SizedBox(width: 12),
                        _buildPaymentMethodLogo('airtel', 'assets/images/airtel.jpeg'),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Payment Form
                    if (_selectedPaymentLogo == 'visa' || _selectedPaymentLogo == 'mastercard')
                      _buildCardForm()
                    else if (_selectedPaymentLogo == 'mtn' || _selectedPaymentLogo == 'airtel')
                      _buildMobileMoneyForm(),
                  ],
                ),
              ),
            ),
          ),
          
          // Pay Button - matching buyer checkout
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
                                'Pay UGX ${amountUGX.toStringAsFixed(0)}',
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
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {String prefix = '', bool isBold = false, bool isGrey = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isGrey ? Colors.grey[600] : (isBold ? Colors.black : Colors.grey[600]),
            fontWeight: isGrey ? FontWeight.normal : (isBold ? FontWeight.w600 : FontWeight.normal),
          ),
        ),
        Text(
          '$prefix${amount.toStringAsFixed(amount >= 1000 ? 0 : 2)}',
          style: GoogleFonts.poppins(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w700 : (isGrey ? FontWeight.normal : FontWeight.w600),
            color: isBold ? Colors.black : (isGrey ? Colors.grey[600] : Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodLogo(String method, String assetPath) {
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
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[100],
                  child: Center(
                    child: Text(
                      method.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
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
        Text(
          'Phone Number',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
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
            prefixStyle: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Required';
            if (value!.length < 9) return 'Invalid phone number';
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Info box - matching buyer checkout
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You\'ll receive a prompt on your $networkName number to complete payment',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

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
      amount: amountUGX,
      currency: 'UGX',
      email: user.email ?? '',
      fullname: _cardHolderController.text,
      phoneNumber: user.phoneNumber,
    );

    if (mounted) {
      Navigator.of(context).pop(); // Close processing dialog
      
      print('💳 Payment result: ${result.success}, status: ${result.status}, error: ${result.error}');
      
      // Check for errors first
      if (!result.success && result.error != null) {
        setState(() => _isProcessing = false);
        
        // Check if it's a test limit error
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
        await _updateAdStatus(result.transactionId ?? 'card_${DateTime.now().millisecondsSinceEpoch}');
        _showSuccessAndExit();
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
      amount: amountUGX,
      currency: 'UGX',
      email: user.email ?? '',
      fullname: user.displayName ?? _cardHolderController.text,
    );

    if (mounted) {
      Navigator.of(context).pop(); // Close processing dialog
      
      // Check if redirect is needed for verification
      if (result.redirectUrl != null && result.redirectUrl!.isNotEmpty) {
        // Open redirect URL in webview for verification
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
            backgroundColor: Colors.blue,
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
        await _updateAdStatus(result.transactionId ?? 'momo_${DateTime.now().millisecondsSinceEpoch}');
        _showSuccessAndExit();
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

  Future<void> _updateAdStatus(String transactionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('ads')
          .doc(widget.adId)
          .update({
        'status': 'active',
        'paidAt': FieldValue.serverTimestamp(),
        'paymentMethod': _selectedPaymentLogo,
        'amountPaid': amountUGX,
        'transactionId': transactionId,
      });
    } catch (e) {
      print('Error updating ad status: $e');
    }
  }

  void _showSuccessAndExit() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AdPaymentSuccessScreen(
          transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: amountUGX,
          paymentMethod: _selectedPaymentLogo == 'mtn' || _selectedPaymentLogo == 'airtel' 
              ? '${_selectedPaymentLogo!.toUpperCase()} Mobile Money' 
              : 'Card',
          timestamp: DateTime.now(),
          adTitle: widget.adTitle,
          views: (widget.budgetUSD * 1024).toInt(),
        ),
      ),
    );
  }

  /// Open webview for payment verification (3DS, OTP, etc.)
  Future<bool> _openVerificationWebview(String redirectUrl, String txRef) async {
    // Try to open URL in browser immediately
    bool urlOpened = false;
    try {
      final uri = Uri.parse(redirectUrl);
      urlOpened = await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication,
      );
      print('🌐 URL opened: $urlOpened');
    } catch (e) {
      print('❌ Error opening URL: $e');
    }
    
    // Show dialog regardless
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Complete Verification', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.security, size: 48, color: Colors.blue),
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
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    redirectUrl,
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.blue),
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
              // Verify payment status
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

  /// Verify payment status
  Future<bool> _verifyPaymentStatus(String txRef) async {
    final result = await _paymentService.verifyPayment(txRef: txRef);
    return result.success && result.status == 'successful';
  }

  /// Poll payment status (for mobile money)
  Future<bool> _pollPaymentStatus(String txRef) async {
    // Show polling dialog
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
  final int _maxAttempts = 20; // 20 attempts * 3 seconds = 60 seconds max
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
    
    // Timeout
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
