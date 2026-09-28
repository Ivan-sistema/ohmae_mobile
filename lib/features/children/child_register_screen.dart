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
  final _formKey = GlobalKey<FormState>();

  // Inicia com os dados padrões do Davi conforme suas diretrizes sênior
  final TextEditingController _nomeController = TextEditingController(
    text: 'Davi Ribeiro',
  );
  final TextEditingController _dataNascimentoController = TextEditingController(
    text: '2025-05-10',
  );
  final TextEditingController _restricoesController = TextEditingController(
    text: 'Alergia à proteína do leite (APLV)',
  );

  String _generoSelecionado = 'MENINO'; // MENINO ou MENINA
  bool _carregando = false;

  void _salvarCriancaNoSupabase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      final url = Uri.parse('http://10.0.2');

      final resposta = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': _nomeController.text.trim(),
          'data_nascimento': _dataNascimentoController.text.trim(),
          'restricoes_medicas': _restricoesController.text.trim(),
        }),
      );

      final dadosResposta = jsonDecode(resposta.body);

      if (resposta.statusCode == 201 || dadosResposta['sucesso'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _generoSelecionado == 'MENINO'
                  ? '👶 Perfil do Davi criado com sucesso no Ohmae!'
                  : '👶 Perfil da Esther criado com sucesso no Ohmae!',
            ),
            backgroundColor: AppTheme.turquesaPrincipal,
          ),
        );
        Navigator.pop(context); // Retorna para o painel principal
      } else {
        throw Exception(dadosResposta['message'] ?? 'Erro ao salvar bebê.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Erro ao salvar: ${e.toString().replaceAll('Exception:', '')}',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              Center(
                child: SizedBox(
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
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Adicionar Criança',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoEscuro,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cadastre o perfil para iniciar o acompanhamento diário.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _generoSelecionado,
                        decoration: InputDecoration(
                          labelText: 'Selecione:',
                          prefixIcon: const Icon(
                            Icons.child_care,
                            color: AppTheme.turquesaPrincipal,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'MENINO',
                            child: Text('Menino (Davi)'),
                          ),
                          DropdownMenuItem(
                            value: 'MENINA',
                            child: Text('Menina (Esther)'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _generoSelecionado = v!;
                            if (_generoSelecionado == 'MENINA') {
                              _nomeController.text = 'Esther Francisco';
                              _restricoesController.text =
                                  'Nenhuma restrição médica cadastrada.';
                            } else {
                              _nomeController.text = 'Davi Francisco';
                              _restricoesController.text =
                                  'Alergia à proteína do leite (APLV)';
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nomeController,
                        style: const TextStyle(
                          color: AppTheme.textoEscuro,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Nome do Bebê',
                          prefixIcon: const Icon(Icons.face_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Insira o nome da criança'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dataNascimentoController,
                        style: const TextStyle(
                          color: AppTheme.textoEscuro,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Data de Nascimento',
                          hintText: 'AAAA-MM-DD',
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Insira a data de nascimento'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _restricoesController,
                        maxLines: 2,
                        style: const TextStyle(color: AppTheme.textoEscuro),
                        decoration: InputDecoration(
                          labelText: 'Restrições Médicas / Observações',
                          alignLabelWithHint: true,
                          prefixIcon: const Icon(Icons.healing_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _carregando
                              ? null
                              : _salvarCriancaNoSupabase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.turquesaPrincipal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _carregando
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Salvar Perfil',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                        ),
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
