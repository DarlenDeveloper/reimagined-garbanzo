import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/store_service.dart';
import '../services/currency_service.dart';
import 'currency_selection_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  final _storeService = StoreService();
  final _currencyService = CurrencyService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String? _storeName;
  String? _logoUrl;
  String? _storeId;
  bool _needsCurrencySelection = false;

  @override
  void initState() {
    super.initState();
    
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFfb2a0a),
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    // Start fade in
    _fadeController.forward();
    
    // Check user's onboarding status
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        // No user logged in, go to login
        if (mounted) context.go('/login');
        return;
      }
      
      // Check if email is verified (skip for Google Sign-In users)
      await user.reload();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && !currentUser.emailVerified) {
        // Check if this is a Google Sign-In user (they're auto-verified)
        final isGoogleUser = currentUser.providerData.any((info) => info.providerId == 'google.com');
        
        if (!isGoogleUser) {
          // Email not verified and not a Google user, go to verify-email screen
          if (mounted) {
            await Future.delayed(const Duration(seconds: 1));
            context.go('/verify-email');
          }
          return;
        }
      }
      
      // Check if store exists
      _storeId = await _storeService.getUserStoreId();
      if (_storeId == null) {
        // No store found, check if they've selected account type
        // If not, go to account-type, otherwise go to store-setup
        if (mounted) {
          await Future.delayed(const Duration(seconds: 1));
          context.go('/account-type');
        }
        return;
      }
      
      // Store exists, load store data
      final storeData = await _storeService.getStore(_storeId!);
      if (storeData != null && mounted) {
        setState(() {
          _storeName = storeData['name'];
          _logoUrl = storeData['logoUrl'];
        });
        
        // Pre-cache the logo
        if (_logoUrl != null && _logoUrl!.isNotEmpty) {
          await precacheImage(CachedNetworkImageProvider(_logoUrl!), context);
        }
      }

      // Initialize currency service and check if currency is set
      await _currencyService.init(_storeId);
      
      if (!_currencyService.hasCurrencySet) {
        // Store doesn't have a currency set - show selection screen
        if (mounted) {
          setState(() => _needsCurrencySelection = true);
        }
        return; // Don't navigate to dashboard yet
      }
    } catch (e) {
      print('Error in loading screen: $e');
      // On error, try to go to dashboard anyway
    }
    
    // Minimum 3 seconds loading time for professional feel
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      context.go('/dashboard');
    }
  }

  void _onCurrencySelected() {
    // Currency has been selected, navigate to dashboard
    context.go('/dashboard');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show currency selection screen if needed
    if (_needsCurrencySelection && _storeId != null) {
      return CurrencySelectionScreen(
        storeId: _storeId!,
        onCurrencySelected: _onCurrencySelected,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFfb2a0a),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Store logo or app logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _logoUrl != null && _logoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _logoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Padding(
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              'assets/images/popstoreslogo.PNG',
                              fit: BoxFit.contain,
                            ),
                          ),
                          errorWidget: (context, url, error) => Padding(
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              'assets/images/popstoreslogo.PNG',
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(20),
                          child: Image.asset(
                            'assets/images/popstoreslogo.PNG',
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // Store name or app name
              Text(
                _storeName ?? 'POP Vendor',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 40),
              // Loading indicator
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Setting up your store...',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
