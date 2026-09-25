import 'dart:io';
import 'package:flutter/material.dart';
import '../controller/database_helper.dart';
import '../controller/registro_controller.dart';
import '../model/registro.dart';
import '../main.dart'; // Importante para acessar o themeNotifier
import 'formulario_registro.dart';

// para exibir a lista de registro
class ListaRegistros extends StatefulWidget {
  const ListaRegistros({super.key});

  @override
  State<ListaRegistros> createState() => _ListaRegistrosState();
}

class _ListaRegistrosState extends State<ListaRegistros> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final RegistroController _controller = RegistroController();
  List<Registro> _registros = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarRegistros();
  }
//consulta o bd para ter a lista de registros
  Future<void> _carregarRegistros() async {
    setState(() => _carregando = true);
    try {
      final dados = await _dbHelper.getRegistros();
      setState(() => _registros = dados);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar registros: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

//para excluir o registro
  Future<void> _excluirRegistro(int id) async {
    await _dbHelper.deleteRegistro(id);
    if (mounted) {
      _carregarRegistros();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registro excluído com sucesso!'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _exibirDetalhes(Registro registro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.assignment_turned_in, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text('Registro #${registro.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imagem salva
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(registro.caminhoFoto),
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey[800],
                    child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _construirLinhaDetalhe(Icons.access_time_filled, 'Data e Hora', registro.datahora),
              const SizedBox(height: 10),

              FutureBuilder<String>(
                future: _controller.obterEnderecoFormatado(registro.latitude, registro.longitude),
                builder: (context, snapshot) {
                  final local = snapshot.connectionState == ConnectionState.waiting
                      ? 'Buscando localização...'
                      : (snapshot.data ?? 'Não localizado');
                  return _construirLinhaDetalhe(Icons.location_on, 'Cidade / País', local);
                },
              ),
              const SizedBox(height: 10),

              _construirLinhaDetalhe(Icons.my_location, 'Coordenadas', 'Lat: ${registro.latitude} | Long: ${registro.longitude}'),
              const SizedBox(height: 10),

              _construirLinhaDetalhe(Icons.notes, 'Observação', registro.observacao),
              const SizedBox(height: 20),

                SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _excluirRegistro(registro.id!);
                  },
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  label: const Text('EXCLUIR REGISTRO', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FECHAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _construirLinhaDetalhe(IconData icone, String titulo, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(valor, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _abrirFormulario() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormularioRegistro()),
    );
    if (resultado == true) _carregarRegistros();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SENAI CheckIn'),
        actions: [
          // Botão para alternar entre Modo Claro e Escuro
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? 'Modo Claro' : 'Modo Escuro',
            onPressed: () {
              themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarRegistros,
            tooltip: 'Atualizar Lista',
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _registros.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.assignment_outlined, size: 70, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhum registro cadastrado',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Toque no botão abaixo para criar o primeiro.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: _registros.length,
                  itemBuilder: (context, index) {
                    final registro = _registros[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _exibirDetalhes(registro),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(registro.caminhoFoto),
                                    width: 75,
                                    height: 75,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 75,
                                      height: 75,
                                      color: Colors.grey[800],
                                      child: const Icon(Icons.camera_alt, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Tag Data/Hora
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          registro.datahora,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      Text(
                                        registro.observacao,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),

                                      // Endereço
                                      FutureBuilder<String>(
                                        future: _controller.obterEnderecoFormatado(registro.latitude, registro.longitude),
                                        builder: (context, snapshot) {
                                          final local = snapshot.data ?? 'Localizando...';
                                          return Row(
                                            children: [
                                              const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                                              const SizedBox(width: 2),
                                              Expanded(
                                                child: Text(
                                                  local,
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => _excluirRegistro(registro.id!),
                                  tooltip: 'Excluir',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('NOVO REGISTRO', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}