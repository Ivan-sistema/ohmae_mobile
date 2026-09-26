import 'package:flutter/material.dart';

// Importa o arquivo de identidade visual que criamos no Passo 1
import 'core/theme/app_theme.dart';

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
      // Aplica o tema sênior com as cores do seu logotipo
      theme: AppTheme.lightTheme,
      // Tela temporária apenas para testarmos a inicialização limpa
      home: const Scaffold(
        body: Center(
          child: Text(
            'Ohmae Iniciado!',
            style: TextStyle(
              color: AppTheme.textoEscuro,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
