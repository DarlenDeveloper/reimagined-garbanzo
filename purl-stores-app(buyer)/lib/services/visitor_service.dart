import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VisitorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Record a store visit for the current user (one per day)
  Future<void> recordStoreVisit(String storeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ User not authenticated, cannot record visit');
        return;
      }

      final userId = user.uid;
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      print('📱 Recording store visit:');
      print('   Store ID: $storeId');
      print('   User ID: $userId');
      print('   Date: $dateKey');

      // Check if user already visited today
      final visitorDoc = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('visitors')
          .doc(userId)
          .get();

      if (visitorDoc.exists) {
        final lastVisitDate = visitorDoc.data()?['lastVisitDate'] as String?;
        if (lastVisitDate == dateKey) {
          print('✅ User already visited today, skipping duplicate');
          return;
        }
      }

      // Record or update the visit
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('visitors')
          .doc(userId)
          .set({
        'userId': userId,
        'lastVisitDate': dateKey,
        'visitCount': FieldValue.increment(1),
        'lastVisitTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Store visit recorded successfully');
    } catch (e) {
      print('❌ Error recording store visit: $e');
    }
  }

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

  /// Stream of total visitor count (with caching to prevent flickering)
  Stream<int> getTotalVisitorCountStream(String storeId) {
    return _firestore
        .collection('stores')
        .doc(storeId)
        .collection('visitors')
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .distinct(); // Only emit when value actually changes
  }
}
