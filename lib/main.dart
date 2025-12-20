import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart'; // <--- IMPORTAR
import 'screens/timer_screen.dart';
import 'services/timer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. INICIALIZAR HIVE
  await Hive.initFlutter();

  // 2. ABRIR LA CAJA (Nuestra tabla de base de datos)
  await Hive.openBox('focus_data');

  runApp(
    MultiProvider(
      providers: [
        // Ahora TimerService cargará datos al iniciarse
        ChangeNotifierProvider(create: (_) => TimerService()),
      ],
      child: const FocusMonsterApp(),
    ),
  );
}

class FocusMonsterApp extends StatelessWidget {
  const FocusMonsterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusMonster',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        // Fuente pixelada recomendada para el futuro: 'PressStart2P'
      ),
      home: const TimerScreen(),
    );
  }
}
