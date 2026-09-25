import 'package:flutter/material.dart';
import 'View/lista_registro.dart';

/// Notificador global que guarda o estado do tema (Claro ou Escuro).
/// O 'ValueNotifier' permite atualizar o ecrã automaticamente quando o valor muda.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SenaiCheckInApp());
}

/// Classe principal da aplicação que configura os temas Claro e Escuro.
class SenaiCheckInApp extends StatelessWidget {
  const SenaiCheckInApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cor vermelha principal (Vermelho SENAI)
    const primaryRed = Color(0xFFC8102E);

    // Configuração do TEMA CLARO
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Fundo suave off-white
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        brightness: Brightness.light,
        primary: primaryRed,
        secondary: const Color(0xFFFF5252),
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      // CORREÇÃO: Utilização da classe CardThemeData em vez de CardTheme
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );

    // Configuração do TEMA ESCURO
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212), // Fundo escuro
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        brightness: Brightness.dark,
        primary: const Color(0xFFFF5252), // Vermelho mais claro para destacar no fundo escuro
        secondary: primaryRed,
        surface: const Color(0xFF1E1E1E), // Cor dos cartões
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      // CORREÇÃO: Utilização da classe CardThemeData em vez de CardTheme
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5252),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );

    // O ValueListenableBuilder reconstrói o MaterialApp sempre que o tema for alterado
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode modeAtual, __) {
        return MaterialApp(
          title: 'SENAI CheckIn',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: modeAtual, // Define qual modo está ativo
          home: const ListaRegistros(),
        );
      },
    );
  }
}