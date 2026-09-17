//Exemplo de Uso do bluetooth => com uso do Stream no corpo da Aplicação

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main(List<String> args) {
  runApp(MaterialApp(home: MyApp(),));
}

class MyApp extends StatefulWidget {
  const new({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  //método

  //iniciar o scaneamento do Bluetooth
  void _startScan(){
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _startScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dispositivos Bluetooth"),
      actions: [
        IconButton(onPressed: _startScan, icon: Icon(Icons.refresh))
      ],),
      body: StreamBuilder<bool>(
        stream: FlutterBluePlus.isScanning,
        initialData: false,
        builder: (context, snapshot){
          final isScanning = snapshot.data ?? false; //verifico se o resultado é null e caso null transforma em false (Coalescência Nula)
          //2º Stream: Monitor os dispositivos encontrados
          return StreamBuilder<List<ScanResult>>(
            stream: FlutterBluePlus.scanResults,
            initialData: [],
            builder: (context, snapshotResult){
              final dispositivos = snapshotResult.data ?? [];
              //montar a lista de dispositivos
              if(isScanning && dispositivos.isEmpty){
                return Center(child: CircularProgressIndicator(),);
              } else if(dispositivos.isEmpty){
                return Center(child: Text("Nenhum dispositivo foi encontrado"),);
              } else{
                return ListView.builder(
                  itemCount: dispositivos.length,
                  itemBuilder: (context, index){
                    final item = dispositivos[index];
                    final name = item.device.platformName.isNotEmpty ? item.device.platformName : "Dispositivo Genérico";
                    return ListTile(
                      title: Text(name),
                      subtitle: Text(item.device.remoteId.str),
                      trailing: Text("${item.rssi} dBm"),
                    );
                  },
                );
              }
            });
        }),
    );
  }
}