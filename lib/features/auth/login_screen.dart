import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../children/child_register_screen.dart';
import '../dashboard/dashboard_screen.dart';
import 'cadastro_screen.dart';
import 'reset_senha_screen.dart';

class _ApiException implements Exception {
  const _ApiException(this.mensagem);

  final String mensagem;
}

class _Sessao {
  const _Sessao({required this.usuarioId, required this.token});

  final String usuarioId;
  final String token;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _senhaFocus = FocusNode();

  bool _senhaOculta = true;
  bool _carregando = false;

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

  void _atualizarEstado() {
    setState(() {});
  }

  Future<void> _realizarLogin() async {
    if (_carregando) return;

    FocusScope.of(context).unfocus();
    if (!_formularioValido || !_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (ApiConfig.demoModeEnabled &&
        email.toLowerCase() == ApiConfig.demoUserEmail &&
        senha == ApiConfig.demoUserPassword) {
      _entrarEmDemonstracao();
      return;
    }

    setState(() => _carregando = true);

    try {
      final sessao = await _autenticar();
      final possuiFilhos = await _usuarioPossuiFilhos(sessao.token);

      if (!mounted) return;

      if (possuiFilhos) {
        _abrirDashboard(sessao);
      } else {
        _abrirCadastroDoBebe(sessao);
      }
    } on TimeoutException {
      _mostrarSnackBar(
        'O servidor demorou para responder. Verifique sua conexão.',
        Colors.redAccent,
      );
    } on SocketException {
      _mostrarSnackBar(
        'Sem conexão com o servidor. Verifique sua internet.',
        Colors.redAccent,
      );
    } on http.ClientException {
      _mostrarSnackBar(
        'Não foi possível se conectar ao servidor.',
        Colors.redAccent,
      );
    } on FormatException {
      _mostrarSnackBar(
        'Resposta inválida do servidor. Contate o suporte.',
        Colors.redAccent,
      );
    } on _ApiException catch (error) {
      _mostrarSnackBar(error.mensagem, Colors.redAccent);
    } catch (_) {
      _mostrarSnackBar(
        'Ocorreu um erro inesperado. Tente novamente.',
        Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<_Sessao> _autenticar() async {
    final resposta = await http
        .post(
          ApiConfig.uri(ApiConfig.rotaLogin),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text.trim(),
            'senha': _senhaController.text,
          }),
        )
        .timeout(ApiConfig.timeout);

    final dados = _decodificarResposta(resposta);
    final statusOk = resposta.statusCode == 200 || resposta.statusCode == 201;

    if (!statusOk || dados['sucesso'] == false) {
      throw _ApiException(
        _extrairMensagem(dados, padrao: 'E-mail ou senha incorretos.'),
      );
    }

    final usuario = dados['usuario'];
    final id = usuario is Map<String, dynamic> ? usuario['id'] : null;
    final token = dados['token'];
    if (id == null || token is! String || token.isEmpty) {
      throw const FormatException('Dados de autenticação ausentes na resposta.');
    }

    return _Sessao(usuarioId: id.toString(), token: token);
  }

  Future<bool> _usuarioPossuiFilhos(String token) async {
    final resposta = await http
        .get(
          ApiConfig.uri(ApiConfig.rotaVinculos),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(ApiConfig.timeout);

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

  String _extrairMensagem(
    Map<String, dynamic> dados, {
    required String padrao,
  }) {
    final mensagem = dados['message'];
    if (mensagem is List && mensagem.isNotEmpty) {
      return mensagem.join('\n');
    }
    if (mensagem is String && mensagem.isNotEmpty) return mensagem;
    return padrao;
  }

  void _abrirDashboard(_Sessao sessao) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          usuarioId: sessao.usuarioId,
          token: sessao.token,
        ),
      ),
      (route) => false,
    );
  }

  void _entrarEmDemonstracao() {
    if (!ApiConfig.demoModeEnabled) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(
          usuarioId: 'demo-user',
          token: '',
          demoMode: true,
        ),
      ),
      (route) => false,
    );
  }

  void _abrirCadastroDoBebe(_Sessao sessao) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => ChildRegisterScreen(
          usuarioId: sessao.usuarioId,
          token: sessao.token,
        ),
      ),
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

  String? _validarEmail(String? valor) {
    final email = valor?.trim() ?? '';
    if (email.isEmpty) return 'Insira seu e-mail de acesso';
    if (!_emailRegex.hasMatch(email)) return 'O formato do e-mail é inválido';
    return null;
  }

  String? _validarSenha(String? valor) {
    if (valor == null || valor.isEmpty) return 'Insira sua senha';
    if (valor.length < 8) return 'A senha deve conter ao menos 8 caracteres';
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                SizedBox(
                  height: 90,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.aquaPrincipal,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ohmae',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textoPrincipal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Bem-vinda de volta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textoPrincipal,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Entre para acompanhar os pequenos momentos que fazem o seu dia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 35),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.superficieCard,
                    borderRadius: BorderRadius.circular(AppTheme.raioCartao),
                    boxShadow: AppTheme.sombraSutil,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CustomTextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        label: 'E-mail',
                        hintText: 'Ex: natalia@email.com',
                        prefixIcon: Icons.mail_outline,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        onFieldSubmitted: (_) => _senhaFocus.requestFocus(),
                        validator: _validarEmail,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _senhaController,
                        focusNode: _senhaFocus,
                        obscureText: _senhaOculta,
                        label: 'Senha',
                        hintText: 'Mínimo de 8 caracteres',
                        prefixIcon: Icons.lock_outline,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) {
                          if (_formularioValido) _realizarLogin();
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _senhaOculta
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _senhaOculta = !_senhaOculta);
                          },
                        ),
                        validator: _validarSenha,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _abrirResetSenha,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text(
                          'Esqueci minha senha',
                          style: TextStyle(
                            color: AppTheme.textoPrincipal,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        texto: 'Entrar',
                        carregando: _carregando,
                        iconeAcao: Icons.arrow_forward,
                        onPressed:
                            _formularioValido ? _realizarLogin : null,
                      ),
                      if (ApiConfig.demoModeEnabled) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.amareloStatus.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Demo: ${ApiConfig.demoUserEmail} / ${ApiConfig.demoUserPassword}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textoPrincipal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _entrarEmDemonstracao,
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Entrar em modo demonstração'),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Dados fictícios; nenhuma informação será enviada ao servidor.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Ainda não tem uma conta? ',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: _abrirCadastro,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Criar conta',
                                style: TextStyle(
                                  color: AppTheme.aquaPrincipal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.aquaPrincipal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: AppTheme.aquaPrincipal,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Seu espaço é privado, seguro e feito para cuidar com tranquilidade.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textoPrincipal,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
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
