import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../services/onboarding_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _onboardingService = OnboardingService();
  bool _isLoading = false;
  bool _emailSent = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail();
    _startEmailCheckTimer();
  }

  Future<void> _sendVerificationEmail() async {
    setState(() => _isLoading = true);
    try {
      await _onboardingService.sendEmailVerification();
      setState(() => _emailSent = true);
    } catch (e) {
      _showError('Failed to send verification email');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startEmailCheckTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final verified = await _onboardingService.checkEmailVerified();
      if (verified && mounted) {
        timer.cancel();
        final nextStep = await _onboardingService.getNextOnboardingStep();
        if (nextStep != null) {
          context.go(nextStep);
        } else {
          context.go('/home');
        }
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: const Text('Verify Email'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              // Email Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.sms,
                  size: 64,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                _emailSent
                    ? 'We\'ve sent a verification link to your email. Please check your inbox and click the link to verify your account.'
                    : 'Sending verification email...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              if (_emailSent) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Waiting for verification...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                
                const SizedBox(height: 40),
                
                // Resend Button
                TextButton(
                  onPressed: _isLoading ? null : _sendVerificationEmail,
                  child: const Text('Resend Email'),
                ),
                
                const SizedBox(height: 16),
                
                // Manual Check Button
                OutlinedButton(
                  onPressed: () async {
                    final verified = await _onboardingService.checkEmailVerified();
                    if (verified && mounted) {
                      final nextStep = await _onboardingService.getNextOnboardingStep();
                      if (nextStep != null) {
                        context.go(nextStep);
                      } else {
                        context.go('/home');
                      }
                    } else {
                      _showError('Email not verified yet');
                    }
                  },
                  child: const Text('I\'ve Verified My Email'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
