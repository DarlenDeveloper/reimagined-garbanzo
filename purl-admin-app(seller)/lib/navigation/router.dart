import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/verify_code_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/store_setup_screen.dart';
import '../screens/main_screen.dart';
import '../screens/ads_screen.dart';
import '../screens/runner_code_screen.dart';
import '../screens/account_type_screen.dart';
import '../screens/loading_screen.dart';

final router = GoRouter(
  initialLocation: '/',
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
      path: '/subscription',
      builder: (context, state) => const SubscriptionScreen(),
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
  ],
);
