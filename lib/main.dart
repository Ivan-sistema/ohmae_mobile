import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart'; // O import que faltava para achar a classe!

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
      home: const LoginScreen(), // Agora o compilador sabe exatamente o que é!
    );
  }
}
