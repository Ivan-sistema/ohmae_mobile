import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';
import '../children/child_register_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String usuarioId; // Recebe o ID real do usuário que fez login

  const DashboardScreen({super.key, required this.usuarioId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _abaSelecionada = 0;
  bool _carregando = true;
  
  // Estados preenchidos dinamicamente pelo banco de dados Supabase
  String _nomeBebe = "";
  String _restricoesBebe = "";
  String _idBebeAtivo = "";
  List<dynamic> _tarefasDeHoje = [];

  @override
  void initState() {
    super.initState();
    _carregarTudoDoBanco();
  }

  // Motor dinâmico que faz a teia de conexões HTTP reais
  Future<void> _carregarTudoDoBanco() async {
    setState(() => _carregando = true);
    try {
      // 1. Busca qual criança está vinculada a este ID de usuário logado
      final urlVinculo = Uri.parse('http://10.0.2{widget.usuarioId}');
      final respostaVinculo = await http.get(urlVinculo);
      final dadosVinculo = jsonDecode(respostaVinculo.body);

      if (dadosVinculo['sucesso'] == true && dadosVinculo['total'] > 0) {
        // Pega a primeira criança da lista vinculada
        final bebe = dadosVinculo['criancas'][0];
        _idBebeAtivo = bebe['id'];
        _nomeBebe = bebe['nome'];
        _restricoesBebe = bebe['restricoes_medicas'] ?? "Nenhuma restrição cadastrada.";

        // 2. Com o ID do bebê descoberto, busca as tarefas agendadas para HOJE
        final urlTarefas = Uri.parse('http://10.0.2');
        final respostaTarefas = await http.get(urlTarefas);
        final dadosTarefas = jsonDecode(respostaTarefas.body);

        if (dadosTarefas['sucesso'] == true) {
          _tarefasDeHoje = dadosTarefas['tarefas'];
        }
      } else {
        // Se não achar nenhuma criança, zera os estados para o app saber
        _nomeBebe = "Nenhum bebê cadastrado";
        _restricoesBebe = "Clique em Perfil para adicionar.";
        _tarefasDeHoje = [];
      }
    } catch (e) {
      _nomeBebe = "Erro de conexão";
      _restricoesBebe = "Não foi possível ler os dados da nuvem.";
    } finally {
      setState(() => _carregando = false);
    }
  }

  // Envia o Check em tempo real para o Supabase
  Future<void> _concluirTarefaNoBanco(String tarefaId) async {
    try {
      final url = Uri.parse('http://10.0.2');
      final resposta = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'observacao_execucao': 'Concluído com sucesso via app celular.',
        }),
      );

      if (resposta.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚀 Status atualizado com sucesso no Supabase!'),
            backgroundColor: AppTheme.turquesaPrincipal,
          ),
        );
        _carregarTudoDoBanco(); // Recarrega a tela com os dados atualizados
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar tarefa.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F6F0),
      body: SafeArea(
        child: _carregando
            ? const Center(child: CircularProgressIndicator(color: AppTheme.turquesaPrincipal))
            : _abaSelecionada == 0
                ? _construirHomePrincipal(context)
                : _abaSelecionada == 3
                    ? _construirAbaPerfil(context)
                    : const Center(child: Text('Tela em Desenvolvimento')),
      ),
      bottomNavigationBar: _construirBottomBar(),
    );
  }

  Widget _construirHomePrincipal(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _carregarTudoDoBanco,
      color: AppTheme.turquesaPrincipal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ohmae', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.turquesaPrincipal)),
                    const SizedBox(height: 4),
                    Text(_nomeBebe, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textoEscuro, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    const Text('Monitoramento 100% Real', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey,
                  backgroundImage: NetworkImage('https://unsplash.com'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rotina de hoje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textoEscuro)),
                      Text('Sincronizado', style: TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _construirLinhaRotina('Atenção/Saúde', _restricoesBebe, 1.0, const Color(0xff5EAEA4), Icons.healing_outlined),
                  const SizedBox(height: 18),
                  _construirLinhaRotina('Próximos Cuidados', '${_tarefasDeHoje.length} pendentes', 0.5, const Color(0xffFCA690), Icons.assignment_outlined),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text('Próximas atividades', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textoEscuro)),
            const SizedBox(height: 16),
            if (_tarefasDeHoje.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: Text('Nenhuma atividade agendada para hoje.', style: TextStyle(color: Colors.grey))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tarefasDeHoje.length,
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final tarefa = _tarefasDeHoje[index];
                  bool isConcluida = tarefa['status'] == 'CONCLUIDO';
                  return InkWell(
                    onTap: () => isConcluida ? null : _concluirTarefaNoBanco(tarefa['id']),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Icon(isConcluida ? Icons.check_circle : Icons.radio_button_unchecked, color: isConcluida ? AppTheme.turquesaPrincipal : Colors.grey),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tarefa['titulo'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isConcluida ? Colors.grey : AppTheme.textoEscuro,
                                    decoration: isConcluida ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text('Categoria: ${tarefa['categoria']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _construirAbaPerfil(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Painel da Família', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textoEscuro)),
          const SizedBox(height: 24),
          _construirItemMenuPerfil(
            'Adicionar nova Criança',
            'Cadastrar perfil de Davi, Esther ou Lia',
            Icons.child_care,
            AppTheme.turquesaPrincipal,
() => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChildRegisterScreen())),),],),);}Widget _construirBottomBar() {return Container(decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1)))),child: BottomNavigationBar(currentIndex: _abaSelecionada,onTap: (index) => setState(() => _abaSelecionada = index),selectedItemColor: AppTheme.turquesaPrincipal,unselectedItemColor: Colors.grey,type: BottomNavigationBarType.fixed,items: const [BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Início'),BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Rotina'),BottomNavigationBarItem(icon: Icon(Icons.photo_library_outlined), label: 'Momentos'),BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),],),);}Widget _construirLinhaRotina(String t, String s, double v, Color c, IconData i) {return Row(children: [Icon(i, color: c, size: 18),const SizedBox(width: 12),Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textoEscuro)), Text(s, style: const TextStyle(fontSize: 12, color: Colors.grey))],),const SizedBox(height: 6),LinearProgressIndicator(value: v, minHeight: 4, backgroundColor: const Color(0xffF5F2EB), valueColor: AlwaysStoppedAnimation(c)),],),)],);}Widget _construirItemMenuPerfil(String t, String s, IconData i, Color c, VoidCallback o) {return InkWell(onTap: o,child: Container(padding: const EdgeInsets.all(16),decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),child: Row(children: [Icon(i, color: c),const SizedBox(width: 16),Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.bold)), Text(s, style: const TextStyle(fontSize: 12, color: Colors.grey))])),const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)],),),);}}