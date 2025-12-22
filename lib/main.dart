import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/timer_service.dart';
import 'services/ad_service.dart'; // <--- IMPORTAR
import 'screens/timer_screen.dart';
import 'screens/onboarding_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Hive.openBox('focus_data');

  // INICIALIZAR ADS
  final adService = AdService();
  await adService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerService()),
        // Proveemos el AdService para usarlo donde queramos
        Provider<AdService>.value(value: adService),
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
      title: 'Focus Monster',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // En lugar de llamar a TimerScreen directo, llamamos a un Wrapper
      home: const AuthWrapper(),
    );
  }
}

// ESTE WIDGET DECIDE A DÓNDE VAS
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el estado del servicio
    final service = Provider.of<TimerService>(context);

    if (service.isFirstTime) {
      return const OnboardingScreen(); // <--- ERES NUEVO
    } else {
      return const TimerScreen(); // <--- YA ERES VETERANO
    }
  }
}
