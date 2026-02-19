import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/sign_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/privacy_consent_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/verify_code_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/interests_screen.dart';
import '../screens/complete_profile_screen.dart';
import '../screens/main_screen.dart';
import '../screens/checkout_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isAuthRoute = state.matchedLocation == '/' || 
                        state.matchedLocation == '/signup' ||
                        state.matchedLocation == '/forgot-password' ||
                        state.matchedLocation == '/verify-email' ||
                        state.matchedLocation == '/verify-reset-code' ||
                        state.matchedLocation == '/reset-password' ||
                        state.matchedLocation == '/auth' ||
                        state.matchedLocation == '/onboarding';
    
    if (user == null && !isAuthRoute) {
      return '/';
    }
    if (user != null && state.matchedLocation == '/') {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SignScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const PrivacyConsentScreen(),
    ),
    GoRoute(
      path: '/login',
      redirect: (context, state) => '/',
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) => const VerifyCodeScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/verify-reset-code',
      builder: (context, state) => const VerifyCodeScreen(isPasswordReset: true),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    GoRoute(
      path: '/interests',
      builder: (context, state) => const InterestsScreen(isOnboarding: true),
    ),
    GoRoute(
      path: '/complete-profile',
      builder: (context, state) => const CompleteProfileScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CheckoutScreen(
          promoCode: extra?['promoCode'] as String?,
          promoDiscount: extra?['promoDiscount'] as double?,
          discountId: extra?['discountId'] as String?,
          discountStoreId: extra?['discountStoreId'] as String?,
        );
      },
    ),
  ],
);
