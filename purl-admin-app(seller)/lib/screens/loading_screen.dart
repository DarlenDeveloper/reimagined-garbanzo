import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
      systemNavigationBarColor: Colors.black,
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
    
    // Load store data in background
    try {
      _storeId = await _storeService.getUserStoreId();
      if (_storeId != null) {
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
      }
    } catch (e) {
      // Continue anyway
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
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Store logo or app logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey[900],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _logoUrl != null && _logoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _logoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Image.asset(
                            'assets/images/mainpurllogo.png',
                            fit: BoxFit.cover,
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/images/mainpurllogo.png',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/images/mainpurllogo.png',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(height: 20),
              // Store name or app name
              Text(
                _storeName ?? 'Purl Admin',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),
              // Loading indicator
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Setting up your store...',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
