import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';

class ResetSenhaScreen extends StatefulWidget {
  const ResetSenhaScreen({super.key});

  @override
  State<ResetSenhaScreen> createState() => _ResetSenhaScreenState();
}

class _ResetSenhaScreenState extends State<ResetSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // E-mail padrão conforme diretriz sênior
  final TextEditingController _emailController =
      TextEditingController(text: 'natalia@email.com');
      
  bool _carregando = false;

  // Envia a solicitação de redefinição de senha para a API
  void _recuperarSenha() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      // Simulação E2E/MVP de envio de link de recuperação
      // Em produção real, você usará o endpoint de Auth do Supabase/NestJS
      await Future.delayed(const Duration(seconds: 1)); // Simula o delay de rede

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚀 Link de redefinição enviado para natalia@email.com!'),
          backgroundColor: AppTheme.turquesaPrincipal,
        ),
      );
      Navigator.pop(context); // Retorna à tela de login
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // Botão Voltar
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textoEscuro),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              
              // Logotipo
              Center(
                child: SizedBox(
                  height: 70,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.turquesaPrincipal,
                        ),
                        SizedBox(width: 8),
                        Text('Ohmae', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textoEscuro)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                'Recuperar senha',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoEscuro,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Insira o e-mail cadastrado e enviaremos as instruções para você criar uma nova senha.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                ),
              ),
              const SizedBox(height: 35),

              // Card Branco Flutuante dos Inputs
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Input E-mail
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          color: AppTheme.textoEscuro,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: const Icon(
                            Icons.mail_outline,
                            color: AppTheme.turquesaPrincipal,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Insira um e-mail válido'
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Botão Principal Turquesa
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _carregando ? null : _recuperarSenha,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.turquesaPrincipal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _carregando
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Enviar instruções',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.send_outlined, size: 18),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
