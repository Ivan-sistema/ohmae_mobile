import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final bool carregando;
  final IconData? iconeAcao;

  const CustomButton({
    super.key,
    required this.texto,
    required this.onPressed,
    this.carregando = false,
    this.iconeAcao,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: carregando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.aquaPrincipal,
          foregroundColor: Colors.white,
          // Cores opacas recomendadas para o estado Desabilitado do manual
          disabledBackgroundColor: AppTheme.bordaInativa,
          disabledForegroundColor: Colors.grey.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.raioCampo)),
          elevation: 0,
        ),
        child: carregando
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(texto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (iconeAcao != null) ...[
                    const SizedBox(width: 8),
                    Icon(iconeAcao, size: 18),
                  ],
                ],
              ),
      ),
    );
  }
}
