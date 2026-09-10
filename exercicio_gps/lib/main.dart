import 'package:flutter/material.dart';
import 'package:exercicio_gps/Service/ApiService.dart';
import 'package:exercicio_gps/Model/clima_model.dart';

void main(List<String> args) {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //para pegar e manipular a latitude e a longitude
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();
  
  final APIService _apiService = APIService();//faz a requisição para a Api
  ClimaModel? _climaData; //armazena a informação de clima
  bool _isLoading = false;

//valida as coordenadas e busca os dados que vão ser exibidos 
  Future<void> _fetchWeather() async {
    final lat = double.tryParse(_latController.text);
    final lon = double.tryParse(_lonController.text);
    //se algum for nulo, exibe uma mensagem de erro 
    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha a latitude e a longitude com números válidos.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return; 
    }

    setState(() {
      _isLoading = true;
      _climaData = null;
    });

    final data = await _apiService.getWeatherByLocation(lat, lon);

    setState(() {
      _isLoading = false;
      if (data != null) {
        _climaData = data;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível buscar o clima. Verifique as coordenadas.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GPS-Localização & Clima")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [              
                TextField(
                  controller: _latController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _lonController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                ElevatedButton(
                  onPressed: _fetchWeather,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text(
                    'Pesquisar Clima', 
                    style: TextStyle(color: Colors.white)
                  ),
                ),
                
                const SizedBox(height: 32),
                
                if (_isLoading)
                  const CircularProgressIndicator()
                else if (_climaData != null)
                  Card(
                    elevation: 4,
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            '${_climaData!.cidade}, ${_climaData!.pais}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${_climaData!.temperatura.toStringAsFixed(1)} °C',
                            style: const TextStyle(fontSize: 48, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}