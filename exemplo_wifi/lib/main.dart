//exemplo de leitura de sensor de conexão

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main(List<String> args) {
  runApp(MaterialApp(home: MyApp(),));
}

class MyApp extends StatefulWidget {
  const new({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //texto da mensagem
  String _mensagem = "Verificando...";
  
  //objeto para ouvir as mudanças de conexão
  late StreamSubscription<List<ConnectivityResult>> _wifiObserver;

  //métodos
  //método para verificar a conexão
  void _checkConnection() async{
    //criar uma variavel para receber as mudanças
    var _connectivityResult = (await Connectivity().checkConnectivity()) as ConnectivityResult;
    _updateConnectionStatus(_connectivityResult);
  }

  //método para atualizar as mudanças de conexão
  void _updateConnectionStatus(ConnectivityResult result){
    setState(() {
      switch(result){
        case ConnectivityResult.wifi:
          _mensagem = "Conectado no WIFI";
          break;
        case ConnectivityResult.mobile:
          _mensagem = "Conectado nos Dados Móveis";
          break;
        case ConnectivityResult.none:
          _mensagem = "Sem conexão com a internet";
          break;
        default:
          _mensagem = "Procurando Conexão...";
          break;
      }
    });
  }

  //inicio
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //1.CheckdaConexão
    _checkConnection();
    //2. Habilitar o Stream para ouvir a mudança de conexão
    _wifiObserver = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results){
     //pega o resultado disponivel e transmite para o update
     final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    _updateConnectionStatus(result);
    });
  }

  //limpa a memória ao sair da tela
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _wifiObserver.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Status da Conexão"),),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              //icone vai mudat de acordo com a conecxão
              _mensagem.contains("WIFI") ? Icons.wifi : 
              _mensagem.contains("Dados") ? Icons.network_cell :
              Icons.wifi_off,
              size: 80,
              color: _mensagem.contains("Sem") ? Colors.red : Colors.green,
            ),
            SizedBox(height: 10,),
            Text("Status: $_mensagem")
          ],
        ),
      )
    );
  }
}

