import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../controller/database_helper.dart';
import '../controller/registro_controller.dart';
import '../model/registro.dart';

//para criar os novoos registros
class FormularioRegistro extends StatefulWidget {
  const FormularioRegistro({super.key});

  @override
  State<FormularioRegistro> createState() => _FormularioRegistroState();
}

class _FormularioRegistroState extends State<FormularioRegistro> {
  final _formKey = GlobalKey<FormState>();
  final _observacaoController = TextEditingController();
  //para controle da camera,gps
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
  void initState() {
    super.initState();
    _solicitarPermissoesIniciais();
  }

  //slolicita as permissões de acesso ao dispositivo
  Future<void> _solicitarPermissoesIniciais() async {
    bool concedidas = await _hardwareController.solicitarPermissoes();
    if (!concedidas && mounted) {
      _exibirSnackBar('Atenção: É necessário conceder permissões para registrar o ponto.', isErro: true);
    }
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
// obtém as coordenadas GPS atuais 
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
//aciona a camera para tirar a foto
  Future<void> _tirarFoto() async {
    setState(() => _carregandoFoto = true);
    try {
      final caminho = await _hardwareController.capturarFoto();
      if (caminho != null) {
        setState(() => _caminhoFoto = caminho);
        _exibirSnackBar('Foto capturada com sucesso!', isErro: false);
      }
    } catch (e) {
      _exibirSnackBar('Erro ao capturar foto: ${e.toString()}', isErro: true);
    } finally {
      setState(() => _carregandoFoto = false);
    }
  }
//reproz o som de confirmação quando o registro e sallvo
  Future<void> _tocarSomConfirmacao() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/confirmacao.mp3'));
    } catch (e) {
      debugPrint('Erro ao tocar o som: $e');
    }
  }

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

    try {//formata a data e hora
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
      Navigator.pop(context, true); 
    } catch (e) {
      _exibirSnackBar('Erro ao salvar no banco: $e', isErro: true);
    } finally {
      setState(() => _salvando = false);
    }
  }
//para os avisos, que ficaram na parte inferior da pagina
  void _exibirSnackBar(String mensagem, {required bool isErro}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isErro ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Registro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Área da Foto
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: _caminhoFoto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          File(_caminhoFoto!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 55, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 10),
                            const Text(
                              'Nenhuma foto capturada',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 12),

              // Botão Câmera
              ElevatedButton.icon(
                onPressed: _carregandoFoto ? null : _tirarFoto,
                icon: _carregandoFoto
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.camera_alt),
                label: Text(_carregandoFoto ? 'Acessando Câmera...' : 'Tirar Foto'),
              ),
              const SizedBox(height: 24),

              // Card do GPS
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('GPS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: _carregandoGPS ? null : _capturarGPS,
                            icon: const Icon(Icons.my_location, size: 18),
                            label: Text(_carregandoGPS ? 'Obtendo...' : 'Capturar GPS'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                      if (_latitude != null && _longitude != null) ...[
                        const Divider(height: 20),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Lat: ${_latitude!.toStringAsFixed(5)} | Long: ${_longitude!.toStringAsFixed(5)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Campo Observação
              TextFormField(
                controller: _observacaoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observação / Diário de Campo',
                  hintText: 'Descreva a atividade realizada...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.edit_note),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe uma observação sobre este registro.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Botão Salvar
              ElevatedButton(
                onPressed: _salvando ? null : _salvarRegistro,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _salvando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'SALVAR REGISTRO',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}