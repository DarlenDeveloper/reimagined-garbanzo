import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if current user has access to any store
  Future<String?> getUserStoreId() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final query = await _firestore
        .collection('stores')
        .where('authorizedUsers', arrayContains: uid)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }
    return null;
  }

  // Create a new store
  Future<String> createStore({
    required String name,
    required String category,
    String? description,
    String? logoUrl,
    Map<String, dynamic>? address,
    Map<String, dynamic>? contact,
    Map<String, dynamic>? businessHours,
    Map<String, dynamic>? paymentMethods,
    Map<String, dynamic>? shipping,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    final storeRef = await _firestore.collection('stores').add({
      'name': name,
      'category': category,
      'description': description ?? '',
      'logoUrl': logoUrl ?? '',
      'ownerId': uid,
      'authorizedUsers': [uid],
      'createdAt': FieldValue.serverTimestamp(),
      'subscription': 'free',
      'address': address ?? {},
      'contact': contact ?? {},
      'businessHours': businessHours ?? {},
      'paymentMethods': paymentMethods ?? {},
      'shipping': shipping ?? {},
    });

    return storeRef.id;
  }

  // Generate invite code for runners
  Future<String> generateInviteCode(String storeId) async {
    final code = _generateRandomCode();
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));

    await _firestore.collection('stores').doc(storeId).update({
      'inviteCode': {
        'code': code,
        'expiresAt': Timestamp.fromDate(expiresAt),
      },
    });

    return code;
  }

  // Verify invite code and join store
  Future<bool> joinStoreWithCode(String code) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final query = await _firestore
        .collection('stores')
        .where('inviteCode.code', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return false;

    final store = query.docs.first;
    final inviteData = store.data()['inviteCode'] as Map<String, dynamic>?;
    
    if (inviteData == null) return false;
    
    final expiresAt = (inviteData['expiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expiresAt)) return false;

    // Add user to authorized users
    await _firestore.collection('stores').doc(store.id).update({
      'authorizedUsers': FieldValue.arrayUnion([uid]),
      'inviteCode': FieldValue.delete(),
    });

    return true;
  }

  String _generateRandomCode() {
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    return random.toString().padLeft(4, '0');
  }

  // Get store data
  Future<Map<String, dynamic>?> getStore(String storeId) async {
    final doc = await _firestore.collection('stores').doc(storeId).get();
    return doc.data();
  }

  // Update store logo
  Future<void> updateStoreLogo(String storeId, String logoUrl) async {
    await _firestore.collection('stores').doc(storeId).update({'logoUrl': logoUrl});
  }

  // Remove user from store (revoke access)
  Future<bool> removeUserFromStore(String storeId, String userId) async {
    try {
      await _firestore.collection('stores').doc(storeId).update({
        'authorizedUsers': FieldValue.arrayRemove([userId]),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
