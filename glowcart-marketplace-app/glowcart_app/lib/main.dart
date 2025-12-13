import 'package:flutter/material.dart';
import 'theme/theme.dart';
import 'navigation/router.dart';

void main() {
  runApp(const GlowCartApp());
}

class GlowCartApp extends StatelessWidget {
  const GlowCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GlowCart',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routerConfig: router,
    );
  }
}
