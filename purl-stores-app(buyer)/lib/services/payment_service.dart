import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// PaymentService handles Flutterwave payment integration
/// 
/// Supports:
/// - Card payments (direct charge)
/// - Mobile money (MTN, Airtel)
class PaymentService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'africa-south1');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Charge card directly
  Future<PaymentChargeResult> chargeCard({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required double amount,
    required String currency,
    required String email,
    required String fullname,
    String? phoneNumber,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final txRef = _generateTxRef(user.uid);
      print('💳 Charging card: $txRef for $amount $currency');

      final result = await _functions
          .httpsCallable('chargeCard')
          .call({
        'cardNumber': cardNumber,
        'expiryMonth': expiryMonth,
        'expiryYear': expiryYear,
        'cvv': cvv,
        'amount': amount,
        'currency': currency,
        'email': email,
        'fullname': fullname,
        'phoneNumber': phoneNumber ?? '',
        'txRef': txRef,
      });

      final data = result.data as Map<String, dynamic>;
      
      return PaymentChargeResult(
        success: data['success'] == true,
        txRef: data['txRef'],
        transactionId: data['transactionId'],
        status: data['status'],
        redirectUrl: data['redirectUrl'],
        authMode: data['authMode'],
        message: data['message'],
        error: data['error'],
      );
    } catch (e) {
      print('❌ Error charging card: $e');
      return PaymentChargeResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Charge mobile money
  Future<PaymentChargeResult> chargeMobileMoney({
    required String phoneNumber,
    required String network,
    required double amount,
    required String currency,
    required String email,
    required String fullname,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final txRef = _generateTxRef(user.uid);
      print('📱 Charging mobile money: $txRef for $amount $currency');

      final result = await _functions
          .httpsCallable('chargeMobileMoney')
          .call({
        'phoneNumber': phoneNumber,
        'network': network,
        'amount': amount,
        'currency': currency,
        'email': email,
        'fullname': fullname,
        'txRef': txRef,
      });

      final data = result.data as Map<String, dynamic>;
      
      return PaymentChargeResult(
        success: data['success'] == true,
        txRef: data['txRef'],
        transactionId: data['transactionId'],
        status: data['status'],
        redirectUrl: data['redirectUrl'],
        authMode: data['authMode'],
        message: data['message'],
        error: data['error'],
      );
    } catch (e) {
      print('❌ Error charging mobile money: $e');
      return PaymentChargeResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Verify payment status
  Future<PaymentVerifyResult> verifyPayment({
    String? transactionId,
    String? txRef,
  }) async {
    try {
      if (transactionId == null && txRef == null) {
        throw Exception('Transaction ID or tx_ref is required');
      }

      print('🔍 Verifying payment: ${transactionId ?? txRef}');

      final result = await _functions
          .httpsCallable('verifyFlutterwavePayment')
          .call({
        if (transactionId != null) 'transactionId': transactionId,
        if (txRef != null) 'txRef': txRef,
      });

      final data = result.data as Map<String, dynamic>;
      
      return PaymentVerifyResult(
        success: data['success'] == true,
        status: data['status'],
        amount: data['amount']?.toDouble(),
        currency: data['currency'],
        txRef: data['txRef'],
        transactionId: data['transactionId'],
      );
    } catch (e) {
      print('❌ Error verifying payment: $e');
      return PaymentVerifyResult(
        success: false,
        status: 'error',
        error: e.toString(),
      );
    }
  }

  /// Generate unique transaction reference
  String _generateTxRef(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userPrefix = userId.substring(0, 8);
    return 'PURL_${userPrefix}_$timestamp';
  }
}

/// Payment charge result (for card and mobile money)
class PaymentChargeResult {
  final bool success;
  final String? txRef;
  final String? transactionId;
  final String? status;
  final String? redirectUrl;
  final String? authMode;
  final String? message;
  final String? error;

  PaymentChargeResult({
    required this.success,
    this.txRef,
    this.transactionId,
    this.status,
    this.redirectUrl,
    this.authMode,
    this.message,
    this.error,
  });
}

/// Payment verification result
class PaymentVerifyResult {
  final bool success;
  final String status;
  final double? amount;
  final String? currency;
  final String? txRef;
  final String? transactionId;
  final String? error;

  PaymentVerifyResult({
    required this.success,
    required this.status,
    this.amount,
    this.currency,
    this.txRef,
    this.transactionId,
    this.error,
  });
}
