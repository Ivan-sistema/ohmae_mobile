import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';

class _ApiException implements Exception {
  const _ApiException(this.mensagem);
  final String mensagem;
}

class ResetSenhaScreen extends StatefulWidget {
  const ResetSenhaScreen({super.key});

  @override
  State<ResetSenhaScreen> createState() => _ResetSenhaScreenState();
}

class _ResetSenhaScreenState extends State<ResetSenhaScreen> {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _carregando = false;

  bool get _formularioValido => _emailRegex.hasMatch(_emailController.text.trim());

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_atualizarEstado);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _atualizarEstado() => setState(() {});

  Future<void> _enviarInstrucoes() async {
    if (_carregando) return;

    FocusScope.of(context).unfocus();

    if (!_formularioValido || !_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      final resposta = await http
          .post(
            ApiConfig.uri(ApiConfig.rotaRecuperarSenha),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': _emailController.text.trim()}),
          )
          .timeout(ApiConfig.timeout);

      final dados = _decodificarResposta(resposta);
      final sucesso = resposta.statusCode == 200 || resposta.statusCode == 201 || dados['sucesso'] == true;

      if (!sucesso) {
        throw _ApiException(dados['message'] ?? 'E-mail não encontrado.');
      }

      if (!mounted) return;
      _mostrarAlerta('🚀 Instruções enviadas com sucesso!', AppTheme.aquaPrincipal);
      Navigator.pop(context);
    } on TimeoutException {
      _mostrarAlerta('❌ O servidor demorou para responder. Tente novamente.', Colors.redAccent);
    } on SocketException {
      _mostrarAlerta('❌ Sem conexão com o servidor. Verifique sua internet.', Colors.redAccent);
    } on _ApiException catch (e) {
      _mostrarAlerta('❌ ${e.mensagem}', Colors.redAccent);
    } catch (_) {
      _mostrarAlerta('❌ Ocorreu um erro inesperado. Tente novamente.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Map<String, dynamic> _decodificarResposta(http.Response resposta) {
    if (resposta.body.isEmpty) throw const FormatException('Resposta vazia.');
    final decodificado = jsonDecode(resposta.body);
    if (decodificado is! Map<String, dynamic>) throw const FormatException('Formato inesperado.');
    return decodificado;
  }

  void _mostrarAlerta(String mensagem, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem), backgroundColor: cor));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cremeFundo,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textoPrincipal),
                  onPressed: () => Navigator.pop(context),
                ),
                Center(
                  child: SizedBox(
                    height: 50,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Icon(Icons.child_care, color: AppTheme.aquaPrincipal, size: 36),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.coralAlerta.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.key_outlined, size: 12, color: AppTheme.coralAlerta),
                      SizedBox(width: 6),
                      Text(
                        'RECONECTAR ACESSO',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.coralAlerta, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vamos criar uma nova\nsenha',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textoPrincipal, height: 1.2, letterSpacing: -0.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Informe o e-mail usado na sua conta. Enviaremos instruções simples para você voltar com segurança.',
                  style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.raioCartao),
                    boxShadow: AppTheme.sombraSutil,
                  ),
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _emailController,
                        label: 'E-mail',
                        hintText: 'voce@email.com',
                        prefixIcon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final email = v?.trim() ?? '';
                          if (email.isEmpty) return 'Insira seu e-mail';
                          if (!_emailRegex.hasMatch(email)) return 'O e-mail digitado é inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        texto: 'Enviar instruções',
                        carregando: _carregando,
                        iconeAcao: Icons.send_outlined,
                        onPressed: _formularioValido ? _enviarInstrucoes : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.amareloStatus.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.amareloStatus.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.mail_lock_outlined, color: AppTheme.textoPrincipal, size: 20),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cheque também o spam', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textoPrincipal)),
                            SizedBox(height: 2),
                            Text('O link é seguro e fica disponível por 30 minutos.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('← Voltar para entrar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
