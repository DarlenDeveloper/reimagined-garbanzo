import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/tracking_screen.dart';
import '../screens/deliveries_screen.dart';
import '../screens/signin_screen.dart';
import '../screens/apply_screen.dart';
import '../screens/verification_screen.dart';
import '../screens/email_verification_screen.dart';
import '../screens/profile_completion_screen.dart';
import '../screens/phone_verification_screen.dart';
import '../screens/pending_verification_screen.dart';
import '../screens/withdraw_screen.dart';
import '../screens/vehicle_type_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/vehicle_info_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/signin',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/apply',
      builder: (context, state) => const ApplyScreen(),
    ),
    GoRoute(
      path: '/email-verification',
      builder: (context, state) => const EmailVerificationScreen(),
    ),
    GoRoute(
      path: '/profile-completion',
      builder: (context, state) => const ProfileCompletionScreen(),
    ),
    GoRoute(
      path: '/vehicle-type',
      builder: (context, state) => const VehicleTypeScreen(),
    ),
    GoRoute(
      path: '/phone-verification',
      builder: (context, state) => const PhoneVerificationScreen(),
    ),
    GoRoute(
      path: '/verification',
      builder: (context, state) => const VerificationScreen(),
    ),
    GoRoute(
      path: '/pending-verification',
      builder: (context, state) => const PendingVerificationScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(
      path: '/tracking',
      builder: (context, state) => const TrackingScreen(),
    ),
    GoRoute(
      path: '/deliveries',
      builder: (context, state) => const DeliveriesScreen(),
    ),
    GoRoute(
      path: '/withdraw',
      builder: (context, state) => const WithdrawScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/vehicle-info',
      builder: (context, state) => const VehicleInfoScreen(),
    ),
  ],
);
