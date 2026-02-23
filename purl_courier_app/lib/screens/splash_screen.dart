import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  final OnboardingService _onboardingService = OnboardingService();

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 4));
    
    if (!mounted) return;
    
    // Check if user is logged in
    final user = _authService.currentUser;
    
    if (user == null) {
      // Not logged in, go to welcome
      context.go('/welcome');
      return;
    }
    
    // User is logged in, check onboarding status
    final nextStep = await _onboardingService.getNextOnboardingStep();
    
    if (nextStep == null) {
      // Onboarding complete, go to home
      context.go('/home');
    } else {
      // Navigate to next onboarding step
      context.go(nextStep);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfb2a0a), // Main Red
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // POP Logo
            Image.asset(
              'assets/images/pop_logo.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              'POP RIDER',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Deliver with POP',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
