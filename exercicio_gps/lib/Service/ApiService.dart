import 'dart:convert';
import 'package:exercicio_gps/Model/clima_model.dart';
import 'package:http/http.dart' as http;

class APIService {
  //informações da Api
  static const String _apiKey = '79849af71d72ee8afd05efbf39a042bd';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<ClimaModel?> getWeatherByLocation(double lat, double lon) async {
    //url para conseguir acessar as informações corretamente
    final url = Uri.parse('$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric');

    try {
      //requisição assincrona
      final response = await http.get(url);

      //se der certo, converte a resposta em formato String/JSON para um Map do Dart e depois retorna
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ClimaModel.fromJson(data);
      } else { //exceção para se der problema na de erro 
        throw Exception('Falha ao carregar os dados da API: ${response.statusCode}');
      }
    } catch (e) {
      //Se não mostra o erro
      print('Erro na requisição: $e');
      return null;
    }
  }
}