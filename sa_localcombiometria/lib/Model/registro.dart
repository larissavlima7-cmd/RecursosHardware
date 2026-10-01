//classe registro, vai conter as informações da classe
import 'package:cloud_firestore/cloud_firestore.dart';

class Registro {
  //atributos
  final String? id;
  final String userId;
  final DateTime dataHora;
  final double latitude;
  final double longitude;
  final bool autenticadoPorBiometria;

  Registro({this.id, required this.userId, required this.dataHora, required this.latitude, required this.longitude, this.autenticadoPorBiometria = false,});

  // vai converter o objeto para um Map pronto para ser salvo no Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'dataHora': Timestamp.fromDate(dataHora), // formato de data nativo do Firestore
      'latitude': latitude,
      'longitude': longitude,
      'autenticadoPorBiometria': autenticadoPorBiometria,
    };
  }

  // Converte os dados vindo do Firestore de volta para o objeto Registro
  factory Registro.fromMap(Map<String, dynamic> map, String docId) {
    return Registro(
      id: docId,
      userId: map['userId'] ?? '',
      dataHora: (map['dataHora'] as Timestamp).toDate(),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      autenticadoPorBiometria: map['autenticadoPorBiometria'] ?? false,
    );
  }
}