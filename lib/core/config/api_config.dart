import 'package:flutter/foundation.dart';

/// Configuração central da API.
///
/// A URL NÃO fica fixa no código: ela é injetada no build.
///
///   Desenvolvimento (padrão, sem flag):
///     flutter run
///
///   Homologação / produção (HTTPS obrigatório em release):
///     flutter build apk --release --dart-define=API_BASE_URL=https://api.seudominio.com
class ApiConfig {
  ApiConfig._();

  static const String _baseUrlDefinida = String.fromEnvironment('API_BASE_URL');
  static const bool _demoModeSolicitado = bool.fromEnvironment(
    'OHMAE_DEMO_MODE',
    defaultValue: false,
  );

  static const Duration timeout = Duration(seconds: 10);

  /// Credenciais de desenvolvimento local.
  /// Só funcionam quando o app estiver em modo demo e fora de release.
  static const String demoUserEmail = 'demo@ohmae.com';
  static const String demoUserPassword = 'demo12345';

  /// Modo de demonstração local, explicitamente habilitado apenas fora de release.
  static bool get demoModeEnabled => !kReleaseMode && _demoModeSolicitado;

  // Rotas do backend NestJS.
  static const String rotaLogin = '/usuarios/login';
  static const String rotaCadastro = '/usuarios';
  static const String rotaCriancas = '/criancas/cadastro';
  static const String rotaTarefasHoje = '/tarefas/hoje';
  static const String rotaTarefas = '/tarefas/concluir';
  static const String rotaRecuperarSenha = '/usuarios/recuperar-senha'; // TODO: confirme a rota no NestJS
  static const String rotaVinculos = '/vinculos/usuario';

  /// URL base resolvida para o ambiente atual.
  static String get baseUrl {
    final url = _resolverUrl();

    // Em release, senha e dados do usuário jamais podem trafegar em texto puro.
    if (kReleaseMode && !url.startsWith('https://')) {
      throw StateError(
        'Em release a API precisa usar HTTPS. '
        'Defina --dart-define=API_BASE_URL=https://...',
      );
    }

    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Monta a URI completa de uma rota.
  static Uri uri(String rota) => Uri.parse('$baseUrl$rota');

  /// Chame no `main()` para falhar logo na abertura do app (e não no
  /// primeiro login) caso a configuração de release esteja errada.
  static void validar() => baseUrl;

  static String _resolverUrl() {
    if (_baseUrlDefinida.isNotEmpty) return _baseUrlDefinida;

    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL não definida. '
        'Use --dart-define=API_BASE_URL=https://...',
      );
    }

    // Só em debug: aponta para a máquina de desenvolvimento.
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000' // emulador Android
        : 'http://localhost:3000'; // simulador iOS / desktop
  }
}