import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';

/// Erro retornado pela API (status fora de 2xx).
class _ApiException implements Exception {
  const _ApiException(this.mensagem);

  final String mensagem;
}

class ChildRegisterScreen extends StatefulWidget {
  const ChildRegisterScreen({
    super.key,
    required this.usuarioId,
    required this.token,
  });

  /// Responsável logado que está cadastrando a criança.
  final String usuarioId;
  final String token;

  @override
  State<ChildRegisterScreen> createState() => _ChildRegisterScreenState();
}

class _ChildRegisterScreenState extends State<ChildRegisterScreen> {
  static const int _totalEtapas = 5; // barras de progresso (a 6ª é o final)
  static const int _etapaFinal = 5;

  final PageController _pageController = PageController();
  int _etapaAtual = 0;
  bool _carregando = false;

  // Todos os campos começam vazios: nenhum dado pessoal fixo no código.
  final _nomeController = TextEditingController();
  final _apelidoController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _alergiaController = TextEditingController();
  final _restricoesAlimentaresController = TextEditingController();
  final _medicamentosController = TextEditingController();
  final _condicoesSaudeController = TextEditingController();
  final _responsavelController = TextEditingController();
  final _vinculoController = TextEditingController();
  final _contatoEmergenciaController = TextEditingController();

  late final List<TextEditingController> _controllers = [
    _nomeController,
    _apelidoController,
    _dataNascimentoController,
    _alergiaController,
    _restricoesAlimentaresController,
    _medicamentosController,
    _condicoesSaudeController,
    _responsavelController,
    _vinculoController,
    _contatoEmergenciaController,
  ];

  DateTime? _dataNascimento;
  String _generoSelecionado = 'MENINA';
  String _estadoRotina = 'PREVISIVEL';
  bool _adicionarCuidador = false;

  /// Etapa 2 exige nome e data de nascimento para avançar.
  bool get _etapa2Valida =>
      _nomeController.text.trim().length >= 2 && _dataNascimento != null;

  /// Nome usado nos títulos: apelido, ou primeiro nome, ou texto neutro.
  String get _nomeExibicao {
    final apelido = _apelidoController.text.trim();
    if (apelido.isNotEmpty) return apelido;
    final nome = _nomeController.text.trim();
    if (nome.isNotEmpty) return nome.split(RegExp(r'\s+')).first;
    return 'seu pequeno';
  }

