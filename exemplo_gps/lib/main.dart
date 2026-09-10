//aplicação de exemplo de código

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main(List<String> args) {
  runApp(MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const new({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String mensagem = "Localização não obtida";

  void getLocation() async{
    //Solicitar a geolocalização quando for disparado o handle
    bool enable;
    LocationPermission permission;

    enable = await Geolocator.isLocationServiceEnabled(); //verificar se o serviço de localização está habilitado

    //se não estiver habilitado, preciso pedir permissão.
    if(!enable){
      mensagem = "Serviço de localização desabilitado";
      permission = await Geolocator.requestPermission();//pedir permissão
      //se negar a permissão
      if(permission == LocationPermission.denied){
        mensagem = "Acesso de Localização não permitido pelo usuário";
      return;
      } 
    }
    
    //permissão liberada
    Position position = await Geolocator.getCurrentPosition(); //pega a posição atual do dispositivo
    mensagem = "Latitude ${position.latitude}, Longitude: ${position.longitude}";

      
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gps-Localização"),),
      body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(mensagem),
          ElevatedButton(onPressed: ()async{
            setState(() {
              getLocation();
            });
          }, child: Text("Obter Localização"))
        ],
      ),),
    );
  }
}