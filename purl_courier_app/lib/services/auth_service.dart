import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'fcm_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Use web client ID for Android OAuth
    serverClientId: '255612064321-8p09as8bg59k9nph3p7n7dp6p1nk50vg.apps.googleusercontent.com',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create courier profile in Firestore
    await _createCourierProfile(
      uid: credential.user!.uid,
      email: email,
      fullName: fullName,
      phone: phone,
    );

    return credential;
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Check if courier profile exists in Firestore
      final courierDoc = await _firestore.collection('couriers').doc(userCredential.user!.uid).get();
      
      // Create profile if it doesn't exist (handles migrated users or new users)
      if (!courierDoc.exists) {
        await _createCourierProfile(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          fullName: userCredential.user!.displayName ?? '',
          phone: '',
        );
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Create courier profile in Firestore
  Future<void> _createCourierProfile({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
  }) async {
    await _firestore.collection('couriers').doc(uid).set({
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'status': 'pending_verification', // pending_verification, verified, suspended
      'verified': false,
      'isOnline': false,
      'rating': 0.0,
      'totalDeliveries': 0,
      'totalEarnings': 0.0,
      'profileCompleted': fullName.isNotEmpty && phone.isNotEmpty,
      'phoneVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Submit verification documents
  Future<void> submitVerification({
    required String idNumber,
    required String vehicleName,
    required String plateNumber,
    required String nextOfKinName,
    required String nextOfKinPhone,
    required String nextOfKinNIN,
    required String idFrontUrl,
    required String idBackUrl,
    required String faceVideoUrl,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    await _firestore.collection('couriers').doc(uid).update({
      'verification': {
        'idNumber': idNumber,
        'vehicleName': vehicleName,
        'plateNumber': plateNumber,
        'nextOfKin': {
          'name': nextOfKinName,
          'phone': nextOfKinPhone,
          'nin': nextOfKinNIN,
        },
        'documents': {
          'idFront': idFrontUrl,
          'idBack': idBackUrl,
          'faceScan': faceVideoUrl,
        },
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, approved, rejected
      },
      'status': 'pending_verification',
      'verified': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Sign out
  Future<void> signOut() async {
    // Remove FCM token before signing out
    try {
      await FCMService().removeToken();
    } catch (e) {
      print('Error removing FCM token: $e');
    }
    
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Delete account
  Future<void> deleteAccount() async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    // Delete courier profile
    await _firestore.collection('couriers').doc(uid).delete();

    // Delete user account
    await currentUser?.delete();
  }
}
