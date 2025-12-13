import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Discover',
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }
}
