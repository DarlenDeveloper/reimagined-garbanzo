import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';
import '../services/payment_service.dart';
import '../services/order_service.dart';
import '../services/cart_service.dart';
import 'payment_success_screen.dart';

/// Single checkout and payment screen - matches the design
class CheckoutPaymentScreen extends StatefulWidget {
  final double subtotal;
  final double deliveryCharge;
  final double tax;
  final double total;
  final Map<String, dynamic> orderData;

  const CheckoutPaymentScreen({
    super.key,
    required this.subtotal,
    required this.deliveryCharge,
    required this.tax,
    required this.total,
    required this.orderData,
  });

  @override
  State<CheckoutPaymentScreen> createState() => _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState extends State<CheckoutPaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final OrderService _orderService = OrderService();
  final CartService _cartService = CartService();
  final _formKey = GlobalKey<FormState>();
  
  // Payment method selection - track specific logo selected
  String? _selectedPaymentLogo; // 'visa', 'mastercard', 'mtn', 'airtel'
  
  // Card payment fields
  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  
  // Mobile money fields
  final _phoneController = TextEditingController();
  
  bool _isProcessing = false;

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
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(
            color: AppColors.black,
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
                    // Order Summary
                    _buildSummaryRow('Subtotal', widget.subtotal, isGrey: true),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Delivery Charge', widget.deliveryCharge, isGrey: true),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Tax', widget.tax, isGrey: true),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Total', widget.total, isBold: true),
                    
                    const SizedBox(height: 32),
                    
