class ClimaModel{
  //atributos da classe clima
  final double temperatura;
  final String cidade;
  final String pais;

//construtor
  ClimaModel({
    required this.temperatura,
    required this.cidade,
    required this.pais,
  });

//convertendo os dados da api para objeto
  factory ClimaModel.fromJson(Map<String, dynamic> json) {
    return ClimaModel(
      temperatura: json['main']['temp'].toDouble(),
      cidade: json['name'],
      pais: json['sys']['country'],
    );
  }
}