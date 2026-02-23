import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  // Brand colors
  static const Color popRed = Color(0xFFfb2a0a);
  static const Color popButtonRed = Color(0xFFb71000);

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      _showError('Please enter your email');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.sendPasswordResetEmail(email);
      setState(() => _emailSent = true);
    } catch (e) {
      _showError('Failed to send reset email. Please check your email address.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: popRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // Back button
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20), // 40/2
                  ),
                  child: const Icon(Icons.chevron_left, size: 24, color: Colors.black),
                ),
              ),
              
              const SizedBox(height: 48),
              
              if (_emailSent) ...[
                // Success state
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mark_email_read_outlined, size: 40, color: Colors.black),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Check Your Email',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'We sent a password reset link to',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _emailController.text.trim(),
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 48),
                      GestureDetector(
                        onTap: () => context.go('/'),
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color: popButtonRed,
                            borderRadius: BorderRadius.circular(26), // 52/2
                          ),
                          child: Center(
                            child: Text(
                              'Back to Login',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => setState(() => _emailSent = false),
                        child: Text(
                          'Try a different email',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: popRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Input state
                Center(
                  child: Text(
                    'Forgot Password',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Center(
                  child: Text(
                    'Enter your email address and we\'ll send\nyou a link to reset your password.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Email field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(26), // 52/2
                      ),
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading,
                        style: GoogleFonts.poppins(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Send button
                GestureDetector(
                  onTap: _isLoading ? null : _sendResetEmail,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _isLoading ? Colors.grey[400] : popButtonRed,
                      borderRadius: BorderRadius.circular(26), // 52/2
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Send Reset Link',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Back to login link
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/'),
                  child: Text(
                    'Back to Login',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: popRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