                    // Payment Method Header
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
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Payment Method Icons
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
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
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Payment Form (Card or Mobile Money)
                    if (_selectedPaymentLogo == 'visa' || _selectedPaymentLogo == 'mastercard') ...[
                      _buildCardForm(),
                    ] else if (_selectedPaymentLogo == 'mtn' || _selectedPaymentLogo == 'airtel') ...[
                      _buildMobileMoneyForm(),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Pay Button
          _buildPayButton(),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isGrey = false, bool isBold = false}) {
    // Format number with commas
    final formattedAmount = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: isGrey ? AppColors.grey600 : AppColors.black,
          ),
        ),
        Text(
          'UGX $formattedAmount',
          style: GoogleFonts.poppins(
            fontSize: isBold ? 18 : 15,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodLogo(String method, String logoPath) {
    final isSelected = _selectedPaymentLogo == method;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentLogo = method;
        });
      },
      child: Container(
        width: 80,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFfb2a0a).withValues(alpha: 0.05) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFfb2a0a) : AppColors.grey300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.asset(
            logoPath,
            fit: BoxFit.cover, // Changed to cover to fill the container
          ),
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Holder Name
        Text(
          'Card Holder Name',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(26), // height / 2
          ),
          child: TextFormField(
            controller: _cardHolderController,
            decoration: InputDecoration(
              hintText: 'Ryan Ghoslet',
              hintStyle: GoogleFonts.poppins(color: AppColors.grey400),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
        ),
        const SizedBox(height: 16),
        
        // Card Number
        Text(
          'Card Number',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(26),
          ),
          child: TextFormField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
            decoration: InputDecoration(
              hintText: '4444 - 0006 - 6569 - 0559',
              hintStyle: GoogleFonts.poppins(color: AppColors.grey400),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (value.replaceAll(' ', '').replaceAll('-', '').length < 15) {
                return 'Invalid card number';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),
        
        // Expiry and CVV
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valid Through',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: TextFormField(
                      controller: _expiryController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryDateFormatter(),
                      ],
                      decoration: InputDecoration(
                        hintText: '02 / 28',
                        hintStyle: GoogleFonts.poppins(color: AppColors.grey400),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (!value.contains('/') || value.length < 5) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CVV',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: TextFormField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        hintText: '***',
                        hintStyle: GoogleFonts.poppins(color: AppColors.grey400),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (value.length < 3) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
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
        // Phone Number (network already selected from payment method icons)
        Text(
          'Phone Number',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(26),
          ),
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              hintText: '0700000000',
              hintStyle: GoogleFonts.poppins(color: AppColors.grey400),
              prefixText: '+256 ',
              prefixStyle: GoogleFonts.poppins(
                color: AppColors.black,
                fontWeight: FontWeight.w500,
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (value.length < 9) return 'Invalid phone number';
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),
        // Show selected network info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFfb2a0a).withValues(alpha: 0.1), // Main red light
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFfb2a0a).withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            children: [
              Icon(Iconsax.info_circle, color: const Color(0xFFfb2a0a), size: 16), // Main red
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You\'ll receive a prompt on your $networkName number to complete payment',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFFfb2a0a), // Main red
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    // Format total with commas
    final formattedTotal = widget.total.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFb71000), // Button red
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.grey300,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28), // height / 2
              ),
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
                        'Pay UGX $formattedTotal',
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
    );
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentLogo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a payment method', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

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
      amount: widget.total,
      currency: 'UGX',
      email: widget.orderData['email'],
      fullname: _cardHolderController.text,
      phoneNumber: widget.orderData['phone'],
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
      }
      
      setState(() => _isProcessing = false);
      
      if (result.success || result.status == 'successful') {
        // Create orders in Firestore
        await _createOrders(result.transactionId ?? 'card_${DateTime.now().millisecondsSinceEpoch}');
        
        // Navigate to success screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PaymentSuccessScreen(
                orderId: result.txRef ?? result.transactionId ?? 'N/A',
                amount: widget.total,
                paymentMethod: 'Card',
                timestamp: DateTime.now(),
                orderDetails: widget.orderData,
              ),
            ),
          );
        }
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
    final phone = '256${_phoneController.text}';
    final network = _selectedPaymentLogo == 'mtn' ? 'MTN' : 'AIRTEL';

    // Show processing dialog
    _showProcessingDialog();

    final result = await _paymentService.chargeMobileMoney(
      phoneNumber: phone,
      network: network,
      amount: widget.total,
      currency: 'UGX',
      email: widget.orderData['email'],
      fullname: widget.orderData['name'],
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
        // Create orders in Firestore
        await _createOrders(result.transactionId ?? 'momo_${DateTime.now().millisecondsSinceEpoch}');
        
        // Navigate to success screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PaymentSuccessScreen(
                orderId: result.txRef ?? result.transactionId ?? 'N/A',
                amount: widget.total,
                paymentMethod: '$network Mobile Money',
                timestamp: DateTime.now(),
                orderDetails: widget.orderData,
              ),
            ),
          );
        }
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFFfb2a0a)), // Main red
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
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createOrders(String transactionId) async {
    try {
      final itemsByStore = widget.orderData['itemsByStore'] as Map<String, List<dynamic>>;
      final totalsByStore = widget.orderData['totalsByStore'];
      final deliveryFeesByStore = widget.orderData['deliveryFeesByStore'] as Map<String, double>;
      final deliveryLocation = widget.orderData['deliveryLocation'] as GeoPoint;
      final selectedAddress = widget.orderData['selectedAddress'];
      
      // Create orders using the existing method
      await _orderService.createOrdersFromCart(
        itemsByStore: itemsByStore.map((key, value) => MapEntry(key, value.cast<CartItemData>())),
        totalsByStore: totalsByStore,
        deliveryAddress: DeliveryAddress(
          label: selectedAddress.label,
          street: selectedAddress.street,
          city: selectedAddress.city,
        ),
        contactDetails: ContactDetails(
          name: widget.orderData['name'],
          phone: widget.orderData['phone'],
          email: widget.orderData['email'],
        ),
        deliveryLocation: deliveryLocation,
        packageSize: widget.orderData['packageSize'] ?? 'standard', // Add package size
        deliveryFeesByStore: deliveryFeesByStore,
        paymentId: transactionId,
        paymentMethod: _selectedPaymentLogo == 'mtn' || _selectedPaymentLogo == 'airtel' 
            ? 'Mobile Money' 
            : 'Card',
        promoCode: widget.orderData['promoCode'],
        promoDiscount: widget.orderData['promoDiscount'],
        discountId: widget.orderData['discountId'],
        discountStoreId: widget.orderData['discountStoreId'],
      );
      
      // Clear cart after successful order creation
      await _cartService.clearCart();
    } catch (e) {
      print('Error creating orders: $e');
    }
  }

  /// Open webview for payment verification (3DS, OTP, etc.)
  Future<bool> _openVerificationWebview(String redirectUrl, String txRef) async {
    // Try to open URL in browser
    bool urlOpened = false;
    try {
      final uri = Uri.parse(redirectUrl);
      if (await canLaunchUrl(uri)) {
        urlOpened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening URL: $e');
    }
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Complete Verification', style: GoogleFonts.poppins()),
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
              SelectableText(
                redirectUrl,
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.blue),
                textAlign: TextAlign.center,
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
              backgroundColor: const Color(0xFFb71000), // Button red
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
            child: Text('I Completed It', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ) ?? false;
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

  /// Verify payment status with backend
  Future<bool> _verifyPaymentStatus(String txRef) async {
    try {
      final result = await _paymentService.verifyPayment(txRef: txRef);
      return result.success && result.status == 'successful';
    } catch (e) {
      print('Error verifying payment: $e');
      return false;
    }
  }
}

/// Polling dialog for mobile money payments
class _PollingDialog extends StatefulWidget {
  final String txRef;
  final PaymentService paymentService;

  const _PollingDialog({
    required this.txRef,
    required this.paymentService,
  });

  @override
  State<_PollingDialog> createState() => _PollingDialogState();
}

class _PollingDialogState extends State<_PollingDialog> {
  int _attempts = 0;
  final int _maxAttempts = 20; // 20 attempts = 60 seconds
  bool _isPolling = true;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  Future<void> _startPolling() async {
    while (_attempts < _maxAttempts && _isPolling && mounted) {
      await Future.delayed(const Duration(seconds: 3));
      
      if (!mounted || !_isPolling) break;
      
      _attempts++;
      
      try {
        final result = await widget.paymentService.verifyPayment(txRef: widget.txRef);
        
        if (result.success && result.status == 'successful') {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
          return;
        }
      } catch (e) {
        print('Polling error: $e');
      }
    }
    
    // Timeout or cancelled
    if (mounted) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFfb2a0a)), // Main red
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
                  color: AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Attempt $_attempts of $_maxAttempts',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.grey400,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() => _isPolling = false);
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

// Card number formatter
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '').replaceAll('-', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' - ');
      }
    }
    
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
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
    final text = newValue.text.replaceAll('/', '').replaceAll(' ', '');
    
    if (text.length >= 2) {
      final formatted = '${text.substring(0, 2)} / ${text.substring(2)}';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    
    return newValue;
  }
}
