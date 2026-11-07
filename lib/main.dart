import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart'; // Import adicionado!

void main() {
  runApp(const OhmaeApp());
}

class OhmaeApp extends StatelessWidget {
  const OhmaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ohmae',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(), // Alterado de LoginScreen para SplashScreen!
    );
  }
}
