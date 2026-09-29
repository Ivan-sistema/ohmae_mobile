import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/app_theme.dart';
import '../children/child_register_screen.dart';
import '../dashboard/dashboard_screen.dart';
import 'cadastro_screen.dart';
import 'reset_senha_screen.dart';

/// Erro retornado pela API (status fora de 2xx ou `sucesso: false`).
class _ApiException implements Exception {
  const _ApiException(this.mensagem);

  final String mensagem;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _apiBaseUrl = 'http://10.0.2.2:3000';
  // 🎯 Rotas casando com o controlador do NestJS.
  static const String _rotaLogin = '/usuarios/login';
  static const String _rotaVinculos = '/vinculos/usuario'; // /vinculos/usuario/{id}
  static const Duration _timeout = Duration(seconds: 10);

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _senhaFocus = FocusNode();

  bool _senhaOculta = true;
  bool _carregando = false;

  /// Verificação silenciosa para ligar/desligar o botão turquesa.
  bool get _formularioValido =>
      _validarEmail(_emailController.text) == null &&
      _validarSenha(_senhaController.text) == null;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_atualizarEstado);
    _senhaController.addListener(_atualizarEstado);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _senhaFocus.dispose();
    super.dispose();
  }

  void _atualizarEstado() => setState(() {});

  // ---------------------------------------------------------------------------
  // Lógica
  // ---------------------------------------------------------------------------

  Future<void> _realizarLogin() async {
    if (_carregando) return;

    FocusScope.of(context).unfocus();

    if (!_formularioValido || !_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      final usuarioId = await _autenticar();
      final possuiFilhos = await _usuarioPossuiFilhos(usuarioId);

      if (!mounted) return;

      if (possuiFilhos) {
        _abrirDashboard(usuarioId);
      } else {
        _mostrarSnackBar(
          '👶 Conta validada! Cadastre o perfil do bebê para começar.',
          AppTheme.turquesaPrincipal,
        );
        _abrirCadastroDoBebe();
      }
    } on TimeoutException {
      _mostrarSnackBar(
        '❌ O servidor demorou para responder. Verifique sua conexão.',
        Colors.redAccent,
      );
    } on SocketException {
      _mostrarSnackBar(
        '❌ Sem conexão com o servidor. Verifique sua internet.',
        Colors.redAccent,
      );
    } on http.ClientException {
      _mostrarSnackBar(
        '❌ Não foi possível se conectar ao servidor.',
        Colors.redAccent,
      );
    } on FormatException {
      _mostrarSnackBar(
        '❌ Resposta inválida do servidor. Contate o suporte.',
        Colors.redAccent,
      );
    } on _ApiException catch (e) {
      _mostrarSnackBar('❌ ${e.mensagem}', Colors.redAccent);
    } catch (_) {
      _mostrarSnackBar(
        '❌ Ocorreu um erro inesperado. Tente novamente.',
        Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  /// Autentica na API (o bcrypt valida a senha no servidor) e devolve o id.
  Future<String> _autenticar() async {
    final resposta = await http
        .post(
          Uri.parse('$_apiBaseUrl$_rotaLogin'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text.trim(),
            'senha': _senhaController.text,
          }),
        )
        .timeout(_timeout);

    final dados = _decodificarResposta(resposta);

    final statusOk = resposta.statusCode == 200 || resposta.statusCode == 201;
    if (!statusOk || dados['sucesso'] == false) {
      throw _ApiException(
        _extrairMensagem(dados, padrao: 'E-mail ou senha incorretos.'),
      );
    }

    final usuario = dados['usuario'];
    final id = usuario is Map<String, dynamic> ? usuario['id'] : null;
    if (id == null) {
      throw const FormatException('ID do usuário ausente na resposta.');
    }

    return id.toString();
  }

  /// Consulta se o usuário logado já possui filhos vinculados.
  Future<bool> _usuarioPossuiFilhos(String usuarioId) async {
    final resposta = await http
        .get(Uri.parse('$_apiBaseUrl$_rotaVinculos/$usuarioId'))
        .timeout(_timeout);

    final dados = _decodificarResposta(resposta);

    if (resposta.statusCode != 200 || dados['sucesso'] != true) {
      throw _ApiException(
        _extrairMensagem(
          dados,
          padrao: 'Não foi possível verificar os vínculos da conta.',
        ),
      );
    }

    final total = (dados['total'] as num?)?.toInt() ?? 0;
    return total > 0;
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
  String _extrairMensagem(
    Map<String, dynamic> dados, {
    required String padrao,
  }) {
    final mensagem = dados['message'];
    if (mensagem is List && mensagem.isNotEmpty) {
      return mensagem.join('\n');
    }
    if (mensagem is String && mensagem.isNotEmpty) {
      return mensagem;
    }
    return padrao;
  }

  // ---------------------------------------------------------------------------
  // Navegação e feedback
  // ---------------------------------------------------------------------------

  void _abrirDashboard(String usuarioId) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => DashboardScreen(usuarioId: usuarioId)),
      (route) => false,
    );
  }

  void _abrirCadastroDoBebe() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ChildRegisterScreen()),
      (route) => false,
    );
  }

  void _abrirCadastro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CadastroScreen()),
    );
  }

  void _abrirResetSenha() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ResetSenhaScreen()),
    );
  }

  void _mostrarSnackBar(String mensagem, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem), backgroundColor: cor));
  }

  // ---------------------------------------------------------------------------
  // Validators
  // ---------------------------------------------------------------------------

  String? _validarEmail(String? v) {
    final email = v?.trim() ?? '';
    if (email.isEmpty) return 'Insira seu e-mail de acesso';
    if (!_emailRegex.hasMatch(email)) return 'O formato do e-mail é inválido';
    return null;
  }

  String? _validarSenha(String? v) {
    if (v == null || v.isEmpty) return 'Insira sua senha';
    if (v.length < 8) return 'A senha deve conter ao menos 8 caracteres';
    return null;
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildLogo(),
              const SizedBox(height: 30),
              const Text(
                'Bem-vinda de volta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoEscuro,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Entre para acompanhar os pequenos momentos '
                  'que fazem o seu dia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 35),
              _buildFormCard(),
              const SizedBox(height: 24),
              _buildAvisoPrivacidade(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      height: 90,
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildCampoEmail(),
              const SizedBox(height: 20),
              _buildCampoSenha(),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _abrirResetSenha,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text(
                  'Esqueci minha senha',
                  style: TextStyle(
                    color: AppTheme.textoEscuro,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildBotaoEntrar(),
              const SizedBox(height: 24),
              _buildLinkCriarConta(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampoEmail() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      onFieldSubmitted: (_) => _senhaFocus.requestFocus(),
      style: const TextStyle(
        color: AppTheme.textoEscuro,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: 'E-mail',
        hintText: 'Ex: natalia@email.com',
        prefixIcon: const Icon(
          Icons.mail_outline,
          color: AppTheme.turquesaPrincipal,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      validator: _validarEmail,
    );
  }

  Widget _buildCampoSenha() {
    return TextFormField(
      controller: _senhaController,
      focusNode: _senhaFocus,
      obscureText: _senhaOculta,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      onFieldSubmitted: (_) {
        if (_formularioValido) _realizarLogin();
      },
      style: const TextStyle(color: AppTheme.textoEscuro),
      decoration: InputDecoration(
        labelText: 'Senha',
        hintText: '••••••••',
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            _senhaOculta
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.grey,
          ),
          onPressed: () => setState(() => _senhaOculta = !_senhaOculta),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      validator: _validarSenha,
    );
  }

  Widget _buildBotaoEntrar() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_formularioValido && !_carregando) ? _realizarLogin : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.turquesaPrincipal,
          foregroundColor: Colors.white,
          // Cinza quando incompleto; mantém o turquesa enquanto carrega.
          disabledBackgroundColor: _carregando
              ? AppTheme.turquesaPrincipal
              : Colors.grey.withValues(alpha: 0.2),
          disabledForegroundColor:
              _carregando ? Colors.white : Colors.grey.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
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
                    'Entrar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildLinkCriarConta() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Ainda não tem uma conta?',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        TextButton(
          onPressed: _abrirCadastro,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Criar conta',
            style: TextStyle(
              color: AppTheme.turquesaPrincipal,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvisoPrivacidade() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.turquesaPrincipal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.shield_outlined,
            color: AppTheme.turquesaPrincipal,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Seu espaço é privado, seguro e feito para cuidar '
              'com tranquilidade.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textoEscuro,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}