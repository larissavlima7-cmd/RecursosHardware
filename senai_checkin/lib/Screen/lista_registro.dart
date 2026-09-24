import 'dart:io';
import 'package:flutter/material.dart';
import '../controller/database_helper.dart';
import '../model/registro.dart';
import 'formulario_registro.dart';

class ListaRegistros extends StatefulWidget {
  const ListaRegistros({super.key});

  @override
  State<ListaRegistros> createState() => _ListaRegistrosState();
}

class _ListaRegistrosState extends State<ListaRegistros> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Registro> _registros = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarRegistros();
  }

  // Busca a lista atualizada de registros salvos no SQLite
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

  // Abre a tela de formulário e recarrega a lista se um novo registro for salvo
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

  // Exibe um modal com os detalhes completos do registro
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
                  height: 200,
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
              Text(
                'Data/Hora:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900]),
              ),
              Text(registro.datahora),
              const SizedBox(height: 8),
              Text(
                'Coordenadas GPS:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900]),
              ),
              Text('Lat: ${registro.latitude}'),
              Text('Long: ${registro.longitude}'),
              const SizedBox(height: 8),
              Text(
                'Observação:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900]),
              ),
              Text(registro.observacao),
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
                      const SizedBox(height: 8),
                      const Text(
                        'Clique no botão abaixo para adicionar.',
                        style: TextStyle(color: Colors.grey),
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