  @override
  void initState() {
    super.initState();
    for (final c in _controllers) {
      c.addListener(_atualizarEstado);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _atualizarEstado() => setState(() {});

  // ---------------------------------------------------------------------------
  // Navegação entre etapas
  // ---------------------------------------------------------------------------

  void _avancar() {
    if (!mounted || _etapaAtual >= _etapaFinal) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _voltar() {
    if (_carregando) return;

    if (_etapaAtual > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Se esta for a única tela da pilha, não há para onde voltar.
      Navigator.maybePop(context);
    }
  }

  void _irParaDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          usuarioId: widget.usuarioId,
          token: widget.token,
        ),
      ),
      (route) => false,
    );
  }

  // ---------------------------------------------------------------------------
  // Data de nascimento
  // ---------------------------------------------------------------------------

  String _doisDigitos(int n) => n.toString().padLeft(2, '0');

  String _formatarData(DateTime d) =>
      '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year}';

  /// Padrão ISO (yyyy-MM-dd) para o banco.
  String _dataIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_doisDigitos(d.month)}-${_doisDigitos(d.day)}';

  Future<void> _selecionarData() async {
    FocusScope.of(context).unfocus();

    final agora = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? agora,
      firstDate: DateTime(agora.year - 18),
      lastDate: agora,
      helpText: 'Data de nascimento',
    );

    if (escolhida == null || !mounted) return;

    setState(() {
      _dataNascimento = escolhida;
      _dataNascimentoController.text = _formatarData(escolhida);
    });
  }

  // ---------------------------------------------------------------------------
  // API
  // ---------------------------------------------------------------------------

  Future<void> _salvarCrianca() async {
    if (_carregando) return;

    final dataNascimento = _dataNascimento;
    if (!_etapa2Valida || dataNascimento == null) {
      _mostrarAlerta(
        'Informe o nome e a data de nascimento da criança.',
        Colors.orangeAccent,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _carregando = true);

    try {
      final resposta = await http
          .post(
            ApiConfig.uri(ApiConfig.rotaCriancas),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
            },
            body: jsonEncode({
              'nome': _nomeController.text.trim(),
              'data_nascimento': _dataIso(dataNascimento),
              'restricoes_medicas': _alergiaController.text.trim(),
            }),
          )
          .timeout(ApiConfig.timeout);

      final sucesso = resposta.statusCode == 200 || resposta.statusCode == 201;
      if (!sucesso) {
        throw _ApiException(_mensagemDeErro(resposta));
      }

      // Só avança para a tela final se o cadastro foi realmente salvo.
      _avancar();
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

  /// Extrai a mensagem de erro da API sem quebrar se o corpo for vazio/inválido.
  String _mensagemDeErro(http.Response resposta) {
    try {
      final dados = jsonDecode(resposta.body);
      if (dados is Map<String, dynamic>) {
        final mensagem = dados['message'];
        if (mensagem is List && mensagem.isNotEmpty) {
          return mensagem.join('\n');
        }
        if (mensagem is String && mensagem.isNotEmpty) {
          return mensagem;
        }
      }
    } catch (_) {
      // Corpo vazio ou não-JSON: usa a mensagem padrão abaixo.
    }
    return 'Não foi possível salvar o cadastro. Tente novamente.';
  }

  void _mostrarAlerta(String mensagem, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem), backgroundColor: cor));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final naEtapaFinal = _etapaAtual == _etapaFinal;
    // Etapas opcionais (cuidados e ritmo) podem ser puladas.
    final podePular = _etapaAtual == 2 || _etapaAtual == 3;

    return Scaffold(
      backgroundColor: AppTheme.cremeFundo,
      appBar: AppBar(
        backgroundColor: AppTheme.cremeFundo,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        // Depois de salvo, não faz sentido voltar às etapas anteriores.
        leading: naEtapaFinal
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppTheme.textoPrincipal,
                ),
                onPressed: _voltar,
              ),
        title: naEtapaFinal ? null : _buildProgresso(),
        centerTitle: true,
        actions: [
          if (podePular)
            TextButton(
              onPressed: _avancar,
              child: const Text(
                'Pular',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (p) => setState(() => _etapaAtual = p),
          children: [
            _tela1VamosComecar(),
            _tela2QuemEEssaPessoinha(),
            _tela3CuidadosEAtencao(),
            _tela4RitmoInicial(),
            _tela5ResponsaveisESeguranca(),
            _tela6CadastroConcluido(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgresso() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_totalEtapas, (index) {
        return Container(
          width: 35,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: index <= _etapaAtual
                ? AppTheme.aquaPrincipal
                : Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Etapas
  // ---------------------------------------------------------------------------

  // 1️⃣ VAMOS COMEÇAR
  Widget _tela1VamosComecar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'VAMOS COMEÇAR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Agora, vamos conhecer seu pequeno',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textoPrincipal,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Dividimos a rotina do Ohmae para cuidar de tudo com você '
            'no seu tempo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const Spacer(),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _construirTagInicial(
                'Tudo num só lugar',
                Icons.space_dashboard_outlined,
                AppTheme.aquaPrincipal,
              ),
              _construirTagInicial(
                'Dados seguros',
                Icons.shield_outlined,
                AppTheme.coralAlerta,
              ),
              _construirTagInicial(
                'Só 3 minutos',
                Icons.timer_outlined,
                AppTheme.amareloStatus,
              ),
            ],
          ),
          const Spacer(),
          _construirAviso(
            icone: Icons.lock_outline,
            cor: AppTheme.aquaPrincipal,
            texto: 'Você está em um espaço seguro. As informações adicionadas '
                'pertencem apenas à sua família.',
          ),
          const SizedBox(height: 24),
          _construirBotaoProximo('Adicionar criança', _avancar),
        ],
      ),
    );
  }

  // 2️⃣ QUEM É ESSA PESSOINHA
  Widget _tela2QuemEEssaPessoinha() {
    return _paginaRolavel(
      children: [
        _titulo('Quem é essa pessoinha?'),
        const SizedBox(height: 6),
        _subtitulo('Com detalhes chave que ajudam a personalizar cada cuidado.'),
        const SizedBox(height: 24),
        _card(
          raio: 20,
          padding: 16,
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.coralAlerta.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color: AppTheme.coralAlerta,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Foto da criança',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textoPrincipal,
                      ),
                    ),
                    Text(
                      'Formatos aceitos: JPG, PNG',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // TODO: implementar o seletor de foto (image_picker).
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Adicionar',
                  style: TextStyle(
                    color: AppTheme.aquaPrincipal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _card(
          child: Column(
            children: [
              _construirInputFieldComCheck(
                _nomeController,
                'Nome completo',
                Icons.person_outline,
                textCapitalization: TextCapitalization.words,
              ),
              const Divider(height: 24),
              _construirInputFieldComCheck(
                _apelidoController,
                'Como chamar a criança',
                Icons.favorite_border,
                textCapitalization: TextCapitalization.words,
              ),
              const Divider(height: 24),
              _construirInputFieldComCheck(
                _dataNascimentoController,
                'Data de nascimento',
                Icons.calendar_today_outlined,
                readOnly: true,
                onTap: _selecionarData,
              ),
              const Divider(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _generoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Gênero / Sexo',
                  prefixIcon: Icon(Icons.child_care_outlined),
                  border: InputBorder.none,
                ),
                items: const [
                  DropdownMenuItem(value: 'MENINO', child: Text('Menino')),
                  DropdownMenuItem(value: 'MENINA', child: Text('Menina')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _generoSelecionado = v);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _construirBotaoProximo(
          'Continuar',
          _etapa2Valida ? _avancar : null,
        ),
      ],
    );
  }

  // 3️⃣ CUIDADOS QUE MERECEM ATENÇÃO
  Widget _tela3CuidadosEAtencao() {
    return _paginaRolavel(
      children: [
        _titulo('Cuidados que merecem atenção'),
        const SizedBox(height: 6),
        _subtitulo(
          'Essas informações são opcionais e ajudam quem cuida a se '
          'organizar melhor.',
        ),
        const SizedBox(height: 20),
        _card(
          raio: 14,
          padding: 12,
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.aquaPrincipal, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Somente você e os cuidadores autorizados terão acesso '
                  'a estes dados.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informações de saúde',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              _construirInputFieldComCheck(
                _alergiaController,
                'Alergias',
                Icons.healing_outlined,
              ),
              const Divider(height: 24),
              _construirInputFieldComCheck(
                _restricoesAlimentaresController,
                'Restrições alimentares',
                Icons.flatware_outlined,
              ),
              const Divider(height: 24),
              _construirInputFieldComCheck(
                _medicamentosController,
                'Medicamentos',
                Icons.medication_outlined,
              ),
              const Divider(height: 24),
              _construirInputFieldComCheck(
                _condicoesSaudeController,
                'Condições de saúde',
                Icons.assignment_ind_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _construirBotaoProximo('Salvar e continuar', _avancar),
      ],
    );
  }

  // 4️⃣ UM COMEÇO NO RITMO DA CRIANÇA
  Widget _tela4RitmoInicial() {
    return _paginaRolavel(
      children: [
        _titulo('Um começo no ritmo de $_nomeExibicao'),
        const SizedBox(height: 6),
        _subtitulo(
          'Se adicionar referências iniciais, a rotina pode mudar a '
          'qualquer momento!',
        ),
        const SizedBox(height: 24),
        // TODO: exemplos visuais do layout; ainda não são editáveis nem salvos.
        _card(
          child: Column(
            children: [
              _construirLinhaDropdownFigma(
                'Sono',
                'Dorme por volta das 20h',
                Icons.bedtime_outlined,
                AppTheme.aquaPrincipal,
              ),
              const Divider(height: 24),
              _construirLinhaDropdownFigma(
                'Alimentação',
                'Leite materno + introdução',
                Icons.flatware_outlined,
                AppTheme.coralAlerta,
              ),
              const Divider(height: 24),
              _construirLinhaDropdownFigma(
                'Banho',
                'À noite, antes de dormir',
                Icons.bathtub_outlined,
                AppTheme.amareloStatus,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Como está a rotina hoje?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textoPrincipal,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _construirBotaoEstadoRotina('Previsível', 'PREVISIVEL'),
            const SizedBox(width: 8),
            _construirBotaoEstadoRotina('Variável', 'VARIAVEL'),
            const SizedBox(width: 8),
            _construirBotaoEstadoRotina('Criação rápida', 'RAPIDA'),
          ],
        ),
        const SizedBox(height: 20),
        _construirAviso(
          icone: Icons.wb_sunny_outlined,
          cor: AppTheme.amareloStatus,
          texto: 'A Ohmae vai estruturar os cards de rotina usando esse '
              'padrão inicial para o dia a dia.',
        ),
        const SizedBox(height: 32),
        _construirBotaoProximo('Continuar', _avancar),
      ],
    );
  }

  // 5️⃣ QUEM CUIDA JUNTO COM VOCÊ
  Widget _tela5ResponsaveisESeguranca() {
    return _paginaRolavel(
      children: [
        _titulo('Quem cuida junto com você?'),
        const SizedBox(height: 6),
        _subtitulo(
          'Adicione pessoas de confiança e deixe um contato para '
          'emergências.',
        ),
        const SizedBox(height: 24),
        _card(
          raio: 20,
          padding: 16,
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Adicionar outro cuidador',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textoPrincipal,
                      ),
                    ),
                  ),
                  Switch(
                    value: _adicionarCuidador,
                    activeTrackColor: AppTheme.aquaPrincipal,
                    onChanged: (v) => setState(() => _adicionarCuidador = v),
                  ),
                ],
              ),
              if (_adicionarCuidador) ...[
                const Divider(height: 24),
                _construirInputFieldComCheck(
                  _responsavelController,
                  'Nome do responsável',
                  Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                ),
                const Divider(height: 24),
                _construirInputFieldComCheck(
                  _vinculoController,
                  'Vínculo (ex: Avó, Babá)',
                  Icons.family_restroom_outlined,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Contato de emergência',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textoPrincipal,
          ),
        ),
        const SizedBox(height: 12),
        _card(
          raio: 16,
          padding: 16,
          child: _construirInputFieldComCheck(
            _contatoEmergenciaController,
            'Nome e telefone',
            Icons.phone_outlined,
            keyboardType: TextInputType.text,
          ),
        ),
        const SizedBox(height: 32),
        _construirBotaoProximo(
          'Concluir cadastro',
          _carregando ? null : _salvarCrianca,
          carregando: _carregando,
        ),
      ],
    );
  }

  // 6️⃣ CADASTRO CONCLUÍDO
  Widget _tela6CadastroConcluido() {
    final alergia = _alergiaController.text.trim();
    final cuidador = _responsavelController.text.trim();
    final vinculo = _vinculoController.text.trim();

    final itens = <Widget>[
      _construirItemResumoFinal(
        '${_nomeController.text.trim()} • ${_dataNascimentoController.text}',
        Icons.cake_outlined,
        AppTheme.aquaPrincipal,
      ),
      if (alergia.isNotEmpty)
        _construirItemResumoFinal(
          'Alergia: $alergia',
          Icons.healing_outlined,
          AppTheme.coralAlerta,
        ),
      if (_adicionarCuidador && cuidador.isNotEmpty)
        _construirItemResumoFinal(
          vinculo.isEmpty ? 'Cuidador: $cuidador' : '$vinculo • $cuidador',
          Icons.people_outline,
          Colors.blueGrey,
        ),
    ];

    return _paginaRolavel(
      centralizado: true,
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.aquaPrincipal.withValues(alpha: 0.15),
          child: const Icon(
            Icons.check,
            color: AppTheme.aquaPrincipal,
            size: 24,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'CADASTRO CONCLUÍDO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.aquaPrincipal,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tudo pronto, $_nomeExibicao está na Ohmae',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.textoPrincipal,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'O perfil foi criado com sucesso. Você pode ajustar qualquer '
          'informação depois.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 28),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumo de $_nomeExibicao',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoPrincipal,
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < itens.length; i++) ...[
                if (i > 0) const Divider(height: 20),
                itens[i],
              ],
            ],
          ),
        ),
        const SizedBox(height: 40),
        _construirBotaoProximo('Ir para o painel', _irParaDashboard),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Componentes reutilizáveis
  // ---------------------------------------------------------------------------

  Widget _paginaRolavel({
    required List<Widget> children,
    bool centralizado = false,
  }) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment:
            centralizado ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _titulo(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppTheme.textoPrincipal,
      ),
    );
  }

  Widget _subtitulo(String texto) {
    return Text(
      texto,
      style: const TextStyle(fontSize: 13, color: Colors.grey),
    );
  }

  Widget _card({
    required Widget child,
    double raio = 24,
    double padding = 20,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppTheme.superficieCard,
        borderRadius: BorderRadius.circular(raio),
      ),
      child: child,
    );
  }

  Widget _construirAviso({
    required IconData icone,
    required Color cor,
    required String texto,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.raioCampo),
      ),
      child: Row(
        children: [
          Icon(icone, color: cor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textoPrincipal,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTagInicial(String texto, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.superficieCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: cor, size: 20),
          const SizedBox(height: 6),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }

  /// Campo sem borda (estilo do layout). O check só aparece quando preenchido.
  Widget _construirInputFieldComCheck(
    TextEditingController controller,
    String label,
    IconData icone, {
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    final preenchido = controller.text.trim().isNotEmpty;

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: AppTheme.textoPrincipal,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icone, size: 20),
        suffixIcon: preenchido
            ? const Icon(
                Icons.check_circle,
                color: AppTheme.aquaPrincipal,
                size: 18,
              )
            : null,
        border: InputBorder.none,
      ),
    );
  }

  Widget _construirLinhaDropdownFigma(
    String titulo,
    String sub,
    IconData icone,
    Color cor,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: cor.withValues(alpha: 0.1),
          child: Icon(icone, color: cor, size: 16),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                sub,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textoPrincipal,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
      ],
    );
  }

  Widget _construirBotaoEstadoRotina(String label, String valor) {
    final ativo = _estadoRotina == valor;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _estadoRotina = valor),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ativo ? AppTheme.aquaPrincipal : AppTheme.superficieCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ativo
                  ? AppTheme.aquaPrincipal
                  : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: ativo ? Colors.white : AppTheme.textoPrincipal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirItemResumoFinal(String texto, IconData icone, Color cor) {
    return Row(
      children: [
        Icon(icone, color: cor, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textoPrincipal,
            ),
          ),
        ),
      ],
    );
  }

  /// Botão principal. `acao == null` deixa o botão desabilitado (cinza).
  Widget _construirBotaoProximo(
    String texto,
    VoidCallback? acao, {
    bool carregando = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: acao,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.aquaPrincipal,
          foregroundColor: Colors.white,
          // Cinza quando desabilitado; mantém a cor aqua enquanto carrega.
          disabledBackgroundColor: carregando
              ? AppTheme.aquaPrincipal
              : Colors.grey.withValues(alpha: 0.2),
          disabledForegroundColor:
              carregando ? Colors.white : Colors.grey.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.raioCampo),
          ),
          elevation: 0,
        ),
        child: carregando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    texto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }
}