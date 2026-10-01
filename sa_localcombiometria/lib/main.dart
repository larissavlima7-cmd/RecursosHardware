import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Services/auth_service.dart';
import 'View/login.dart';
import 'View/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialização obrigatória do Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return MaterialApp(
      title: 'Registro de Ponto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // O StreamBuilder redireciona automaticamente para o ecra correto
      home: StreamBuilder(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Se houver sessão ativa, vai direto para a Home
          if (snapshot.hasData) {
            return const TelaHome();
          }
          // Caso contrário, pede login
          return const TelaLogin();
        },
      ),
    );
  }
}