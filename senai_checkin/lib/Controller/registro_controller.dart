import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Controller responsável pelo gerenciamento de hardware e sensores do dispositivo.
/// Manipula as permissões em tempo de execução, captura de coordenadas via GPS e captura de fotos.
class RegistroController {
  final ImagePicker _picker = ImagePicker();

  /// Solicita e verifica as permissões de Câmera e Localização em tempo de execução
  Future<bool> solicitarPermissoes() async {
    // 1. Solicita permissão de acesso à Câmera
    var statusCamera = await Permission.camera.request();

    // 2. Verifica e solicita permissão de Localização
    LocationPermission permissaoGPS = await Geolocator.checkPermission();
    if (permissaoGPS == LocationPermission.denied) {
      permissaoGPS = await Geolocator.requestPermission();
    }

    // Retorna true somente se ambas as permissões forem concedidas
    bool cameraConcedida = statusCamera.isGranted;
    bool gpsConcedido = permissaoGPS == LocationPermission.whileInUse ||
        permissaoGPS == LocationPermission.always;

    return cameraConcedida && gpsConcedido;
  }

  /// Obtém as coordenadas atuais (Latitude e Longitude) via GPS do dispositivo.
  /// Inclui verificação de serviço ativo, tratamento de erros e fallback para última posição conhecida.
  Future<Position?> obterLocalizacao() async {
    // 1. Verifica se o serviço de GPS do dispositivo está ativado
    bool servicoHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicoHabilitado) {
      throw Exception('O serviço de localização (GPS) está desativado no dispositivo.');
    }

    // 2. Valida o status da permissão de localização
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

    // 3. Tenta obter a posição atual com alta precisão e limite de tempo (Timeout)
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      // Fallback: Se o sinal de GPS falhar ou estourar o tempo limite, tenta resgatar a última posição conhecida
      Position? ultimaPosicaoConhecida = await Geolocator.getLastKnownPosition();
      if (ultimaPosicaoConhecida != null) {
        return ultimaPosicaoConhecida;
      }
      throw Exception('Não foi possível obter a localização atual. Tente novamente em um local aberto.');
    }
  }

  /// Aciona a câmera nativa do dispositivo para capturar uma foto
  /// Retorna o caminho do arquivo de imagem salvo temporariamente ou null se a captura for cancelada.
  Future<String?> capturarFoto() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Compressão leve de 80% para economizar memória e espaço em disco
      );

      if (foto != null) {
        return foto.path; // Retorna o caminho local do arquivo de imagem
      }
      return null; // Usuário cancelou a captura
    } catch (e) {
      throw Exception('Erro ao acessar a câmera: $e');
    }
  }
}