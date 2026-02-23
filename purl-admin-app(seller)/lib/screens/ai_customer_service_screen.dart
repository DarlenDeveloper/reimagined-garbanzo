import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ai_service.dart';
import '../services/flutterwave_service.dart';
import '../models/ai_config.dart';
import 'ai_call_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AICustomerServiceScreen extends StatefulWidget {
  const AICustomerServiceScreen({super.key});

  @override
  State<AICustomerServiceScreen> createState() => _AICustomerServiceScreenState();
}

class _AICustomerServiceScreenState extends State<AICustomerServiceScreen> {
  final _aiService = AIService();
  final _paymentService = FlutterwaveService();
  String? _storeId;
  bool _isProcessing = false;
  String? _selectedPaymentMethod;
  final _phoneController = TextEditingController();

  static const double AI_SUBSCRIPTION_FEE = 20.0;
  static const double AI_SUBSCRIPTION_FEE_UGX = 75000.0; // 20 * 3750 (fixed USD to UGX rate)

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadStoreId();
  }

  Future<void> _loadStoreId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .where('authorizedUsers', arrayContains: user.uid)
          .limit(1)
          .get();

      if (storeDoc.docs.isNotEmpty) {
        setState(() => _storeId = storeDoc.docs.first.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_storeId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Customer Service',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFb71000),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: const Color(0xFFb71000))),
      );
    }

    return StreamBuilder<AIServiceConfig?>(
      stream: _aiService.streamAIConfig(_storeId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                'Customer Service',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFb71000),
              elevation: 0,
            ),
            body: const Center(child: CircularProgressIndicator(color: const Color(0xFFb71000))),
          );
        }

        final config = snapshot.data;

        if (config == null || !config.enabled) {
          return _buildPaymentWall();
        }

        return _buildDashboard(config);
      },
    );
  }

  Widget _buildPaymentWall() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Customer Service',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFb71000),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // Title with star icon
            Row(
              children: [
                Text(
                  'Unlock Riley.',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFb71000),
                    height: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Iconsax.star1, size: 32, color: Colors.grey[800]),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Description
            Text(
              'Riley is your AI-powered customer service assistant that handles phone calls 24/7. Never miss a customer inquiry again.',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
            
            const SizedBox(height: 32),

            // Features with checkmarks
            _buildFeatureItem(Icons.check_circle, 'Dedicated phone number for your store'),
            _buildFeatureItem(Icons.check_circle, '100 minutes of AI calls included'),
            _buildFeatureItem(Icons.check_circle, 'Natural voice conversations'),
            _buildFeatureItem(Icons.check_circle, 'Call logs with transcripts & summaries'),
            _buildFeatureItem(Icons.check_circle, 'Customer satisfaction tracking'),

            const SizedBox(height: 32),
            
            // Pricing card with discount badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Assistant',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFb71000),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get Riley to handle all customer calls',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$20',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFb71000),
                              height: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4, left: 4),
                            child: Text(
                              '/month',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '\$50',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[400],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'UGX ${AI_SUBSCRIPTION_FEE_UGX.toStringAsFixed(0)}/month',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -10,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFb71000),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '60% OFF',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Payment method selection
            Text(
              'Choose Payment Method',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPaymentLogo('mtn', 'assets/images/mtn.jpeg'),
                const SizedBox(width: 12),
                _buildPaymentLogo('airtel', 'assets/images/airtel.jpeg'),
              ],
            ),

            if (_selectedPaymentMethod != null) ...[
              const SizedBox(height: 20),
              Text(
                'Phone Number',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '0700000000',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  prefixText: '+256 ',
                  prefixStyle: GoogleFonts.poppins(
                    color: const Color(0xFFb71000),
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Continue button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_isProcessing || _selectedPaymentMethod == null)
                    ? null
                    : _startPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFb71000),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
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
                    : Text(
                        'Continue',
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

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFFb71000)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentLogo(String method, String assetPath) {
    final isSelected = _selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      child: Container(
        width: 70,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFFb71000) : Colors.grey[300]!,
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

  Widget _buildDashboard(AIServiceConfig config) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Customer Service',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFb71000),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phone number card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFb71000),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Iconsax.call, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Your AI Phone Number',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    config.phoneNumber ?? 'Not assigned',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Riley is ready to assist your customers',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Subscription status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subscription Status',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: config.isActive ? Colors.green[50] : Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          config.isActive ? 'Active' : config.isGracePeriod ? 'Grace Period' : 'Expired',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: config.isActive ? Colors.green[700] : Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Expires',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(config.subscription.expiryDate),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (config.subscription.isExpiringSoon) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Iconsax.warning_2, size: 16, color: const Color(0xFFb71000)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Expires in ${config.subscription.daysUntilExpiry} days',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFb71000),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (config.isExpired || config.isGracePeriod) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showRenewalDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFb71000),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Renew Subscription',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Usage stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usage This Month',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${config.subscription.usedMinutes.toStringAsFixed(1)} min',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Used',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${config.subscription.remainingMinutes} min',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Remaining',
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
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: config.subscription.usedMinutes / config.subscription.minutesIncluded,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        config.subscription.usedMinutes >= config.subscription.minutesIncluded
                            ? Colors.red
                            : const Color(0xFFb71000),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent calls header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Calls',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Call logs
            StreamBuilder<List<CallLog>>(
              stream: _aiService.streamCallLogs(_storeId!, limit: 10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: const Color(0xFFb71000)),
                    ),
                  );
                }

                final calls = snapshot.data ?? [];

                if (calls.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Iconsax.call_slash, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No calls yet',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: calls.map((call) => _buildCallLogItem(call)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallLogItem(CallLog call) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AICallDetailScreen(callLog: call),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.call, size: 18, color: Colors.grey[700]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    call.formattedPhone,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM dd • hh:mm a').format(call.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  call.formattedDuration,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (call.csatScore != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Iconsax.star1, size: 12, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        '${call.csatScore}/10',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startPayment() async {
    if (_phoneController.text.isEmpty || _phoneController.text.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid phone number', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }

      print('💳 Starting payment process...');
      _showProcessingDialog();

      final phone = '256${_phoneController.text}';
      final network = _selectedPaymentMethod == 'mtn' ? 'MTN' : 'AIRTEL';

      print('📱 Charging mobile money: $phone ($network)');
      final result = await _paymentService.chargeMobileMoney(
        phoneNumber: phone,
        network: network,
        amount: AI_SUBSCRIPTION_FEE_UGX,
        currency: 'UGX',
        email: user.email ?? '',
        fullname: user.displayName ?? 'Store Owner',
      );

      print('💳 Payment result: ${result.success}, status: ${result.status}');

      if (mounted) {
        Navigator.of(context).pop(); // Close processing dialog

        if (result.redirectUrl != null && result.redirectUrl!.isNotEmpty) {
          print('🌐 Opening redirect URL: ${result.redirectUrl}');
          await launchUrl(Uri.parse(result.redirectUrl!), mode: LaunchMode.externalApplication);
        }

        if (result.success || result.status == 'pending' || result.status == 'successful') {
          print('✅ Payment successful, recording payment...');
          // Record payment
          await _aiService.recordAIPayment(
            storeId: _storeId!,
            transactionId: result.transactionId ?? 'ai_${DateTime.now().millisecondsSinceEpoch}',
            amount: AI_SUBSCRIPTION_FEE,
          );

          print('🤖 Enabling AI service...');
          // Enable AI service
          _showEnablingDialog();
          
          final enableResult = await _aiService.enableAIService(_storeId!);
          
          print('🎉 AI service enabled: ${enableResult['success']}');
          
          if (mounted) {
            Navigator.of(context).pop(); // Close enabling dialog
            
            if (enableResult['success']) {
              print('📞 Phone number assigned: ${enableResult['phoneNumber']}');
              _showSuccessDialog(enableResult['phoneNumber']);
            } else {
              throw Exception(enableResult['message'] ?? 'Failed to enable service');
            }
          }
        } else {
          throw Exception(result.error ?? 'Payment failed');
        }
      }
    } catch (e) {
      print('❌ Error in payment flow: $e');
      if (mounted) {
        // Close any open dialogs
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        
        setState(() => _isProcessing = false);
        
        // Show user-friendly error message
        String errorMessage = 'Unable to complete setup. Please try again.';
        if (e.toString().contains('UNAVAILABLE')) {
          errorMessage = 'Service temporarily unavailable. Please try again in a moment.';
        } else if (e.toString().contains('UNAUTHENTICATED')) {
          errorMessage = 'Authentication error. Please log in again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFFb71000),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showRenewalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Renew Subscription',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Renew your AI Customer Service subscription for another 30 days.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Amount',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'UGX ${AI_SUBSCRIPTION_FEE_UGX.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement renewal payment flow
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Renewal feature coming soon',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: const Color(0xFFb71000),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFb71000),
              foregroundColor: Colors.white,
            ),
            child: Text('Renew', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: const Color(0xFFb71000)),
                const SizedBox(height: 20),
                Text(
                  'Processing Payment',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEnablingDialog() {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: const Color(0xFFb71000)),
              const SizedBox(height: 20),
              Text(
                'Setting Up AI Service',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a moment...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  print('⚠️ User cancelled AI service setup');
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String phoneNumber) {
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
              'AI Service Activated!',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your AI assistant Riley is ready at:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              phoneNumber,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFb71000),
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
}
