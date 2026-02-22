import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ai_config.dart';

class AIService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'africa-south1');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get AI service configuration for current store
  Future<AIServiceConfig?> getAIConfig(String storeId) async {
    try {
      final doc = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('aiAssistant')
          .doc('config')
          .get();

      if (!doc.exists) {
        return null;
      }

      return AIServiceConfig.fromFirestore(doc.data()!);
    } catch (e) {
      print('❌ Error getting AI config: $e');
      return null;
    }
  }

  /// Stream AI service configuration
  Stream<AIServiceConfig?> streamAIConfig(String storeId) {
    return _firestore
        .collection('stores')
        .doc(storeId)
        .collection('aiAssistant')
        .doc('config')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return AIServiceConfig.fromFirestore(doc.data()!);
    });
  }

  /// Enable AI service (after payment)
  Future<Map<String, dynamic>> enableAIService(String storeId) async {
    try {
      print('🚀 Calling enableAIService function for store: $storeId');
      final callable = _functions.httpsCallable('enableAIService');
      
      print('📡 Sending request to Cloud Function...');
      final result = await callable.call({'storeId': storeId});
      
      print('✅ Cloud Function response received');
      print('   - success: ${result.data['success']}');
      print('   - phoneNumber: ${result.data['phoneNumber']}');
      print('   - message: ${result.data['message']}');
      
      return {
        'success': result.data['success'] ?? false,
        'phoneNumber': result.data['phoneNumber'],
        'expiryDate': result.data['expiryDate'],
        'message': result.data['message'],
      };
    } catch (e) {
      print('❌ Error enabling AI service: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Error details: ${e.toString()}');
      throw Exception('Failed to enable AI service: ${e.toString()}');
    }
  }

  /// Renew AI subscription (after payment)
  Future<Map<String, dynamic>> renewSubscription(String storeId, String paymentId) async {
    try {
      final callable = _functions.httpsCallable('renewAISubscription');
      final result = await callable.call({
        'storeId': storeId,
        'paymentId': paymentId,
      });
      
      return {
        'success': result.data['success'] ?? false,
        'expiryDate': result.data['expiryDate'],
        'message': result.data['message'],
      };
    } catch (e) {
      print('❌ Error renewing subscription: $e');
      throw Exception('Failed to renew subscription: ${e.toString()}');
    }
  }

  /// Get call logs with pagination
  Future<List<CallLog>> getCallLogs(String storeId, {int limit = 20, DocumentSnapshot? lastDoc}) async {
    try {
      Query query = _firestore
          .collection('stores')
          .doc(storeId)
          .collection('aiAssistant')
          .doc('config')
          .collection('callLogs')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => CallLog.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting call logs: $e');
      return [];
    }
  }

  /// Stream call logs
  Stream<List<CallLog>> streamCallLogs(String storeId, {int limit = 20}) {
    return _firestore
        .collection('stores')
        .doc(storeId)
        .collection('aiAssistant')
        .doc('config')
        .collection('callLogs')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CallLog.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  /// Record AI subscription payment
  Future<void> recordAIPayment({
    required String storeId,
    required String transactionId,
    required double amount,
  }) async {
    try {
      final now = DateTime.now();
      
      await _firestore.collection('stores').doc(storeId).update({
        'aiPayments': FieldValue.arrayUnion([
          {
            'amount': amount,
            'transactionId': transactionId,
            'paidAt': Timestamp.fromDate(now),
            'type': 'ai_subscription',
          }
        ]),
        'lastAIPayment': {
          'amount': amount,
          'transactionId': transactionId,
          'paidAt': Timestamp.fromDate(now),
          'type': 'ai_subscription',
        },
      });
    } catch (e) {
      print('❌ Error recording AI payment: $e');
      throw Exception('Failed to record payment');
    }
  }
}
