import 'package:geolocator/geolocator.dart';

class LocalizacaoService {
  // Coordenadas padrão da empresa (no caso, SENAI)
  static const double latitudeEmpresa = -22.735;
  static const double longitudeEmpresa = -47.320;
  //para considerar o raio de 100 metros 
  static const double raioMaximoMetros = 100.0;

  // vai confirmar se o GPS do celular está ativo e solicitar as permissões de localização
  Future<bool> verificarEPedirPermissoes() async {
    bool servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      return false;
    }

    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        return false;
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // vai pegar as coordenadas atuais do dispositivo
  Future<Position?> obterPosicaoAtual() async {
    try {
      final temPermissao = await verificarEPedirPermissoes();
      if (!temPermissao) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      print('Erro ao capturar GPS: $e');
      return null;
    }
  }

  // compara as coordenadas da empresa com a do dispositivo
  // e confirma se está dentro do raio de 100 metros
  double calcularDistanciaEmMetros(
    double latAtual,
    double longAtual,
    double latEmpresa,
    double longEmpresa,
  ) {
    return Geolocator.distanceBetween(
      latAtual,
      longAtual,
      latEmpresa,
      longEmpresa,
    );
  }

  // se o funcionário está dentro do raio de 100 metros, ele valida.
  //Se não ele vai falar que está fora do raio permitido e o registro não vai ser validado
  Future<Map<String, dynamic>> validarRaioPermitido({
    double latAlvo = latitudeEmpresa,
    double longAlvo = longitudeEmpresa,
    double raioMaximo = raioMaximoMetros,
  }) async {
    final posicao = await obterPosicaoAtual();

    if (posicao == null) {
      return {
        'sucesso': false,
        'mensagem': 'Ative o GPS e permita o acesso à localização para continuar.',
        'distancia': 0.0,
        'posicao': null,
      };
    }

    final distancia = calcularDistanciaEmMetros(
      posicao.latitude,
      posicao.longitude,
      latAlvo,
      longAlvo,
    );

    final estaDentroDoRaio = distancia <= raioMaximo;

    return {
      'sucesso': estaDentroDoRaio,
      'mensagem': estaDentroDoRaio
          ? 'Localização validada! Você está a ${distancia.toStringAsFixed(1)}m do local.'
          : 'Fora do raio permitido. Você está a ${distancia.toStringAsFixed(1)}m (Máximo: ${raioMaximo.toInt()}m).',
      'distancia': distancia,
      'posicao': posicao,
    };
  }
}