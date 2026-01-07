import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/store_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _logoController;
  late AnimationController _transitionController;
  
  late Animation<double> _textFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoMove;
  late Animation<double> _bgFade;
  
  bool _showLogin = false;

  @override
  void initState() {
    super.initState();
    
    // Set status bar for black background
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    
    // Text fade in then out
    _textController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    
    // Logo scale and move
    _logoController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _logoScale = Tween<double>(begin: 1.0, end: 0.6).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeInOut));
    _logoMove = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeInOut));
    
    // Background transition
    _transitionController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _transitionController, curve: Curves.easeOut));
    
    _startAnimation();
  }

  void _startAnimation() async {
    // Check if user is already logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Show brief splash then navigate to loading
      await Future.delayed(const Duration(milliseconds: 800));
      _textController.forward();
      await Future.delayed(const Duration(milliseconds: 1200));
      
      final storeService = StoreService();
      final storeId = await storeService.getUserStoreId();
      if (mounted) {
        if (storeId != null) {
          context.go('/loading');
        } else {
          context.go('/account-type');
        }
      }
      return;
    }

    // Not logged in - show splash animation and login
    // Show text
    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();
    
    // Wait, then fade out text
    await Future.delayed(const Duration(milliseconds: 2000));
    _textController.reverse();
    
    // Move logo up and shrink
    await Future.delayed(const Duration(milliseconds: 600));
    _logoController.forward();
    
    // Transition background and show login
    await Future.delayed(const Duration(milliseconds: 800));
    _transitionController.forward();
    
    // Update system UI for white background
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _showLogin = true);
  }

  @override
  void dispose() {
    _textController.dispose();
    _logoController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Black background with logo
          AnimatedBuilder(
            animation: Listenable.merge([_textFade, _logoScale, _logoMove, _bgFade]),
            builder: (context, child) {
              return Container(
                color: Color.lerp(Colors.black, Colors.white, _bgFade.value),
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, -_logoMove.value * (screenHeight * 0.35)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/images/mainpurllogo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        // Text below logo (fades out)
                        SizedBox(height: 16 * (1 - _logoMove.value)),
                        Opacity(
                          opacity: _textFade.value * (1 - _logoMove.value),
                          child: Column(
                            children: [
                              Text('Purl Admin', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                              const SizedBox(height: 8),
                              Text('Buy • Sell • Deliver', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400], letterSpacing: 2)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Login content slides up
          if (_showLogin)
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              bottom: 0,
              child: const _LoginContent(),
            ),
        ],
      ),
    );
  }
}

// Login content without scaffold - embedded in splash
class _LoginContent extends StatefulWidget {
  const _LoginContent();

  @override
  State<_LoginContent> createState() => _LoginContentState();
}

class _LoginContentState extends State<_LoginContent> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _storeService = StoreService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmail(email: email, password: password);
      await _navigateBasedOnStoreAccess();
    } on FirebaseAuthException catch (e) {
      _showError(_getErrorMessage(e.code));
    } catch (e) {
      _showError('An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        await _navigateBasedOnStoreAccess();
      }
    } catch (e) {
      _showError('Google sign in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateBasedOnStoreAccess() async {
    final storeId = await _storeService.getUserStoreId();
    if (mounted) {
      if (storeId != null) {
        context.go('/loading');
      } else {
        context.go('/account-type');
      }
    }
  }

  void _showAppleNotAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please use other auth methods'), backgroundColor: Colors.black, behavior: SnackBarBehavior.floating),
    );
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email';
      case 'wrong-password': return 'Incorrect password';
      case 'invalid-credential': return 'Invalid email or password';
      default: return 'An error occurred. Please try again';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[600], behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _slideController,
        child: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text('Welcome Back', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.black)),
                const SizedBox(height: 4),
                Text('Sign in to your store', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 32),
                // Social Buttons
                _buildSocialButton(Icons.g_mobiledata, 'Continue with Google', onTap: _signInWithGoogle),
                const SizedBox(height: 12),
                _buildSocialButton(Icons.apple, 'Continue with Apple', onTap: _showAppleNotAvailable),
                const SizedBox(height: 24),
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('or', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13))),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 24),
                // Email
                Text('Email', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
                const SizedBox(height: 8),
                _buildTextField(_emailController, 'Enter your email', false, TextInputType.emailAddress),
                const SizedBox(height: 20),
                // Password
                Text('Password', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
                const SizedBox(height: 8),
                _buildTextField(_passwordController, 'Enter your password', true, TextInputType.visiblePassword),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => context.push('/forgot-password'),
                    child: Text('Forgot Password?', style: GoogleFonts.poppins(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(height: 28),
                // Sign In Button
                GestureDetector(
                  onTap: _isLoading ? null : _signInWithEmail,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(color: _isLoading ? Colors.grey : Colors.black, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Sign In', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
                  ),
                ),
                const SizedBox(height: 24),
                // Register Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have a store? ", style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14)),
                      GestureDetector(
                        onTap: () => context.push('/signup'),
                        child: Text('Create one', style: GoogleFonts.poppins(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Colors.black),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isPassword, TextInputType type) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: type,
      style: GoogleFonts.poppins(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscurePassword ? Iconsax.eye_slash : Iconsax.eye, color: Colors.grey[500], size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
      ),
    );
  }
}
