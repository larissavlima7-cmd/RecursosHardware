import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../controller/database_helper.dart';
import '../controller/registro_controller.dart';
import '../model/registro.dart';

class FormularioRegistro extends StatefulWidget {
  const FormularioRegistro({super.key});

  @override
  State<FormularioRegistro> createState() => _FormularioRegistroState();
}

class _FormularioRegistroState extends State<FormularioRegistro> {
  final _formKey = GlobalKey<FormState>();
  final _observacaoController = TextEditingController();
  
  final RegistroController _hardwareController = RegistroController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AudioPlayer _audioPlayer = AudioPlayer();

  double? _latitude;
  double? _longitude;
  String? _caminhoFoto;

  bool _carregandoGPS = false;
  bool _carregandoFoto = false;
  bool _salvando = false;

  @override
  void dispose() {
    _observacaoController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Obtém as coordenadas do GPS usando o RegistroController
  Future<void> _capturarGPS() async {
    setState(() => _carregandoGPS = true);
    try {
      final posicao = await _hardwareController.obterLocalizacao();
      if (posicao != null) {
        setState(() {
          _latitude = posicao.latitude;
          _longitude = posicao.longitude;
        });
        _exibirSnackBar('Localização obtida com sucesso!', isErro: false);
      }
    } catch (e) {
      _exibirSnackBar('Erro ao obter GPS: ${e.toString()}', isErro: true);
    } finally {
      setState(() => _carregandoGPS = false);
    }
  }

  // Aciona a câmera usando o RegistroController
  Future<void> _tirarFoto() async {
    setState(() => _carregandoFoto = true);
    try {
      final caminho = await _hardwareController.capturarFoto();
      if (caminho != null) {
        setState(() {
          _caminhoFoto = caminho;
        });
        _exibirSnackBar('Foto capturada com sucesso!', isErro: false);
      }
    } catch (e) {
      _exibirSnackBar('Erro ao capturar foto: ${e.toString()}', isErro: true);
    } finally {
      setState(() => _carregandoFoto = false);
    }
  }

  // Executa um efeito sonoro de confirmação usando a API web do audioplayers
  Future<void> _tocarSomConfirmacao() async {
    try {
      await _audioPlayer.play(
        UrlSource('https://codeskulptor-demos.commondatastorage.googleapis.com/rigel/mark.m4a'),
      );
    } catch (_) {
      // Caso o dispositivo esteja sem conexão, ignora falha do som online
    }
  }

  // Valida e salva o registro no banco SQLite
  Future<void> _salvarRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    if (_caminhoFoto == null) {
      _exibirSnackBar('É obrigatório capturar uma foto antes de salvar.', isErro: true);
      return;
    }

    if (_latitude == null || _longitude == null) {
      _exibirSnackBar('É obrigatório obter a localização GPS antes de salvar.', isErro: true);
      return;
    }

    setState(() => _salvando = true);

    try {
      // Formatação simples da data/hora atual
      final agora = DateTime.now();
      final dataHoraFormatada = 
          '${agora.day.toString().padLeft(2, '0')}/${agora.month.toString().padLeft(2, '0')}/${agora.year} '
          '${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}';

      final novoRegistro = Registro(
        datahora: dataHoraFormatada,
        latitude: _latitude!,
        longitude: _longitude!,
        observacao: _observacaoController.text,
        caminhoFoto: _caminhoFoto!,
      );

      await _dbHelper.insertRegistro(novoRegistro);
      await _tocarSomConfirmacao();

      if (!mounted) return;
      _exibirSnackBar('Registro salvo com sucesso!', isErro: false);
      
      // Retorna true para a tela anterior recarregar a lista
      Navigator.pop(context, true); 
    } catch (e) {
      _exibirSnackBar('Erro ao salvar no banco: $e', isErro: true);
    } finally {
      setState(() => _salvando = false);
    }
  }

  void _exibirSnackBar(String mensagem, {required bool isErro}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isErro ? Colors.red[700] : Colors.green[700],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Registro de Ponto'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bloco 1: Preview da Foto
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: _caminhoFoto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_caminhoFoto!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Nenhuma foto capturada'),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 12),

              // Botão para Tirar Foto
              ElevatedButton.icon(
                onPressed: _carregandoFoto ? null : _tirarFoto,
                icon: _carregandoFoto
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_camera),
                label: Text(_carregandoFoto ? 'Acessando Câmera...' : 'Tirar Foto'),
              ),
              const SizedBox(height: 20),

              // Bloco 2: Localização GPS
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Coordenadas GPS:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: _carregandoGPS ? null : _capturarGPS,
                            child: _carregandoGPS
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Obter GPS'),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text(
                        _latitude != null && _longitude != null
                            ? 'Lat: ${_latitude!.toStringAsFixed(6)} | Long: ${_longitude!.toStringAsFixed(6)}'
                            : 'Clique em "Obter GPS" para capturar a localização.',
                        style: TextStyle(
                          color: _latitude != null ? Colors.black: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bloco 3: Observações
              TextFormField(
                controller: _observacaoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observação / Diário de Campo',
                  hintText: 'Descreva a atividade ou motivo da visita...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe uma observação sobre este registro.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botão Salvar
              ElevatedButton(
                onPressed: _salvando ? null : _salvarRegistro,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _salvando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'SALVAR REGISTRO',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}