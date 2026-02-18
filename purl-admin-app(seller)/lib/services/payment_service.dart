import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'currency_service.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CurrencyService _currencyService = CurrencyService();

  /// Get store's payment transactions stream
  Stream<PaymentData> getPaymentDataStream() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield PaymentData(balance: 0, transactions: [], currency: 'UGX');
      return;
    }

    // Get store ID from stores where user is authorized
    final storeQuery = await _firestore
        .collection('stores')
        .where('authorizedUsers', arrayContains: user.uid)
        .limit(1)
        .get();
    
    if (storeQuery.docs.isEmpty) {
      yield PaymentData(balance: 0, transactions: [], currency: 'UGX');
      return;
    }

    final storeId = storeQuery.docs.first.id;
    final storeData = storeQuery.docs.first.data();
    final storeCurrency = storeData['currency'] as String? ?? 'UGX';

    // Listen to orders for this store
    await for (var snapshot in _firestore
        .collection('stores')
        .doc(storeId)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()) {
      
      final transactions = <PaymentTransaction>[];
      double balance = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final total = (data['total'] ?? 0).toDouble();
        final orderNumber = data['orderNumber'] ?? '';
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        // Get commission from order (3% + $0.50)
        final commission = (data['commission'] ?? 0).toDouble();
        final sellerPayout = (data['sellerPayout'] ?? (total - commission)).toDouble();

        // Add sale transaction
        transactions.add(PaymentTransaction(
          type: 'Sale',
          amount: total,
          orderId: orderNumber,
          date: createdAt,
          isPositive: true,
          currency: storeCurrency,
        ));

        // Add commission transaction
        if (commission > 0) {
          transactions.add(PaymentTransaction(
            type: 'Commission',
            amount: commission,
            orderId: orderNumber,
            date: createdAt,
            isPositive: false,
            currency: storeCurrency,
          ));
        }

        // Calculate balance (seller payout)
        balance += sellerPayout;
      }

      yield PaymentData(balance: balance, transactions: transactions, currency: storeCurrency);
    }
  }
}

class PaymentData {
  final double balance;
  final List<PaymentTransaction> transactions;
  final String currency;

  PaymentData({
    required this.balance,
    required this.transactions,
    required this.currency,
  });
}

class PaymentTransaction {
  final String type;
  final double amount;
  final String orderId;
  final DateTime date;
  final bool isPositive;
  final String currency;

  PaymentTransaction({
    required this.type,
    required this.amount,
    required this.orderId,
    required this.date,
    required this.isPositive,
    required this.currency,
  });

  String get formattedAmount {
    final prefix = isPositive ? '+' : '-';
    final symbol = _getCurrencySymbol(currency);
    return '$prefix$symbol${amount.toStringAsFixed(2)}';
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'UGX':
        return 'USh ';
      case 'KES':
        return 'KSh ';
      case 'TZS':
        return 'TSh ';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '\$';
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
