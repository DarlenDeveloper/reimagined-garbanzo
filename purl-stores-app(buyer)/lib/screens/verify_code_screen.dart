import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String? email;
  final bool isPasswordReset;
  
  const VerifyCodeScreen({
    super.key,
    this.email,
    this.isPasswordReset = false,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _authService = AuthService();
  Timer? _timer;
  bool _isChecking = false;
  bool _canResend = true;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerified();
    });
  }

  Future<void> _checkEmailVerified() async {
    if (_isChecking) return;
    _isChecking = true;
    
    try {
      await _authService.reloadUser();
      if (_authService.isEmailVerified && mounted) {
        _timer?.cancel();
        context.go('/interests');
      }
    } catch (e) {
      // Ignore errors
    }
    
    _isChecking = false;
  }

  Future<void> _resendEmail() async {
    if (!_canResend) return;
    
    try {
      await _authService.sendEmailVerification();
      setState(() {
        _canResend = false;
        _resendCountdown = 60;
      });
      
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_resendCountdown > 0) {
          setState(() => _resendCountdown--);
        } else {
          timer.cancel();
          setState(() => _canResend = true);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification email sent', style: GoogleFonts.poppins()),
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _manualCheck() async {
    setState(() => _isChecking = true);
    await _checkEmailVerified();
    
    if (!_authService.isEmailVerified && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email not verified yet. Please check your inbox.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange[700],
        ),
      );
    }
    setState(() => _isChecking = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? widget.email ?? 'your email';
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chevron_left, size: 24, color: Colors.black),
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Email icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_unread_outlined, size: 40, color: Colors.black),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Verify Your Email',
                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.black),
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'We sent a verification link to',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Click the link in your email to verify your account. This page will automatically redirect once verified.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500], height: 1.5),
              ),
              
              const SizedBox(height: 48),
              
              // Resend code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive the email?", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _canResend ? _resendEmail : null,
                    child: Text(
                      _canResend ? 'Resend' : 'Resend in ${_resendCountdown}s',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _canResend ? Colors.black : Colors.grey,
                        fontWeight: FontWeight.w500,
                        decoration: _canResend ? TextDecoration.underline : null,
                        decorationColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              
              // Check verification button
              GestureDetector(
                onTap: _isChecking ? null : _manualCheck,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isChecking ? Colors.grey : Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isChecking
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('I\'ve Verified My Email', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Open email app hint
              Text(
                'Check your spam folder if you don\'t see the email',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
