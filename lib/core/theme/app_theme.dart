import 'package:flutter/material.dart';

class AppTheme {
  // 1. Quatro Cores Oficiais do Guia Visual
  static const Color cremeFundo = Color(0xffF9F6F0);
  static const Color aquaPrincipal = Color(0xff5EAEA4);
  static const Color coralAlerta = Color(0xffFCA690);
  static const Color amareloStatus = Color(0xffFCD067);

  // Cores de Apoio e Contraste AA
  static const Color textoPrincipal = Color(0xff142321);
  static const Color textoDeAcao = Color(0xff3B7D75);
  static const Color textoSecundario = Color(0xff7EBEB4);
  static const Color superficieCard = Colors.white;
  static const Color bordaInativa = Color(0xffE1ECEF);

  // 2. Fundamentos de Raios (Bordas Arredondadas Oficiais)
  static double get raioCampo => 16.0;
  static double get raioCartao => 24.0;
  static double get raioPetala => 999.0;

  // 3. Sistema de Sombras do Guia Visual (0 / 4 / 8 / 15px de Blur sutil)
  static List<BoxShadow> get sombraSutil => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ];

  // 4. Configuração da Tipografia Oficial (Fonte Inter)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cremeFundo,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.light(
        primary: aquaPrincipal,
        secondary: coralAlerta,
        surface: superficieCard,
        error: Colors.redAccent,
      ),
      textTheme: const TextTheme(
        // H1 - Títulos Grandes (Ex: Bem-vinda de volta)
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textoPrincipal, letterSpacing: -0.5),
        // H2 - Títulos de Seção (Ex: Rotina de hoje)
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textoPrincipal, letterSpacing: -0.3),
        // Inputs e Textos de Ação (Ex: Salvar e continuar)
        bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textoPrincipal),
        // Textos Secundários e Placeholders
        bodyMedium: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.normal),
      ),
    );
  }
}
