import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../children/child_register_screen.dart';

/// Erro retornado pela API (status fora de 2xx ou `sucesso: false`).
class _ApiException implements Exception {
  const _ApiException(this.mensagem);

  final String mensagem;
}

class _Crianca {
  const _Crianca({
    required this.id,
    required this.nome,
    required this.restricoes,
  });

  final String id;
  final String nome;
  final String restricoes;

  factory _Crianca.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    if (id.isEmpty) {
      throw const FormatException('Criança sem id.');
    }

    final restricoes = (json['restricoes_medicas'] as String?)?.trim() ?? '';

    return _Crianca(
      id: id,
      nome: (json['nome'] as String?)?.trim() ?? '',
      restricoes:
          restricoes.isEmpty ? 'Nenhuma restrição cadastrada.' : restricoes,
    );
  }

  String get inicial => nome.isEmpty ? '?' : nome[0].toUpperCase();
}

class _Tarefa {
  const _Tarefa({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.concluida,
  });

  final String id;
  final String titulo;
  final String categoria;
  final bool concluida;

  factory _Tarefa.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    if (id.isEmpty) {
      throw const FormatException('Tarefa sem id.');
    }

    return _Tarefa(
      id: id,
      titulo: (json['titulo'] as String?)?.trim() ?? 'Sem título',
      categoria: (json['categoria'] as String?)?.trim() ?? '',
      concluida: json['status'] == 'CONCLUIDO',
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.usuarioId,
    required this.token,
    this.demoMode = false,
  });

  /// ID real do usuário que fez login.
  final String usuarioId;
  final String token;
  final bool demoMode;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const int _abaInicio = 0;
  static const int _abaPerfil = 3;

  int _abaSelecionada = _abaInicio;
  bool _carregando = true;
  String? _erro;

  _Crianca? _crianca;
  List<_Tarefa> _tarefas = [];

  /// Id da tarefa sendo concluída (evita toques duplicados).
  String? _concluindoId;

  int get _totalConcluidas => _tarefas.where((t) => t.concluida).length;

  int get _totalPendentes => _tarefas.length - _totalConcluidas;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // ---------------------------------------------------------------------------
  // Lógica
  // ---------------------------------------------------------------------------

  /// Busca a criança vinculada e as tarefas de hoje.
  /// Com [silencioso] (pull-to-refresh) não troca a tela pelo loading.
  Future<void> _carregar({bool silencioso = false}) async {
    if (widget.demoMode) {
      if (!mounted) return;
      setState(() {
        _crianca ??= const _Crianca(
          id: 'demo-child',
          nome: 'Lia',
          restricoes: 'Nenhuma restrição cadastrada.',
        );
        if (_tarefas.isEmpty) {
          _tarefas = [
            const _Tarefa(
              id: 'demo-task-1',
              titulo: 'Café da manhã',
              categoria: 'Alimentação',
              concluida: false,
            ),
            const _Tarefa(
              id: 'demo-task-2',
              titulo: 'Soneca da manhã',
              categoria: 'Sono',
              concluida: true,
            ),
            const _Tarefa(
              id: 'demo-task-3',
              titulo: 'Passeio ao ar livre',
              categoria: 'Atividade',
              concluida: false,
            ),
          ];
        }
        _erro = null;
        _carregando = false;
      });
      return;
    }

    if (!silencioso) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final crianca = await _buscarCrianca();
      final tarefas =
          crianca == null ? <_Tarefa>[] : await _buscarTarefas(crianca.id);

      if (!mounted) return;
      setState(() {
        _crianca = crianca;
        _tarefas = tarefas;
        _erro = null;
      });
    } catch (e) {
      final mensagem = _mensagemParaErro(e);
      if (!mounted) return;

      if (silencioso) {
        // Mantém os dados já exibidos e só avisa da falha.
        _mostrarAlerta('❌ $mensagem', Colors.redAccent);
      } else {
        setState(() => _erro = mensagem);
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  /// Primeira criança vinculada ao usuário, ou null se não houver nenhuma.
  Future<_Crianca?> _buscarCrianca() async {
    final resposta = await http
        .get(
          ApiConfig.uri(ApiConfig.rotaVinculos),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        )
        .timeout(ApiConfig.timeout);

    final dados = _decodificarResposta(resposta);

    if (resposta.statusCode != 200 || dados['sucesso'] != true) {
      throw _ApiException(
        _extrairMensagem(
          dados,
          padrao: 'Não foi possível carregar os dados da família.',
        ),
      );
    }

    final lista = dados['criancas'];
    if (lista is! List || lista.isEmpty) return null;

    final primeira = lista.first;
    if (primeira is! Map<String, dynamic>) {
      throw const FormatException('Formato inesperado.');
    }

    return _Crianca.fromJson(primeira);
  }

  Future<List<_Tarefa>> _buscarTarefas(String criancaId) async {
    final resposta = await http
        .get(
          ApiConfig.uri('${ApiConfig.rotaTarefasHoje}/$criancaId'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        )
        .timeout(ApiConfig.timeout);

    final dados = _decodificarResposta(resposta);

    if (resposta.statusCode != 200 || dados['sucesso'] != true) {
      throw _ApiException(
        _extrairMensagem(
          dados,
          padrao: 'Não foi possível carregar as atividades de hoje.',
        ),
      );
    }

    final lista = dados['tarefas'];
    if (lista is! List) return [];

    return lista
        .whereType<Map<String, dynamic>>()
        .map(_Tarefa.fromJson)
        .toList();
  }

  Future<void> _concluirTarefa(_Tarefa tarefa) async {
    if (_concluindoId != null) return;

    if (widget.demoMode) {
      setState(() {
        _tarefas = _tarefas
            .map(
              (item) => item.id == tarefa.id
                  ? _Tarefa(
                      id: item.id,
                      titulo: item.titulo,
                      categoria: item.categoria,
                      concluida: true,
                    )
                  : item,
            )
            .toList();
      });
      _mostrarAlerta(
        'Concluída apenas nesta demonstração.',
        AppTheme.aquaPrincipal,
      );
      return;
    }

    setState(() => _concluindoId = tarefa.id);

    try {
      final resposta = await http
          .patch(
            ApiConfig.uri('${ApiConfig.rotaTarefas}/${tarefa.id}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
            },
            body: jsonEncode({
              'observacao_execucao': 'Concluído com sucesso via app celular.',
            }),
          )
          .timeout(ApiConfig.timeout);

      final sucesso = resposta.statusCode == 200 ||
          resposta.statusCode == 201 ||
          resposta.statusCode == 204;

      if (!sucesso) {
        throw _ApiException(
          _extrairMensagemDoCorpo(
            resposta,
            padrao: 'Não foi possível concluir a tarefa.',
          ),
        );
      }

      _mostrarAlerta('✅ Tarefa concluída!', AppTheme.aquaPrincipal);
      await _carregar(silencioso: true);
    } catch (e) {
      _mostrarAlerta('❌ ${_mensagemParaErro(e)}', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _concluindoId = null);
    }
  }

  String _mensagemParaErro(Object erro) {
    if (erro is TimeoutException) {
      return 'O servidor demorou para responder. Tente novamente.';
    }
    if (erro is SocketException || erro is http.ClientException) {
      return 'Sem conexão com o servidor. Verifique sua internet.';
    }
    if (erro is FormatException) {
      return 'Resposta inválida do servidor. Contate o suporte.';
    }
    if (erro is _ApiException) return erro.mensagem;
    return 'Ocorreu um erro inesperado. Tente novamente.';
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

  /// Versão tolerante a corpo vazio/não-JSON (ex.: respostas de erro).
  String _extrairMensagemDoCorpo(
    http.Response resposta, {
    required String padrao,
  }) {
    try {
      return _extrairMensagem(_decodificarResposta(resposta), padrao: padrao);
    } catch (_) {
      return padrao;
    }
  }

  void _mostrarAlerta(String mensagem, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem), backgroundColor: cor));
  }

  void _abrirCadastroDeCrianca() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildRegisterScreen(
          usuarioId: widget.usuarioId,
          token: widget.token,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cremeFundo,
      body: SafeArea(child: _buildCorpo()),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildCorpo() {
    switch (_abaSelecionada) {
      case _abaInicio:
        if (_carregando) return _buildLoading();
        if (_erro != null) return _buildErro(_erro!);
        return _buildHome();
      case _abaPerfil:
        return _buildAbaPerfil();
      default:
        return const Center(child: Text('Tela em desenvolvimento'));
    }
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.aquaPrincipal),
    );
  }

  Widget _buildErro(String mensagem) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Não foi possível carregar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textoPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildBotaoPrincipal(
              'Tentar novamente',
              Icons.refresh,
              () => _carregar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHome() {
    final crianca = _crianca;

    return RefreshIndicator(
      onRefresh: () => _carregar(silencioso: true),
      color: AppTheme.aquaPrincipal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: crianca == null
            ? _buildSemCrianca()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCabecalho(crianca),
                  if (widget.demoMode) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Modo demonstração: dados fictícios e alterações somente locais.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildCardRotina(crianca),
                  const SizedBox(height: 28),
                  const Text(
                    'Próximas atividades',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildListaTarefas(),
                ],
              ),
      ),
    );
  }

  Widget _buildSemCrianca() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.child_care, size: 56, color: AppTheme.aquaPrincipal),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma criança cadastrada',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cadastre o perfil da criança para acompanhar a rotina.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildBotaoPrincipal(
            'Adicionar criança',
            Icons.arrow_forward,
            _abrirCadastroDeCrianca,
          ),
        ],
      ),
    );
  }

  Widget _buildCabecalho(_Crianca crianca) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ohmae',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.aquaPrincipal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                crianca.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoPrincipal,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Acompanhe a rotina de hoje',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.aquaPrincipal.withValues(alpha: 0.15),
          child: Text(
            crianca.inicial,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.aquaPrincipal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardRotina(_Crianca crianca) {
    final total = _tarefas.length;
    final progresso = total == 0 ? 0.0 : _totalConcluidas / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.superficieCard,
        borderRadius: BorderRadius.circular(AppTheme.raioCartao),
        boxShadow: AppTheme.sombraSutil,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rotina de hoje',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoPrincipal,
                ),
              ),
              Text(
                '$_totalConcluidas/$total concluídas',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textoDeAcao,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLinhaRotina(
            titulo: 'Atenção/Saúde',
            subtitulo: crianca.restricoes,
            cor: AppTheme.aquaPrincipal,
            icone: Icons.healing_outlined,
          ),
          const SizedBox(height: 18),
          _buildLinhaRotina(
            titulo: 'Próximos Cuidados',
            subtitulo: '$_totalPendentes pendentes',
            valor: progresso,
            cor: AppTheme.coralAlerta,
            icone: Icons.assignment_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaRotina({
    required String titulo,
    required String subtitulo,
    required Color cor,
    required IconData icone,
    double? valor,
  }) {
    return Row(
      children: [
        Icon(icone, color: cor, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textoPrincipal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      subtitulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              if (valor != null) ...[
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: valor,
                  minHeight: 4,
                  backgroundColor: AppTheme.bordaInativa,
                  valueColor: AlwaysStoppedAnimation(cor),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListaTarefas() {
    if (_tarefas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            'Nenhuma atividade agendada para hoje.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tarefas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _buildItemTarefa(_tarefas[index]),
    );
  }

  Widget _buildItemTarefa(_Tarefa tarefa) {
    final concluindo = _concluindoId == tarefa.id;
    final podeConcluir = !tarefa.concluida && _concluindoId == null;

    return Material(
      color: AppTheme.superficieCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: podeConcluir ? () => _concluirTarefa(tarefa) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (concluindo)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppTheme.aquaPrincipal,
                    strokeWidth: 2.5,
                  ),
                )
              else
                Icon(
                  tarefa.concluida
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: tarefa.concluida ? AppTheme.aquaPrincipal : Colors.grey,
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarefa.titulo,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: tarefa.concluida
                            ? Colors.grey
                            : AppTheme.textoPrincipal,
                        decoration:
                            tarefa.concluida ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (tarefa.categoria.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Categoria: ${tarefa.categoria}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbaPerfil() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Painel da Família',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textoPrincipal,
            ),
          ),
          const SizedBox(height: 24),
          _buildItemMenuPerfil(
            titulo: 'Adicionar nova criança',
            subtitulo: 'Cadastrar o perfil de outra criança',
            icone: Icons.child_care,
            cor: AppTheme.aquaPrincipal,
            onTap: _abrirCadastroDeCrianca,
          ),
        ],
      ),
    );
  }

  Widget _buildItemMenuPerfil({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.superficieCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icone, color: cor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitulo,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotaoPrincipal(
    String texto,
    IconData icone,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.aquaPrincipal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.raioCampo),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              texto,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(icone, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.superficieCard,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _abaSelecionada,
        onTap: (index) => setState(() => _abaSelecionada = index),
        selectedItemColor: AppTheme.aquaPrincipal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Rotina',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            label: 'Momentos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}