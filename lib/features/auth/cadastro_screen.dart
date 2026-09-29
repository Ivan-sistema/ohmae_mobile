import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/app_theme.dart';

/// Erro retornado pela API (status fora de 2xx ou `sucesso: false`).
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
  // TODO: ajuste host, porta e rota para o seu backend NestJS.
  // Emulador Android: 10.0.2.2 | Dispositivo físico: IP da sua máquina.
  static const String _apiBaseUrl = 'http://10.0.2.2:3000';
  static const String _rotaCadastro = '/usuarios';
  static const Duration _timeout = Duration(seconds: 10);

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  final _emailFocus = FocusNode();
  final _senhaFocus = FocusNode();
  final _confirmarSenhaFocus = FocusNode();

  String _perfilSelecionado = 'MAE';
  bool _aceitouTermos = false;
  bool _carregando = false;
  bool _senhaOculta = true;
  bool _confirmarSenhaOculta = true;

  /// Verificação silenciosa (não exibe erro nenhum na tela): o botão só habilita
  /// quando todos os campos passam nos validators E os termos foram aceitos.
  bool get _formularioValido =>
      _validarNome(_nomeController.text) == null &&
      _validarEmail(_emailController.text) == null &&
      _validarSenha(_senhaController.text) == null &&
      _validarConfirmacao(_confirmarSenhaController.text) == null &&
      _aceitouTermos;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _nomeController,
      _emailController,
      _senhaController,
      _confirmarSenhaController,
    ]) {
      c.addListener(_atualizarEstado);
    }
  }

  void _atualizarEstado() => setState(() {});

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _emailFocus.dispose();
    _senhaFocus.dispose();
    _confirmarSenhaFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Lógica
  // ---------------------------------------------------------------------------

  Future<void> _cadastrarFamilia() async {
    if (_carregando) return;

    FocusScope.of(context).unfocus();

    // Segurança extra: o botão já só habilita com tudo válido.
    if (!_formularioValido || !_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      final resposta = await http
          .post(
            Uri.parse('$_apiBaseUrl$_rotaCadastro'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nome': _nomeController.text.trim(),
              'email': _emailController.text.trim(),
              'senha': _senhaController.text,
              'tipo': 'PAI_MAE',
            }),
          )
          .timeout(_timeout);

      final dados = _decodificarResposta(resposta);

      final sucesso = resposta.statusCode == 200 ||
          resposta.statusCode == 201 ||
          dados['sucesso'] == true;

      if (!sucesso) {
        throw _ApiException(_extrairMensagem(dados));
      }

      if (!mounted) return;
      _mostrarAlerta(
        '🚀 Conta criada com sucesso!',
        AppTheme.turquesaPrincipal,
      );
      Navigator.pop(context);
    } on TimeoutException {
      _mostrarAlerta(
        '❌ O servidor demorou para responder. Tente novamente.',
        Colors.redAccent,
      );
    } on SocketException {
      _mostrarAlerta(
        '❌ Sem conexão com o servidor. Verifique sua internet.',
        Colors.redAccent,
      );
    } on http.ClientException {
      _mostrarAlerta(
        '❌ Não foi possível se conectar ao servidor.',
        Colors.redAccent,
      );
    } on FormatException {
      _mostrarAlerta(
        '❌ Resposta inválida do servidor. Contate o suporte.',
        Colors.redAccent,
      );
    } on _ApiException catch (e) {
      _mostrarAlerta('❌ ${e.mensagem}', Colors.redAccent);
    } catch (_) {
      _mostrarAlerta(
        '❌ Ocorreu um erro inesperado. Tente novamente.',
        Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  /// Converte o corpo em Map. Lança [FormatException] se estiver vazio/inválido.
  Map<String, dynamic> _decodificarResposta(http.Response resposta) {
    if (resposta.body.isEmpty) {
      throw const FormatException('Resposta vazia.');
    }

    final decodificado = jsonDecode(resposta.body);
    if (decodificado is! Map<String, dynamic>) {
      throw const FormatException('Formato inesperado.');
    }
    return decodificado;
  }

  /// O NestJS pode devolver `message` como String ou como lista (validação).
  String _extrairMensagem(Map<String, dynamic> dados) {
    final mensagem = dados['message'];
    if (mensagem is List && mensagem.isNotEmpty) {
      return mensagem.join('\n');
    }
    if (mensagem is String && mensagem.isNotEmpty) {
      return mensagem;
    }
    return 'Erro interno no cadastro.';
  }

  void _mostrarAlerta(String mensagem, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem), backgroundColor: cor));
  }

  // ---------------------------------------------------------------------------
  // Validators
  // ---------------------------------------------------------------------------

  String? _validarNome(String? v) {
    final nome = v?.trim() ?? '';
    if (nome.isEmpty) return 'Insira seu nome completo';
    if (nome.split(RegExp(r'\s+')).length < 2) {
      return 'Informe nome e sobrenome';
    }
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

  String? _validarConfirmacao(String? v) {
    if (v == null || v.isEmpty) return 'Confirme sua senha';
    if (v != _senhaController.text) return 'As senhas digitadas não conferem';
    return null;
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  InputDecoration _decoracao({
    required String label,
    required String hint,
    required IconData icone,
    Widget? sufixo,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icone),
      suffixIcon: sufixo,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _botaoVisibilidade({
    required bool oculta,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(
        oculta ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: Colors.grey,
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppTheme.textoEscuro,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              _buildLogo(),
              const SizedBox(height: 24),
              const Text(
                'Cadastro de Gestores',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoEscuro,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Crie a conta master da família. Apenas os pais '
                  'gerenciam acessos e cadastram os bebês.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildFormCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
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
    );
  }

  Widget _buildFormCard() {
    final mae = _perfilSelecionado == 'MAE';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _perfilSelecionado,
                decoration: _decoracao(
                  label: 'Seu Perfil',
                  hint: '',
                  icone: Icons.family_restroom,
                ).copyWith(
                  prefixIcon: const Icon(
                    Icons.family_restroom,
                    color: AppTheme.turquesaPrincipal,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'MAE', child: Text('Mãe')),
                  DropdownMenuItem(value: 'PAI', child: Text('Pai')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _perfilSelecionado = v);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                style: const TextStyle(
                  color: AppTheme.textoEscuro,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _decoracao(
                  label: 'Nome Completo',
                  hint: mae ? 'Ex: Natália Silva' : 'Ex: Ivan Francisco',
                  icone: Icons.person_outline,
                ),
                validator: _validarNome,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onFieldSubmitted: (_) => _senhaFocus.requestFocus(),
                style: const TextStyle(
                  color: AppTheme.textoEscuro,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _decoracao(
                  label: 'E-mail',
                  hint: mae ? 'Ex: natalia@email.com' : 'Ex: ivan@email.com',
                  icone: Icons.mail_outline,
                ),
                validator: _validarEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _senhaController,
                focusNode: _senhaFocus,
                obscureText: _senhaOculta,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _confirmarSenhaFocus.requestFocus(),
                style: const TextStyle(color: AppTheme.textoEscuro),
                decoration: _decoracao(
                  label: 'Crie uma Senha',
                  hint: 'Mínimo de 8 caracteres',
                  icone: Icons.lock_outline,
                  sufixo: _botaoVisibilidade(
                    oculta: _senhaOculta,
                    onPressed: () =>
                        setState(() => _senhaOculta = !_senhaOculta),
                  ),
                ),
                validator: _validarSenha,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmarSenhaController,
                focusNode: _confirmarSenhaFocus,
                obscureText: _confirmarSenhaOculta,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) {
                  if (_formularioValido) _cadastrarFamilia();
                },
                style: const TextStyle(color: AppTheme.textoEscuro),
                decoration: _decoracao(
                  label: 'Confirme sua Senha',
                  hint: 'Digite a senha novamente',
                  icone: Icons.lock_reset_outlined,
                  sufixo: _botaoVisibilidade(
                    oculta: _confirmarSenhaOculta,
                    onPressed: () => setState(
                      () => _confirmarSenhaOculta = !_confirmarSenhaOculta,
                    ),
                  ),
                ),
                validator: _validarConfirmacao,
              ),
              const SizedBox(height: 12),
              _buildTermos(),
              const SizedBox(height: 16),
              _buildBotaoCadastrar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermos() {
    return Row(
      children: [
        Checkbox(
          value: _aceitouTermos,
          activeColor: AppTheme.turquesaPrincipal,
          onChanged: (v) => setState(() => _aceitouTermos = v ?? false),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _aceitouTermos = !_aceitouTermos),
            child: const Text(
              'Declaro que sou o responsável legal e aceito os termos.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoCadastrar() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed:
            (_formularioValido && !_carregando) ? _cadastrarFamilia : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.turquesaPrincipal,
          foregroundColor: Colors.white,
          // Cinza quando incompleto; mantém o turquesa enquanto carrega.
          disabledBackgroundColor: _carregando
              ? AppTheme.turquesaPrincipal
              : Colors.grey.withValues(alpha: 0.2),
          disabledForegroundColor:
              _carregando ? Colors.white : Colors.grey.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _carregando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Criar Conta Família',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }
}