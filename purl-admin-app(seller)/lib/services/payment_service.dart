import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// PaymentService for managing seller payments and transactions
/// This is separate from FlutterwaveService which handles payment processing
class PaymentService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get payment data stream for current seller
  Stream<PaymentData> getPaymentDataStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(PaymentData(balance: 0, transactions: [], currency: 'UGX'));
    }

    return _firestore
        .collection('sellers')
        .doc(userId)
        .snapshots()
        .asyncMap((sellerDoc) async {
      if (!sellerDoc.exists) {
        return PaymentData(balance: 0, transactions: [], currency: 'UGX');
      }

      final data = sellerDoc.data()!;
      final balance = (data['balance'] ?? 0).toDouble();
      final currency = data['currency'] ?? 'UGX';

      // Get recent transactions
      final transactionsSnapshot = await _firestore
          .collection('sellers')
          .doc(userId)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final transactions = transactionsSnapshot.docs
          .map((doc) => PaymentTransaction.fromFirestore(doc))
          .toList();

      return PaymentData(
        balance: balance,
        transactions: transactions,
        currency: currency,
      );
    });
  }

  /// Request payout
  Future<void> requestPayout({
    required double amount,
    required String method,
    required Map<String, dynamic> details,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Create payout request
    await _firestore
        .collection('sellers')
        .doc(userId)
        .collection('payouts')
        .add({
      'amount': amount,
      'method': method,
      'details': details,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Deduct from balance
    await _firestore.collection('sellers').doc(userId).update({
      'balance': FieldValue.increment(-amount),
    });

    // Add transaction record
    await _firestore
        .collection('sellers')
        .doc(userId)
        .collection('transactions')
        .add({
      'type': 'payout',
      'amount': -amount,
      'method': method,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Payment data model
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

/// Payment transaction model
class PaymentTransaction {
  final String id;
  final String type; // 'sale', 'payout', 'refund'
  final double amount;
  final String? method;
  final String status;
  final DateTime createdAt;
  final String? orderId;
  final String? description;

  PaymentTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.method,
    required this.status,
    required this.createdAt,
    this.orderId,
    this.description,
  });

  bool get isPositive => amount >= 0;

  String get formattedAmount {
    final absAmount = amount.abs();
    final prefix = amount >= 0 ? '+' : '-';
    return '$prefix${absAmount.toStringAsFixed(0)}';
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  factory PaymentTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentTransaction(
      id: doc.id,
      type: data['type'] ?? 'sale',
      amount: (data['amount'] ?? 0).toDouble(),
      method: data['method'],
      status: data['status'] ?? 'completed',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      orderId: data['orderId'],
      description: data['description'],
    );
  }
}
