import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();

  // Inputs pré-configurados com a Natália para acelerar seus testes
  final TextEditingController _nomeController =
      TextEditingController(text: 'Natália Silva');
  final TextEditingController _emailController =
      TextEditingController(text: 'natalia@email.com');
  final TextEditingController _senhaController =
      TextEditingController(text: '12345678');

  String _tipoUsuario = 'PAI_MAE'; // PAI_MAE ou CUIDADOR
  bool _aceitouTermos = true;
  bool _carregando = false;

  // Função assíncrona que dispara o cadastro real para o backend NestJS
  void _cadastrarNoSupabase() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_aceitouTermos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa aceitar os Termos de Uso.'),
        ),
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      // O IP 10.0.2.2 mapeia diretamente o localhost do seu notebook de dentro do emulador Android
      final url = Uri.parse('http://10.0.2');

      final resposta = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': _nomeController.text.trim(),
          'email': _emailController.text.trim(),
          'tipo': _tipoUsuario,
        }),
      );

      final dadosResposta = jsonDecode(resposta.body);

      if (resposta.statusCode == 201 || dadosResposta['sucesso'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tipoUsuario == 'PAI_MAE'
                  ? '🚀 Perfil de Natália salvo com sucesso no Supabase!'
                  : '🚀 Perfil de ohmae_baba salvo com sucesso no Supabase!',
            ),
            backgroundColor: AppTheme.turquesaPrincipal,
          ),
        );
        Navigator.pop(context); // Fecha a tela e retorna ao login
      } else {
        throw Exception(dadosResposta['message'] ?? 'Erro no cadastro.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Erro na integração: ${e.toString().replaceAll('Exception:', '')}',
          ),
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
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textoEscuro),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
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
                        Text(
                          'Ohmae',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textoEscuro,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Criar sua conta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoEscuro,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gerencie e compartilhe a rotina de cuidado com segurança.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
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
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _tipoUsuario,
                        decoration: InputDecoration(
                          labelText: 'Você é:',
                          prefixIcon: const Icon(
                            Icons.badge_outlined,
                            color: AppTheme.turquesaPrincipal,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'PAI_MAE',
                            child: Text('Mãe / Pai '),
                          ),
                          DropdownMenuItem(
                            value: 'CUIDADOR',
                            child: Text('Cuidador (a) / Babá '),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _tipoUsuario = v!;
                            if (_tipoUsuario == 'CUIDADOR') {
                              _nomeController.text = 'ohmae_baba';
                              _emailController.text = 'baba@email.com';
                            } else {
                              _nomeController.text = 'Natália Silva';
                              _emailController.text = 'natalia@email.com';
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nomeController,
                        style: const TextStyle(
                          color: AppTheme.textoEscuro,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Nome',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Insira o nome' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          color: AppTheme.textoEscuro,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: const Icon(Icons.mail_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Insira um e-mail válido'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _senhaController,
                        obscureText: true,
                        style: const TextStyle(color: AppTheme.textoEscuro),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (v) => v == null || v.length < 8
                            ? 'Mínimo de 8 caracteres'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: _aceitouTermos,
                            activeColor: AppTheme.turquesaPrincipal,
                            onChanged: (v) => setState(() => _aceitouTermos = v!),
                          ),
                          const Expanded(
                            child: Text(
                              'Aceito os termos de privacidade da Ohmae.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _carregando ? null : _cadastrarNoSupabase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.turquesaPrincipal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _carregando
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Concluir Cadastro',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.check, size: 18),
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