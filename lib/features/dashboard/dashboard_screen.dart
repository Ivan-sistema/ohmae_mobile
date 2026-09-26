import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../children/child_register_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _abaSelecionada = 0; // Controla a navegação da barra inferior

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F6F0),
      body: SafeArea(
        // Alterna entre a Home e a aba de Perfil de forma dinâmica e limpa
        child: _abaSelecionada == 0
            ? _construirHomePrincipal(context)
            : _abaSelecionada == 3
                ? _construirAbaPerfil(context)
                : Center(
                    child: Text(
                      'Tela em Desenvolvimento',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ),
      ),

      // 🗺️ BARRA DE NAVEGAÇÃO INFERIOR EXATAMENTE IGUAL AO SEU FIGMA
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _abaSelecionada,
          onTap: (index) => setState(() => _abaSelecionada = index),
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.turquesaPrincipal,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
      ),
    );
  }

  // 🏠 CONSTRUTOR DA TELA PRINCIPAL (Home do seu design do Figma)
  Widget _construirHomePrincipal(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com Títulos e Foto da Natália
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ohmae',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.turquesaPrincipal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Visão Geral do Dia',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textoEscuro,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sexta-feira, 25 de setembro',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
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

          // Card de Rotina de Hoje
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rotina de hoje',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textoEscuro,
                      ),
                    ),
                    Text(
                      'Tudo no ritmo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _construirLinhaRotina(
                  'Soneca',
                  '2h 10min',
                  0.6,
                  const Color(0xff5EAEA4),
                  Icons.bedtime_outlined,
                ),
                const SizedBox(height: 18),
                _construirLinhaRotina(
                  'Alimentação',
                  '5 de 6',
                  0.8,
                  const Color(0xffFCA690),
                  Icons.flatware_outlined,
                ),
                const SizedBox(height: 18),
                _construirLinhaRotina(
                  'Banho',
                  'Concluído',
                  1.0,
                  const Color(0xffFCD067),
                  Icons.bathtub_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Seção Próximos Cuidados com o Botão de mais focado em Criar Tarefa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Próximos cuidados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoEscuro,
                  letterSpacing: -0.3,
                ),
              ),
              // Botão de "+" agora focado em criar atividades e rotinas diárias
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Abertura do Módulo de Criação de Atividades diárias...',
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppTheme.turquesaPrincipal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _construirCardTarefaFigma('Separar a troca da noite', '18:30', true),
          const SizedBox(height: 12),
          _construirCardTarefaFigma(
            'Preparar a próxima mamadeira',
            '19:00',
            false,
          ),
          const SizedBox(height: 12),
          _construirCardTarefaFigma('Ler uma história', 'Antes de dormir', false),
          const SizedBox(height: 28),

          // Seção Momentos de Hoje (Grid de fotos)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Momento de hoje',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoEscuro,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Ver todos',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: NetworkImage('https://unsplash.com'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '10:42 - Soneca tranquila',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textoEscuro,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Container(
                      height: 85,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        image: const DecorationImage(
                          image: NetworkImage('https://unsplash.com'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 85,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        image: const DecorationImage(
                          image: NetworkImage('https://unsplash.com'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 👤 CONSTRUTOR DA ABA DE PERFIL (Central Administrativa de Contas e Cadastros)
  Widget _construirAbaPerfil(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Painel da Família',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textoEscuro,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gerenciamento administrativo da conta.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Card de Dados da Mãe/Gestora
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage('https://unsplash.com'),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Natália Silva',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textoEscuro,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'natalia@email.com • Gestora',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Lista de Opções Exclusivas de Administradores
          const Text(
            'Configurações do App',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),

          // Opção 1: Adicionar Filho
          _construirItemMenuPerfil(
            'Adicionar Criança',
            'Cadastrar perfil de Davi ou Esther',
            Icons.child_care,
            AppTheme.turquesaPrincipal,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChildRegisterScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Opção 2: Convidar Babá
          _construirItemMenuPerfil(
            'Convidar Cuidador',
            'Autorizar acesso de ohmae_baba ou avós',
            Icons.person_add_alt_1_outlined,
            AppTheme.coralDestaque,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Módulo de convite de babá selecionado.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Widgets auxiliares internos de renderização de componentes
  Widget _construirLinhaRotina(
    String titulo,
    String status,
    double value,
    Color cor,
    IconData icone,
  ) {
    return Row(
      children: [
        Icon(icone, color: cor.withOpacity(0.6), size: 18),
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
                      color: AppTheme.textoEscuro,
                    ),
                  ),
                  Text(
                    status,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 4,
                  backgroundColor: const Color(0xffF5F2EB),
                  valueColor: AlwaysStoppedAnimation(cor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirCardTarefaFigma(String titulo, String horario, bool concluido) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: concluido ? AppTheme.turquesaPrincipal : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: concluido
                    ? AppTheme.turquesaPrincipal
                    : Colors.grey.withOpacity(0.4),
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: concluido ? Colors.grey : AppTheme.textoEscuro,
                    decoration: concluido ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  horario,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirItemMenuPerfil(
    String titulo,
    String sub,
    IconData icone,
    Color cor,
    VoidCallback onClick,
  ) {
    return InkWell(
      onTap: onClick,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, color: cor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textoEscuro,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}