class Registro {
  //atributos da classe Registro(as informações de Registro)
  int? id;
  String datahora;
  double latitude;
  double longitude;
  String observacao;
  String caminhoFoto;

//construtor
  Registro({this.id, required this.datahora, required this.latitude, required this.longitude, required this.observacao, required this.caminhoFoto});

  Map<String, dynamic> toMap(){
    return{
      'id': id,
      'data_hora': datahora,
      'latitude': latitude,
      'longitude': longitude,
      'observacao': observacao,
      'caminho_foto': caminhoFoto,
    };
  }

  factory Registro.fromMap(Map<String, dynamic> map){
    return Registro(
      id: map['id'],
      datahora: map['data_hora'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      observacao: map['observacao'],
      caminhoFoto: map['caminho_foto'],
    );
  }
}