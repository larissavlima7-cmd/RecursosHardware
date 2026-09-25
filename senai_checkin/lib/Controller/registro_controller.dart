import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class RegistroController {
  final ImagePicker _picker = ImagePicker();

//vai pedir a permissão para usar a camera e a localização
  Future<bool> solicitarPermissoes() async {
    var statusCamera = await Permission.camera.request();

    LocationPermission permissaoGPS = await Geolocator.checkPermission();
    if (permissaoGPS == LocationPermission.denied) {
      permissaoGPS = await Geolocator.requestPermission();
    }

    bool cameraConcedida = statusCamera.isGranted;
    bool gpsConcedido = permissaoGPS == LocationPermission.whileInUse ||
        permissaoGPS == LocationPermission.always;

    return cameraConcedida && gpsConcedido;
  }

//para conseguir a localização da foto que foi tirada
  Future<Position?> obterLocalizacao() async {
    bool servicoHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicoHabilitado) {
      throw Exception('O serviço de localização (GPS) está desativado no dispositivo.');
    }

    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        throw Exception('A permissão de localização foi negada.');
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      throw Exception(
        'A permissão de localização foi negada permanentemente. Habilite nas configurações do aparelho.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      Position? ultimaPosicaoConhecida = await Geolocator.getLastKnownPosition();
      if (ultimaPosicaoConhecida != null) {
        return ultimaPosicaoConhecida;
      }
      throw Exception('Não foi possível obter a localização atual. Tente novamente em um local aberto.');
    }
  }

  // para encontrar a cidade e País 
  Future<String> obterEnderecoFormatado(double lat, double lng) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng');
      final response = await http.get(
        url,
        headers: {'User-Agent': 'SenaiCheckInApp'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        if (address != null) {
          String cidade = address['city'] ?? 
                          address['town'] ?? 
                          address['village'] ?? 
                          address['municipality'] ?? 
                          'Cidade desconhecida';
          String pais = address['country'] ?? 'Brasil';
          return '$cidade, $pais';
        }
      }
    } catch (e) {
      debugPrint('Erro ao obter endereço: $e');
    }
    return 'Cidade/País não localizados';
  }
//para tirar a foto
  Future<String?> capturarFoto() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (foto != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(foto.path);
        final savedImage = await File(foto.path).copy('${appDir.path}/$fileName');
        return savedImage.path;
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao acessar a câmera: $e');
    }
  }
}