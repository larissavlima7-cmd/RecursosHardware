import 'package:flutter/material.dart';
import '../Model/registro.dart';
import '../Services/auth_service.dart';
import '../Services/biometria_service.dart';
import '../Services/localizacao_service.dart';
import 'login.dart';

class TelaHome extends StatefulWidget {
  const TelaHome({super.key});

  @override
  State<TelaHome> createState() => _TelaHomeState();
}

class _TelaHomeState extends State<TelaHome> {
  final AuthService _authService = AuthService();
  final LocalizacaoService _localizacaoService = LocalizacaoService();
  final BiometriaService _biometriaService = BiometriaService();

  bool _carregando = false;
  String _statusMensagem = 'Pressione o botão para registrar o ponto.';

  void _mostrarMensagem(String mensagem, {bool ehErro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: ehErro ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  //fluxo da batida de ponto: GPS (100m) -> Biometria Facial -> Firestore
  Future<void> _baterPonto() async {
    final usuario = _authService.usuarioAtual;
    if (usuario == null) {
      _mostrarMensagem('Sessão expirada. Faça login novamente.', ehErro: true);
      _deslogar();
      return;
    }

    setState(() {
      _carregando = true;
      _statusMensagem = '1/3 Validando sua localização (GPS)...';
    });

    // primeiro ele valida a Geolocalização (Raio de 100m)
    final resLocalizacao = await _localizacaoService.validarRaioPermitido();

    if (resLocalizacao['sucesso'] != true) {
      setState(() {
        _carregando = false;
        _statusMensagem = resLocalizacao['mensagem'];
      });
      _mostrarMensagem(resLocalizacao['mensagem'], ehErro: true);
      return;
    }

    setState(() {
      _statusMensagem = '2/3 Solicitando Reconhecimento Facial...';
    });

    // depois ele valida por reconhecimento Facial
    final resBiometria = await _biometriaService.autenticarFacial();

    if (resBiometria['sucesso'] != true) {
      setState(() {
        _carregando = false;
        _statusMensagem = resBiometria['mensagem'];
      });
      _mostrarMensagem(resBiometria['mensagem'], ehErro: true);
      return;
    }

    setState(() {
      _statusMensagem = '3/3 Gravando ponto no banco de dados...';
    });

    // e então ele cria o Registro no Cloud Firestore
    final posicao = resLocalizacao['posicao'];
    final novoRegistro = Registro(
      userId: usuario.uid,
      dataHora: DateTime.now(),
      latitude: posicao.latitude,
      longitude: posicao.longitude,
      autenticadoPorBiometria: true,
    );

    final resBanco = await _authService.registrarPonto(novoRegistro);

    setState(() {
      _carregando = false;
      _statusMensagem = resBanco['sucesso']
          ? 'Ponto registrado com sucesso!'
          : resBanco['mensagem'];
    });

    if (resBanco['sucesso'] == true) {
      _mostrarMensagem('Ponto registrado com sucesso!');
    } else {
      _mostrarMensagem(resBanco['mensagem'], ehErro: true);
    }
  }
//usario sai e vai ser direcionado para a tela de login
  Future<void> _deslogar() async {
    await _authService.deslogar();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TelaLogin()),
    );
  }
//padronizar a data e o horário
  String _formatarDataHora(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year;
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    final segundo = data.second.toString().padLeft(2, '0');
    return '$dia/$mes/$ano às $hora:$minuto:$segundo';
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _authService.usuarioAtual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ponto'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _deslogar,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Informativo do Usuário
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Usuário Logado:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              usuario?.email ?? 'Não identificado',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Botão Principal de Registro de Ponto
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _carregando ? null : _baterPonto,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _carregando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.touch_app, size: 28),
                        label: Text(
                          _carregando ? 'PROCESSANDO...' : 'BATER PONTO',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _statusMensagem,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Histórico em Tempo Real via StreamBuilder
              Text(
                'Histórico de Registros',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: StreamBuilder<List<Registro>>(
                  stream: _authService.buscarHistoricoPontos(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erro ao carregar histórico: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final lista = snapshot.data ?? [];

                    if (lista.isEmpty) {
                      return const Center(
                        child: Text(
                          'Nenhum ponto registrado até o momento.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: lista.length,
                      itemBuilder: (context, index) {
                        final registro = lista[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              Icons.check_circle_outline,
                              color: Colors.green.shade600,
                            ),
                            title: Text(
                              _formatarDataHora(registro.dataHora),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'Lat: ${registro.latitude.toStringAsFixed(4)}, Long: ${registro.longitude.toStringAsFixed(4)}\n'
                              'Reconhecimento Facial: ${registro.autenticadoPorBiometria ? "Sim" : "Não"}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}