import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check onboarding status and return the next route
  /// Returns null if onboarding is complete
  Future<String?> getNextOnboardingStep() async {
    final user = _auth.currentUser;
    if (user == null) return '/welcome';

    // Check if email is verified (for email/password sign-ups)
    if (!user.emailVerified && user.providerData.any((p) => p.providerId == 'password')) {
      return '/email-verification';
    }

    // Get courier profile
    final courierDoc = await _firestore.collection('couriers').doc(user.uid).get();
    
    if (!courierDoc.exists) {
      // Profile doesn't exist - shouldn't happen but handle it
      return '/welcome';
    }

    final data = courierDoc.data()!;

    // Check if profile is completed (name and phone)
    final profileCompleted = data['profileCompleted'] ?? false;
    final hasName = (data['fullName'] as String?)?.isNotEmpty ?? false;
    final hasPhone = (data['phone'] as String?)?.isNotEmpty ?? false;

    if (!profileCompleted || !hasName || !hasPhone) {
      return '/profile-completion';
    }

    // Check if phone is verified
    final phoneVerified = data['phoneVerified'] ?? false;
    if (!phoneVerified) {
      return '/phone-verification';
    }

    // Check if verification documents are submitted
    final verification = data['verification'] as Map<String, dynamic>?;
    if (verification == null || verification['status'] == null) {
      return '/verification';
    }

    // Check verification status
    final verificationStatus = data['status'] ?? 'pending_verification';
    final verified = data['verified'] ?? false;
    
    switch (verificationStatus) {
      case 'pending_verification':
        // Check if documents are submitted
        if (verification != null && verification['status'] != null) {
          return '/pending-verification';
        }
        return '/verification';
      case 'verified':
        if (verified) {
          return null; // Onboarding complete, go to home
        }
        return '/pending-verification';
      case 'suspended':
        return '/suspended';
      default:
        return '/verification';
    }
  }

  /// Check if user needs email verification
  Future<bool> needsEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    // Only check for email/password sign-ups
    final hasPasswordProvider = user.providerData.any((p) => p.providerId == 'password');
    return hasPasswordProvider && !user.emailVerified;
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Reload user to check email verification status
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }
}
