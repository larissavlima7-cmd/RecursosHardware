import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/database_helper.dart';
import '../controller/registro_controller.dart';
import '../model/registro.dart';
import 'formulario_registro.dart';

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

  Future<void> _carregarRegistros() async {
    setState(() => _carregando = true);
    try {
      final dados = await _dbHelper.getRegistros();
      setState(() {
        _registros = dados;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar registros: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _abrirMapa(double latitude, double longitude) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o Google Maps.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _excluirRegistro(int id) async {
    await _dbHelper.deleteRegistro(id);
    if (mounted) {
      Navigator.pop(context); // Fecha a modal
      _carregarRegistros();  // Atualiza a lista na tela
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro excluído com sucesso!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exibirDetalhes(Registro registro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Registro #${registro.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(registro.caminhoFoto),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Data/Hora:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
              Text(registro.datahora),
              const SizedBox(height: 8),
              
              Text('Localização (Cidade/País):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
              FutureBuilder<String>(
                future: _controller.obterEnderecoFormatado(registro.latitude, registro.longitude),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Buscando cidade e país...', style: TextStyle(color: Colors.grey, fontSize: 12));
                  }
                  return Text(snapshot.data ?? 'Não localizado', style: const TextStyle(fontWeight: FontWeight.w500));
                },
              ),
              const SizedBox(height: 8),

              Text('Coordenadas GPS:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
              Text('Lat: ${registro.latitude} | Long: ${registro.longitude}'),
              const SizedBox(height: 8),

              Text('Observação:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
              Text(registro.observacao),
              const SizedBox(height: 16),

              // BOTÃO GOOGLE MAPS
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _abrirMapa(registro.latitude, registro.longitude),
                  icon: const Icon(Icons.map, color: Colors.white),
                  label: const Text('VER NO MAPA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // BOTÃO EXCLUIR
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _excluirRegistro(registro.id!),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('EXCLUIR REGISTRO', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FECHAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirFormulario() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FormularioRegistro(),
      ),
    );

    if (resultado == true) {
      _carregarRegistros();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SENAI CheckIn — Diário de Campo'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
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
                      Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum registro encontrado.',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _registros.length,
                  itemBuilder: (context, index) {
                    final registro = _registros[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(registro.caminhoFoto),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.camera_alt, color: Colors.grey),
                            ),
                          ),
                        ),
                        title: Text(
                          registro.datahora,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              registro.observacao,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.red),
                                const SizedBox(width: 2),
                                Text(
                                  '${registro.latitude.toStringAsFixed(4)}, ${registro.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _exibirDetalhes(registro),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('NOVO REGISTRO'),
      ),
    );
  }
}