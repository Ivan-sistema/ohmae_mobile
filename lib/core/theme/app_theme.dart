import 'package:flutter/material.dart';

class AppTheme {
  // As cores oficiais extraídas diretamente do seu design do logotipo
  static const Color turquesaPrincipal = Color(
    0xff5EAEA4,
  ); // O lindo Aqua dos botões
  static const Color coralDestaque = Color(
    0xffFCA690,
  ); // O Coral para alertas/links
  static const Color amareloStatus = Color(
    0xffFCD067,
  ); // O Amarelo sutil das tags
  static const Color fundoCreme = Color(
    0xffF9F6F0,
  ); // O fundo fosco e confortável para as mães
  static const Color textoEscuro = Color(
    0xff2A3A38,
  ); // O cinza escuro sofisticado dos textos

  // Configuração do Tema Light do Flutter
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: fundoCreme,
      colorScheme: const ColorScheme.light(
        primary: turquesaPrincipal,
        secondary: coralDestaque,
        surface: Colors.white,
        error: Colors.redAccent,
      ),
    );
  }
}
