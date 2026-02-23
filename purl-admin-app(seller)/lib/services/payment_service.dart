import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// PaymentService for managing seller payments and transactions
/// This is separate from FlutterwaveService which handles payment processing
class PaymentService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get payment data stream for current seller
  Stream<PaymentData> getPaymentDataStream() async* {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      yield PaymentData(balance: 0, transactions: [], currency: 'UGX');
      return;
    }

    // First get the store ID
    final storeQuery = await _firestore
        .collection('stores')
        .where('authorizedUsers', arrayContains: userId)
        .limit(1)
        .get();

    if (storeQuery.docs.isEmpty) {
      yield PaymentData(balance: 0, transactions: [], currency: 'UGX');
      return;
    }

    final storeId = storeQuery.docs.first.id;

    // Stream orders and calculate balance/transactions from them
    yield* _firestore
        .collection('stores')
        .doc(storeId)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .asyncMap((ordersSnapshot) async {
      // Get store data for currency
      final storeDoc = await _firestore.collection('stores').doc(storeId).get();
      final storeData = storeDoc.data();
      final currency = storeData?['currency'] ?? 'UGX';

      // Calculate balance from paid orders
      double balance = 0.0;
      final transactions = <PaymentTransaction>[];

      for (var orderDoc in ordersSnapshot.docs) {
        final orderData = orderDoc.data();
        final paymentStatus = orderData['paymentStatus'] ?? '';
        final total = (orderData['total'] ?? 0).toDouble();
        final commission = (orderData['commission'] ?? 0).toDouble();
        final sellerPayout = (orderData['sellerPayout'] ?? total).toDouble();
        final createdAt = (orderData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final orderNumber = orderData['orderNumber'] ?? orderDoc.id;

        // Only count paid orders for balance (use sellerPayout, not total)
        if (paymentStatus == 'paid') {
          balance += sellerPayout;
        }

        // Create sale transaction from order
        transactions.add(PaymentTransaction(
          id: orderDoc.id,
          type: 'Sale',
          amount: total,
          method: orderData['paymentMethod'],
          status: paymentStatus,
          createdAt: createdAt,
          orderId: orderNumber,
          description: 'Order payment',
        ));

        // Add commission as a separate negative transaction
        if (commission > 0) {
          transactions.add(PaymentTransaction(
            id: '${orderDoc.id}_commission',
            type: 'Commission',
            amount: -commission,
            method: null,
            status: paymentStatus,
            createdAt: createdAt,
            orderId: orderNumber,
            description: 'Platform commission',
          ));
        }
      }

      // Get payouts and add them to transactions
      final payoutsSnapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('payouts')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      for (var payoutDoc in payoutsSnapshot.docs) {
        final payoutData = payoutDoc.data();
        final amount = (payoutData['amount'] ?? 0).toDouble();
        final status = payoutData['status'] ?? 'pending';
        final method = payoutData['method'];
        final createdAt = (payoutData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

        transactions.add(PaymentTransaction(
          id: payoutDoc.id,
          type: 'Payout',
          amount: -amount,
          method: method,
          status: status,
          createdAt: createdAt,
          orderId: null,
          description: 'Payout request',
        ));

        // Deduct all payouts from balance (pending, processing, and completed)
        // Only exclude rejected/cancelled payouts
        if (status != 'rejected' && status != 'cancelled') {
          balance -= amount;
        }
      }

      // Sort all transactions by date
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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

    // Get store ID
    final storeQuery = await _firestore
        .collection('stores')
        .where('authorizedUsers', arrayContains: userId)
        .limit(1)
        .get();

    if (storeQuery.docs.isEmpty) throw Exception('Store not found');
    final storeId = storeQuery.docs.first.id;

    // Create payout request
    await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('payouts')
        .add({
      'amount': amount,
      'method': method,
      'details': details,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Note: Balance is calculated from orders, not stored separately
    // So we don't need to update a balance field
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
