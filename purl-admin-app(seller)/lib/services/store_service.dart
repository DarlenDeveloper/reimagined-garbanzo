import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// StoreService handles all store-related operations including:
/// - Store creation and management
/// - RBAC (Role-Based Access Control) for store runners
/// - Invite code generation and verification
/// 
/// RBAC FLOW:
/// 1. Admin opens Team page → taps "Add Runner"
/// 2. Admin generates a 4-digit invite code (valid for 15 minutes)
/// 3. Admin shares code with runner (verbally, text, etc.)
/// 4. Runner opens app → selects "Join a Store" → enters code
/// 5. Code is verified → runner gets added to store's authorizedUsers
/// 6. Runner can now access the store with limited permissions
class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Checks if the current authenticated user has access to any store.
  /// Returns the store ID if found, null otherwise.
  /// Used on app startup to determine navigation (dashboard vs account-type).
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

  /// Creates a new store in Firestore.
  /// The creating user becomes the owner and is added to authorizedUsers.
  /// Returns the newly created store's document ID.
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

  /// Generates a 4-digit invite code for adding store runners.
  /// 
  /// ADMIN ACTION - Called from Team page when admin taps "Add Runner"
  /// 
  /// The code is:
  /// - Stored in the store document under 'inviteCode' field
  /// - Valid for 15 minutes from generation
  /// - Single-use (deleted after successful join)
  /// - Overwrites any previous unused code
  /// 
  /// Returns the generated 4-digit code string.
  Future<String> generateInviteCode(String storeId) async {
    final code = _generateRandomCode();
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));

    // Store the invite code with expiration timestamp
    await _firestore.collection('stores').doc(storeId).update({
      'inviteCode': {
        'code': code,
        'expiresAt': Timestamp.fromDate(expiresAt),
      },
    });

    return code;
  }

  /// Verifies an invite code and adds the current user to the store.
  /// 
  /// RUNNER ACTION - Called from RunnerCodeScreen when runner enters code
  /// 
  /// Verification steps:
  /// 1. Find store with matching invite code
  /// 2. Check if code hasn't expired (15 min window)
  /// 3. Add user's UID to store's authorizedUsers array
  /// 4. Delete the invite code (single-use)
  /// 
  /// Returns true if successful, false if code invalid/expired.
  Future<bool> joinStoreWithCode(String code) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    // Search for store with this invite code
    final query = await _firestore
        .collection('stores')
        .where('inviteCode.code', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return false;

    final store = query.docs.first;
    final inviteData = store.data()['inviteCode'] as Map<String, dynamic>?;
    
    if (inviteData == null) return false;
    
    // Check expiration (15 minutes from generation)
    final expiresAt = (inviteData['expiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expiresAt)) return false;

    // Success: Add user to authorized users and delete the used code
    await _firestore.collection('stores').doc(store.id).update({
      'authorizedUsers': FieldValue.arrayUnion([uid]),
      'inviteCode': FieldValue.delete(), // Single-use: remove after successful join
    });

    return true;
  }

  /// Generates a random 4-digit code (0000-9999).
  /// Used for invite codes.
  String _generateRandomCode() {
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    return random.toString().padLeft(4, '0');
  }

  /// Fetches store data by ID.
  /// Returns the store document data or null if not found.
  Future<Map<String, dynamic>?> getStore(String storeId) async {
    final doc = await _firestore.collection('stores').doc(storeId).get();
    return doc.data();
  }

  /// Updates the store's logo URL.
  Future<void> updateStoreLogo(String storeId, String logoUrl) async {
    await _firestore.collection('stores').doc(storeId).update({'logoUrl': logoUrl});
  }

  /// Removes a user from the store's authorized users list.
  /// 
  /// ADMIN ACTION - Called from Team page when admin removes a runner
  /// 
  /// This revokes the user's access to the store immediately.
  /// The owner cannot be removed (enforced in UI).
  /// 
  /// Returns true if successful, false on error.
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
