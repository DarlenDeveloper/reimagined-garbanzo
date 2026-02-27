import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // No clientId or serverClientId needed - google_sign_in automatically reads
    // from GoogleService-Info.plist (iOS) and google-services.json (Android)
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Initialize notifications after successful login
    await NotificationService().initialize();
    
    return credential;
  }

  // Sign up with email
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (displayName != null && credential.user != null) {
      await credential.user!.updateDisplayName(displayName);
    }
    
    // Initialize notifications after successful signup
    await NotificationService().initialize();
    
    return credential;
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    
    // Initialize notifications after successful Google sign in
    await NotificationService().initialize();
    
    return userCredential;
  }

  // Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    // Generate a nonce for security
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    // Request Apple credentials
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    // Create an OAuthCredential from the Apple credential
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    // Sign in with Firebase
    final userCredential = await _auth.signInWithCredential(oauthCredential);

    // Apple only provides the name on first sign-in, so save it
    if (appleCredential.givenName != null && userCredential.user != null) {
      final displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
      if (displayName.isNotEmpty) {
        await userCredential.user!.updateDisplayName(displayName);
      }
    }

    // Initialize notifications after successful Apple sign in
    await NotificationService().initialize();

    return userCredential;
  }

  /// Generates a cryptographically secure random nonce
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Returns the sha256 hash of [input] in hex notation
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Sign out
  Future<void> signOut() async {
    // Delete FCM token before signing out
    await NotificationService().deleteFCMToken();
    
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Reload user to check verification status
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }
}
