import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Notifier that listens to Firebase auth state changes
/// Used by GoRouter to trigger navigation updates
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }
}
