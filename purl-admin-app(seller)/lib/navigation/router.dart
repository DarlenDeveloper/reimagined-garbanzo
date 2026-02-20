import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/verify_code_screen.dart';
import '../screens/store_setup_screen.dart';
import '../screens/main_screen.dart';
import '../screens/ads_screen.dart';
import '../screens/runner_code_screen.dart';
import '../screens/account_type_screen.dart';
import '../screens/loading_screen.dart';
import '../screens/store_verification_screen.dart';
import '../services/auth_state_notifier.dart';

final _authStateNotifier = AuthStateNotifier();

final router = GoRouter(
  initialLocation: '/',
  refreshListenable: _authStateNotifier,
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final isLoggingIn = state.matchedLocation == '/login' || 
                        state.matchedLocation == '/signup' ||
                        state.matchedLocation == '/forgot-password' ||
                        state.matchedLocation == '/verify-email' ||
                        state.matchedLocation == '/account-type' ||
                        state.matchedLocation == '/runner-code';

    // If not logged in and not on a login page, redirect to login
    if (!isLoggedIn && !isLoggingIn) {
      return '/login';
    }

    // If logged in and on login page, redirect to loading/dashboard
    if (isLoggedIn && isLoggingIn) {
      return '/loading';
    }

    // If on root and logged in, go to loading
    if (state.matchedLocation == '/' && isLoggedIn) {
      return '/loading';
    }

    return null; // No redirect needed
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/loading',
      builder: (context, state) => const LoadingScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) => const VerifyCodeScreen(),
    ),
    GoRoute(
      path: '/account-type',
      builder: (context, state) => const AccountTypeScreen(),
    ),
    GoRoute(
      path: '/runner-code',
      builder: (context, state) => const RunnerCodeScreen(),
    ),
    GoRoute(
      path: '/store-setup',
      builder: (context, state) => const StoreSetupScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const MainScreen(),
    ),
    GoRoute(
      path: '/ads',
      builder: (context, state) => const AdsScreen(),
    ),
    GoRoute(
      path: '/store-verification',
      builder: (context, state) {
        final isRenewal = state.uri.queryParameters['renewal'] == 'true';
        return StoreVerificationScreen(isRenewal: isRenewal);
      },
    ),
  ],
);
