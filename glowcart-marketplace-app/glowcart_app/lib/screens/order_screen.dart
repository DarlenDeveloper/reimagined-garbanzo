import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Order',
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }
}
