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

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  final _emailFocus = FocusNode();
  final _senhaFocus = FocusNode();

  bool _senhaOculta = true;
  bool _aceitouTermos = false;
  bool _carregando = false;

  bool get _formularioValido =>
      _validarNome(_nomeController.text) == null &&
      _validarEmail(_emailController.text) == null &&
      _validarSenha(_senhaController.text) == null &&
      _aceitouTermos;

  @override
  void initState() {
    super.initState();
    _nomeController.addListener(_atualizarEstado);
    _emailController.addListener(_atualizarEstado);
    _senhaController.addListener(_atualizarEstado);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _emailFocus.dispose();
    _senhaFocus.dispose();
    super.dispose();
  }

  void _atualizarEstado() => setState(() {});

  Future<void> _cadastrarFamilia() async {
    if (_carregando) return;

    FocusScope.of(context).unfocus();

    if (!_formularioValido || !_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      final resposta = await http
          .post(
            ApiConfig.uri(ApiConfig.rotaCadastro),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nome': _nomeController.text.trim(),
              'email': _emailController.text.trim(),
              'senha': _senhaController.text,
              'tipo': 'PAI_MAE',
            }),
          )
          .timeout(ApiConfig.timeout);

      final dados = _decodificarResposta(resposta);
      final sucesso = resposta.statusCode == 200 || resposta.statusCode == 201 || dados['sucesso'] == true;

      if (!sucesso) {
        throw _ApiException(dados['message'] ?? 'Erro interno no cadastro.');
      }

      if (!mounted) return;
      _mostrarAlerta('🚀 Conta criada com sucesso!', AppTheme.aquaPrincipal);
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

  void _mostrarAlerta(String mensaje, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: cor));
  }

  String? _validarNome(String? v) {
    final nome = v?.trim() ?? '';
    if (nome.isEmpty) return 'Insira seu nome completo';
    if (nome.split(RegExp(r'\s+')).length < 2) return 'Informe nome e sobrenome';
    return null;
  }

  String? _validarEmail(String? v) {
    final email = v?.trim() ?? '';
    if (email.isEmpty) return 'Insira seu e-mail';
    if (!_emailRegex.hasMatch(email)) return 'O e-mail digitado é inválido';
    return null;
  }

  String? _validarSenha(String? v) {
    if (v == null || v.isEmpty) return 'Crie uma senha';
    if (v.length < 8) return 'A senha precisa ter no mínimo 8 caracteres';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cremeFundo,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textoPrincipal),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(
                height: 50,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.child_care, color: AppTheme.aquaPrincipal, size: 36),
                ),
              ),
              const SizedBox(height: 32),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Comece a cuidar com a\nOhmae',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textoPrincipal, height: 1.2, letterSpacing: -0.5),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Crie seu acesso básico. Leva menos de um minuto.', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.raioCartao),
                  boxShadow: AppTheme.sombraSutil,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _nomeController,
                        label: 'Nome',
                        hintText: 'Como podemos chamar você?',
                        prefixIcon: Icons.person_outline,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
                        validator: _validarNome,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        label: 'E-mail',
                        hintText: 'voce@email.com',
                        prefixIcon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_senhaFocus),
                        validator: _validarEmail,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _senhaController,
                        focusNode: _senhaFocus,
                        obscureText: _senhaOculta,
                        label: 'Senha',
                        hintText: 'Mínimo de 8 caracteres',
                        prefixIcon: Icons.lock_outline,
                        textInputAction: TextInputAction.done,
                        suffixIcon: IconButton(
                          icon: Icon(_senhaOculta ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
                          onPressed: () => setState(() => _senhaOculta = !_senhaOculta),
                        ),
                        validator: _validarSenha,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: _aceitouTermos,
                            activeColor: AppTheme.aquaPrincipal,
                            onChanged: (v) => setState(() => _aceitouTermos = v ?? false),
                          ),
                          const Expanded(
                            child: Text(
                              'Li e aceito os Termos de Uso e a Política de Privacidade.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textoPrincipal, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        texto: 'Criar conta',
                        carregando: _carregando,
                        iconeAcao: Icons.arrow_forward,
                        onPressed: _formularioValido ? _cadastrarFamilia : null,
),
const SizedBox(height: 24),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Text('Já tem uma conta? ', style: TextStyle(color: Colors.grey, fontSize: 13)),
GestureDetector(
onTap: () => Navigator.pop(context),
child: const Text('Entrar', style: TextStyle(color: AppTheme.aquaPrincipal, fontWeight: FontWeight.bold, fontSize: 13)),
),
],
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