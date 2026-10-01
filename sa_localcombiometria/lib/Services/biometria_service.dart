import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometriaService {
  final LocalAuthentication _auth = LocalAuthentication();

  //verifica se o dispositivo possui hardware de biometria e se há dados cadastrados
  Future<bool> podeAutenticar() async {
    try {
      final bool podeVerificar = await _auth.canCheckBiometrics;
      final bool ehSuportado = await _auth.isDeviceSupported();
      return podeVerificar && ehSuportado;
    } catch (e) {
      print('Erro ao verificar suporte à biometria: $e');
      return false;
    }
  }

  //executa a solicitação do Reconhecimento Facial
  Future<Map<String, dynamic>> autenticarFacial() async {
    try {
      final bool disponivel = await podeAutenticar();

      if (!disponivel) {
        return {
          'sucesso': false,
          'mensagem': 'Biometria/Reconhecimento Facial não disponível ou não configurado neste aparelho.',
        };
      }

      // abre a verificação nativa do sistema (Face ID)
      final bool autenticado = await _auth.authenticate(
       localizedReason: 'Confirme sua identidade com o Reconhecimento Facial para registrar o ponto',
       biometricOnly: true,
      );
      //condição para o reconhecimento facial 
      if (autenticado) {
        return {
          'sucesso': true,
          'mensagem': 'Reconhecimento facial confirmado com sucesso!',
        };
      } else {
        return {
          'sucesso': false,
          'mensagem': 'Reconhecimento facial cancelado ou não reconhecido.',
        };
      }
      //condição, caso tiver o leitor de biometria
    } on PlatformException catch (e) {
      print('Erro de plataforma na biometria: $e');
      return {
        'sucesso': false,
        'mensagem': 'Falha no sensor de biometria: ${e.message}',
      };
    } catch (e) {
      print('Erro inesperado na biometria: $e');
      return {
        'sucesso': false,
        'mensagem': 'Erro ao processar biometria.',
      };
    }
  }
}