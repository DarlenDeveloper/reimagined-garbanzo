import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VisitorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get total unique visitors for a store (today)
  Future<int> getTodayVisitorCount(String storeId) async {
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final snapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('visitors')
          .where('lastVisitDate', isEqualTo: dateKey)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getting visitor count: $e');
      return 0;
    }
  }

  /// Get total unique visitors for a store (all time)
  Future<int> getTotalVisitorCount(String storeId) async {
    try {
      final snapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('visitors')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getting total visitor count: $e');
      return 0;
    }
  }

  /// Stream of today's visitor count (with caching to prevent flickering)
  Stream<int> getTodayVisitorCountStream(String storeId) {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return _firestore
        .collection('stores')
        .doc(storeId)
        .collection('visitors')
        .where('lastVisitDate', isEqualTo: dateKey)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .distinct(); // Only emit when value actually changes
  }

  /// Stream of total visitor count
  Stream<int> getTotalVisitorCountStream(String storeId) {
    return _firestore
        .collection('stores')
        .doc(storeId)
        .collection('visitors')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
