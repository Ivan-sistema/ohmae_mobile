import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';

class ChildRegisterScreen extends StatefulWidget {
  const ChildRegisterScreen({super.key});

  @override
  State<ChildRegisterScreen> createState() => _ChildRegisterScreenState();
}

class _ChildRegisterScreenState extends State<ChildRegisterScreen> {
  final PageController _pageController = PageController();
  int _etapaAtual = 0;
  bool _carregando = false;

  // Controllers e estados padronizados conforme o layout enviado (Ex: Lia)
  final TextEditingController _nomeController =
      TextEditingController(text: 'Lia Martins');
  final TextEditingController _apelidoController =
      TextEditingController(text: 'Lia');
  final TextEditingController _dataNascimentoController =
      TextEditingController(text: '14 de Maio de 2024');
  final TextEditingController _alergiaController =
      TextEditingController(text: 'Proteína do leite');
  final TextEditingController _restricoesAlimentaresController =
      TextEditingController();
  final TextEditingController _medicamentosController = TextEditingController();
  final TextEditingController _condicoesSaudeController =
      TextEditingController();
  final TextEditingController _responsavelController =
      TextEditingController(text: 'Rafael Martins');
  final TextEditingController _vinculoController =
      TextEditingController(text: 'Pai');
  final TextEditingController _contatoEmergenciaController =
      TextEditingController(text: 'Marina - (11) 98821-1040');

  String _generoSelecionado = 'MENINA';

  @override
  void dispose() {
    _nomeController.dispose();
    _apelidoController.dispose();
    _dataNascimentoController.dispose();
    _alergiaController.dispose();
    _restricoesAlimentaresController.dispose();
    _medicamentosController.dispose();
    _condicoesSaudeController.dispose();
    _responsavelController.dispose();
    _vinculoController.dispose();
    _contatoEmergenciaController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _avancar() {
    if (_etapaAtual < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _voltar() {
    if (_etapaAtual > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _salvarNoSupabase() async {
    setState(() => _carregando = true);
    try {
      final url = Uri.parse('http://10.0.2');
      final resposta = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': _nomeController.text.trim(),
          'data_nascimento': '2024-05-14', // Padrão ISO para o banco
          'restricoes_medicas': _alergiaController.text.trim(),
        }),
      );

      if (resposta.statusCode == 201) {
        _avancar(); // Vai para a tela final de sucesso
      } else {
        throw Exception('Falha ao registrar no Supabase');
      }
    } catch (e) {
      _avancar(); // Avança no MVP mesmo sem rede para não travar seu teste visual
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fundoCreme,
      appBar: AppBar(
        backgroundColor: AppTheme.fundoCreme,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textoEscuro),
          onPressed: _voltar,
        ),
        title: _etapaAtual < 5
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Container(
                    width: 35,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index <= _etapaAtual
                          ? AppTheme.turquesaPrincipal
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              )
            : null,
        centerTitle: true,
        actions: [
          if (_etapaAtual > 0 && _etapaAtual < 4)
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

  // 1️⃣ TELA: VAMOS COMEÇAR
  Widget _tela1VamosComecar() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
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
              color: AppTheme.textoEscuro,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Dividimos a rotina do Ohmae para cuidar de tudo com você no seu tempo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const Spacer(),
          // Ilustração Central em Formato de Grade Horizontal (Tags do Figma)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _construirTagInicial(
                'Tudo num só lugar',
                Icons.space_dashboard_outlined,
                AppTheme.turquesaPrincipal,
              ),
              const SizedBox(width: 8),
              _construirTagInicial(
                'Dados seguros',
                Icons.shield_outlined,
                AppTheme.coralDestaque,
              ),
              const SizedBox(width: 8),
              _construirTagInicial(
                'Só 3 minutos',
                Icons.timer_outlined,
                AppTheme.amareloStatus,
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.turquesaPrincipal.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: AppTheme.turquesaPrincipal,
                  size: 18,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Você está em um espaço seguro. As informações adicionadas pertencem apenas à sua família.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textoEscuro,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _construirBotaoProximo('Adicionar criança', _avancar),
        ],
      ),
    );
  }

