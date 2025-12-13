import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const darkGreen = Color(0xFF1B4332);
  static const beige = Color(0xFFF5F0E8);

  final List<_SlideData> _slides = [
    _SlideData(
      titleLight: 'Discover',
      titleBold: 'Local Stores',
      subtitle: 'Near You',
      image: 'assets/images/IMG_9498.JPG',
    ),
    _SlideData(
      titleLight: 'Shop With',
      titleBold: 'Confidence',
      subtitle: 'Every Time',
      image: 'assets/images/IMG_9499.JPG',
    ),
    _SlideData(
      titleLight: 'Follow Your',
      titleBold: 'Favorite',
      subtitle: 'Vendors',
      image: 'assets/images/IMG_9500.PNG',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/auth');
    }
  }

  void _skip() {
    context.go('/auth');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              beige,
              beige.withAlpha(240),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _SlideContent(slide: _slides[index]);
                },
              ),
              Positioned(
                left: 28,
                right: 28,
                bottom: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _skip,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: darkGreen.withAlpha(150),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    _buildPageIndicator(),
                    GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: darkGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: darkGreen.withAlpha(60),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_slides.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 4,
          decoration: BoxDecoration(
            color: isActive ? darkGreen : darkGreen.withAlpha(50),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

class _SlideData {
  final String titleLight;
  final String titleBold;
  final String subtitle;
  final String image;

  _SlideData({
    required this.titleLight,
    required this.titleBold,
    required this.subtitle,
    required this.image,
  });
}

class _SlideContent extends StatelessWidget {
  final _SlideData slide;

  const _SlideContent({required this.slide});

  static const darkGreen = Color(0xFF1B4332);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text(
            slide.titleLight,
            style: GoogleFonts.poppins(
              fontSize: 42,
              fontWeight: FontWeight.w300,
              color: darkGreen,
              height: 1.1,
            ),
          ),
          Text(
            slide.titleBold,
            style: GoogleFonts.poppins(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: darkGreen,
              height: 1.1,
            ),
          ),
          Text(
            slide.subtitle,
            style: GoogleFonts.poppins(
              fontSize: 42,
              fontWeight: FontWeight.w300,
              color: darkGreen.withAlpha(120),
              height: 1.1,
            ),
          ),
          const Spacer(),
          Center(
            child: Container(
              height: screenHeight * 0.45,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: darkGreen.withAlpha(30),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  slide.image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
