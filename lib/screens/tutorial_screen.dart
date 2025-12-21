import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/timer_service.dart';
import 'timer_screen.dart';

class TutorialScreen extends StatefulWidget {
  // Recibimos la elección del usuario para guardarla al final
  final String selectedPetId;
  final String selectedThemeId;

  const TutorialScreen({
    super.key,
    required this.selectedPetId,
    required this.selectedThemeId,
  });

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // DATOS DEL TUTORIAL
  final List<Map<String, dynamic>> _pages = [
    {
      "title": "La Regla de Oro",
      "desc":
          "Tu mascota se alimenta de tu concentración.\nSi sales de la app mientras el timer corre...",
      "icon": Icons.dangerous,
      "color": Colors.redAccent,
      "extra": "💀 MORIRÁ 💀",
    },
    {
      "title": "Evolución",
      "desc":
          "Empiezas con un huevo. Acumula tiempo de estudio para verlo nacer y crecer hasta ser Adulto.",
      "icon": Icons.trending_up,
      "color": Colors.greenAccent,
      "extra": "Huevo ➡ Bebé ➡ Adulto",
    },
    {
      "title": "Economía",
      "desc":
          "Ganas 1 Moneda por cada minuto de foco (mínimo 5 min). Úsalas para desbloquear nuevas especies.",
      "icon": Icons.monetization_on,
      "color": Colors.amber,
      "extra": "💰 Focus Coins",
    },
    {
      "title": "Niveles",
      "desc":
          "Tu rango de usuario sube con las horas. ¿Podrás llegar al Nivel 50 y ser un Maestro?",
      "icon": Icons.school,
      "color": Colors.blueAccent,
      "extra": "🎓 Rango Infinito",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // INDICADOR DE PÁGINA (PUNTITOS)
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  height: 10,
                  width: _currentPage == index ? 20 : 10,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.orangeAccent
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),

            // CARRUSEL
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(page["icon"], size: 100, color: page["color"]),
                        const SizedBox(height: 40),
                        Text(
                          page["title"],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          page["desc"],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: (page["color"] as Color).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: page["color"]),
                          ),
                          child: Text(
                            page["extra"],
                            style: TextStyle(
                              color: page["color"],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // BOTÓN DE ACCIÓN
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      // Siguiente página
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    } else {
                      // FINALIZAR: GUARDAR DATOS Y ENTRAR A LA APP
                      _finishOnboarding(context);
                    }
                  },
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? "¡ENTENDIDO, VAMOS!"
                        : "SIGUIENTE",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _finishOnboarding(BuildContext context) {
    final service = Provider.of<TimerService>(context, listen: false);

    // AQUÍ ES DONDE REALMENTE GUARDAMOS LA SELECCIÓN DEL USUARIO
    service.completeOnboarding(widget.selectedPetId, widget.selectedThemeId);

    // Navegar a la pantalla principal y borrar historial
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const TimerScreen()),
      (route) => false,
    );
  }
}