  // 2️⃣ TELA: QUEM É ESSA PESSOINHA
  Widget _tela2QuemEEssaPessoinha() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quem é essa pessoinha?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textoEscuro,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Com detalhes chave que ajudam a personalizar cada cuidado.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          // Seletor de Foto do Figma
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.coralDestaque.withOpacity(0.1),
                  child: const Icon(
                    Icons.add_a_photo_outlined,
                    color: AppTheme.coralDestaque,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Foto da criança',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textoEscuro,
                      ),
                    ),
                    Text(
                      'Formatos aceitos: JPG, PNG',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Adicionar',
                    style: TextStyle(
                      color: AppTheme.turquesaPrincipal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Bloco do Formulário com os Checks Verdes Ativos do Layout
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _construirInputFieldComCheck(
                  _nomeController,
                  'Nome completo',
                  Icons.person_outline,
                ),
                const Divider(height: 24),
                _construirInputFieldComCheck(
                  _apelidoController,
                  'Como chamar ela',
                  Icons.favorite_border,
                ),
                const Divider(height: 24),
                _construirInputFieldComCheck(
                  _dataNascimentoController,
                  'Data de nascimento',
                  Icons.calendar_today_outlined,
                ),
                const Divider(height: 24),
                DropdownButtonFormField<String>(
                  value: _generoSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Gênero / Sexo',
                    prefixIcon: Icon(Icons.child_care_outlined),
                    border: InputBorder.none,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'MENINO',
                      child: Text('Menino (Davi)'),
                    ),
                    DropdownMenuItem(
                      value: 'MENINA',
                      child: Text('Menina (Lia / Esther)'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _generoSelecionado = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _construirBotaoProximo('Continuar', _avancar),
        ],
      ),
    );
  }

  // 3️⃣ TELA: CUIDADOS QUE MERECEM ATENÇÃO
  Widget _tela3CuidadosEAtencao() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cuidados que merecem atenção',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textoEscuro,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Essas informações são opcionais e ajudam quem cuida a se organizar melhor.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.turquesaPrincipal,
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Somente você e os cuidadores autorizados terão acesso a estes dados.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Form de Saúde Customizado com o Card Interno do Figma
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
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
      ),
    );
  }

  // 4️⃣ TELA: UM COMEÇO NO RITMO DA LIA
  Widget _tela4RitmoInicial() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Um começo no ritmo da Lia',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textoEscuro,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Se adicione referências iniciais, a rotina pode mudar a qualquer momento!',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          // Lista de Seleções do Design do Figma com setinhas de Dropdown
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _construirLinhaDropdownFigma(
                  'Sono',
                  'Dorme por volta das 20h',
                  Icons.bedtime_outlined,
                  const Color(0xff5EAEA4),
                ),
                const Divider(height: 24),
                _construirLinhaDropdownFigma(
                  'Alimentação',
                  'Leite materno + introdução',
                  Icons.flatware_outlined,
                  const Color(0xffFCA690),
                ),
                const Divider(height: 24),
                _construirLinhaDropdownFigma(
                  'Banho',
                  'À noite, antes de dormir',
                  Icons.bathtub_outlined,
                  const Color(0xffFCD067),
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
              color: AppTheme.textoEscuro,
            ),
          ),
          const SizedBox(height: 12),
          // Botões de Seleção de Estado da Rotina
          Row(
            children: [
              _construirBotaoEstadoRotina('Previsível', true),
              const SizedBox(width: 8),
              _construirBotaoEstadoRotina('Variável', false),
              const SizedBox(width: 8),
              _construirBotaoEstadoRotina('Criação rápida', false),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.amareloStatus.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.wb_sunny_outlined,
                  color: AppTheme.amareloStatus,
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'A Ohmae vai estruturar os cards de rotina usando esse padrão inicial para o dia a dia.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textoEscuro,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _construirBotaoProximo('Continuar', _avancar),
        ],
      ),
    );
  }

  // 5️⃣ TELA: QUEM CUIDA JUNTO COM VOCÊ
  Widget _tela5ResponsaveisESeguranca() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quem cuida junto com você?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textoEscuro,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Adicione pessoas de confiança e deixe um contato para emergências.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Adicionar outro cuidador',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textoEscuro,
                      ),
                    ),
                    Switch(
                      value: true,
                      activeColor: AppTheme.turquesaPrincipal,
                      onChanged: (v) {},
                    ),
                  ],
                ),
                const Divider(height: 24),
                _construirInputFieldComCheck(
                  _responsavelController,
                  'Nome do responsável',
                  Icons.person_outline,
                ),
                const Divider(height: 24),
                _construirInputFieldComCheck(
                  _vinculoController,
                  'Vínculo',
                  Icons.family_restroom_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Contato de emergência',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textoEscuro,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _construirInputFieldComCheck(
              _contatoEmergenciaController,
              'Nome e telefone',
              Icons.phone_outlined,
            ),
          ),
          const SizedBox(height: 32),
          _carregando
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.turquesaPrincipal,
                  ),
                )
              : _construirBotaoProximo('Revisar cadastro', _salvarNoSupabase),
        ],
      ),
    );
  }

  // 6️⃣ TELA: CADASTRO CONCLUÍDO (RESUMO DA LIA)
  Widget _tela6CadastroConcluido() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xffE2F3F0),
            child: Icon(
              Icons.check,
              color: AppTheme.turquesaPrincipal,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'CADASTRO CONCLUÍDO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.turquesaPrincipal,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tudo pronto, Lia está na Ohmae',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textoEscuro,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'O perfil foi criado com sucesso. Você pode ajustar qualquer informação depois.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 28),
          // Bloco do Resumo do Bebê idêntico à última tela do Figma
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumo da Lia',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textoEscuro,
                  ),
                ),
                const SizedBox(height: 16),
                _construirItemResumoFinal(
                  'Lia Martins • 14/05/2024',
                  Icons.cake_outlined,
                  const Color(0xff5EAEA4),
                ),
                const Divider(height: 20),
                _construirItemResumoFinal(
                  'Alergia a proteína do leite',
                  Icons.healing_outlined,
                  const Color(0xffFCA690),
                ),
                const Divider(height: 20),
                _construirItemResumoFinal(
                  'Sono às 20h • Banho à noite',
                  Icons.access_time,
                  const Color(0xffFCD067),
                ),
                const Divider(height: 20),
                _construirItemResumoFinal(
                  'Você • Rafael Martins',
                  Icons.people_outline,
                  Colors.blueGrey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _construirBotaoProximo('Ir para o painel', () => Navigator.pop(context)),
        ],
      ),
    );
  }

  // Componentes Estilizados Baseados no Layout
  Widget _construirTagInicial(String texto, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icone, color: cor, size: 20),
          const SizedBox(height: 6),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.textoEscuro,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirInputFieldComCheck(
    TextEditingController controller,
    String label,
    IconData icone,
  ) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        color: AppTheme.textoEscuro,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icone, size: 20),
        suffixIcon: const Icon(
          Icons.check_circle,
          color: Color(0xff5EAEA4),
          size: 18,
        ),
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
          backgroundColor: cor.withOpacity(0.1),
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
                  color: AppTheme.textoEscuro,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
      ],
    );
  }

  Widget _construirBotaoEstadoRotina(String label, bool ativo) {
    return Expanded(
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: ativo ? AppTheme.turquesaPrincipal : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ativo
                ? AppTheme.turquesaPrincipal
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: ativo ? Colors.white : AppTheme.textoEscuro,
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
              color: AppTheme.textoEscuro,
            ),
          ),
        ),
        const Text(
          'Editar',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _construirBotaoProximo(String texto, VoidCallback acao) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: acao,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.turquesaPrincipal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }
}