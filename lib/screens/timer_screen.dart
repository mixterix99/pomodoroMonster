import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/timer_service.dart';
import '../widgets/monster_widget.dart';
import '../data/game_data.dart'; // Importar Datos
import '../models/theme_model.dart'; // Importar Modelo

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // LÓGICA DE BURBUJAS (Igual)
  String _currentMessage = "";
  Timer? _bubbleTimer;
  bool _showBubble = false;

  final Map<int, List<String>> _messagesByLevel = {
    0: ["Concéntrate...", "Siento tu energía 🧠", "¿Listo para empezar?"],
    1: ["¡Goo goo, ga ga!", "¡Mira, estoy creciendo!", "Necesito foco 🍼"],
    2: ["Disciplina es poder.", "Un Pomodoro más.", "Excelente racha."],
  };

  @override
  void initState() {
    super.initState();
    _startBubbleCycle();
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    super.dispose();
  }

  void _startBubbleCycle() {
    _bubbleTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) return;
      final service = Provider.of<TimerService>(context, listen: false);

      bool canTalk =
          service.state == TimerState.running ||
          service.state == TimerState.initial ||
          service.state == TimerState.finished;

      if (canTalk && Random().nextBool()) {
        _showMessageForLevel(service.level);
      }
    });
  }

  void _showMessageForLevel(int level) {
    int safeLevel = level > 2 ? 2 : level;
    List<String> possibleMessages =
        _messagesByLevel[safeLevel] ?? _messagesByLevel[0]!;

    setState(() {
      _currentMessage =
          possibleMessages[Random().nextInt(possibleMessages.length)];
      _showBubble = true;
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showBubble = false);
    });
  }

  void _showCustomTimeDialog(BuildContext context) {
    // (Igual que antes, código del diálogo...)
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A40),
        title: const Text(
          "Tiempo Personalizado",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Minutos (Mínimo 5):",
              style: TextStyle(color: Colors.white70),
            ),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Ej: 45",
                hintStyle: TextStyle(color: Colors.white30),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              final String input = _controller.text;
              if (input.isNotEmpty) {
                int minutes = int.tryParse(input) ?? 0;
                if (minutes < 5) minutes = 5;
                Provider.of<TimerService>(
                  context,
                  listen: false,
                ).setDuration(minutes * 60);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text("Establecer"),
          ),
        ],
      ),
    );
  }

  // --- MENÚ DE PRUEBA RÁPIDA (DEBUG) ---
  // --- MENÚ DE PRUEBA RÁPIDA (DEBUG) ---
  void _showDebugMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E), // Fondo oscuro bonito
      isScrollControlled:
          true, // Permite que el menú sea más alto si es necesario
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "🛠️ MODO DESARROLLADOR",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Divider(color: Colors.white24),

              const SizedBox(height: 10),
              const Text(
                "Seleccionar Mascota:",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),

              // USAMOS WRAP PARA QUE QUEPAN LOS 5 BOTONES
              Wrap(
                spacing: 10, // Espacio horizontal
                runSpacing: 10, // Espacio vertical
                alignment: WrapAlignment.center,
                children: [
                  _DebugButton(
                    label: "🦕 Dino",
                    onTap: () => _equipDebugPet(context, 'classic'),
                  ),
                  _DebugButton(
                    label: "🔥 Fuego",
                    onTap: () => _equipDebugPet(context, 'inferno'),
                  ),
                  _DebugButton(
                    label: "💧 Agua",
                    onTap: () => _equipDebugPet(context, 'aqua'),
                  ),
                  _DebugButton(
                    label: "🌿 Flora",
                    onTap: () => _equipDebugPet(context, 'flora'),
                  ),
                  _DebugButton(
                    label: "🤖 Robo",
                    onTap: () => _equipDebugPet(context, 'robo'),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Text(
                "Cambiar Tema:",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _DebugButton(
                    label: "🌌 Espacio",
                    onTap: () => _equipDebugTheme(context, 'space'),
                  ),
                  _DebugButton(
                    label: "📚 Biblio",
                    onTap: () => _equipDebugTheme(context, 'library'),
                  ),
                  _DebugButton(
                    label: "🏖️ Playa",
                    onTap: () => _equipDebugTheme(context, 'beach'),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _equipDebugPet(BuildContext context, String id) {
    // Llamamos a la nueva función de "Fuerza Bruta"
    Provider.of<TimerService>(context, listen: false).debugEquipPet(id);
    Navigator.pop(context); // Cerrar menú
  }

  void _equipDebugTheme(BuildContext context, String id) {
    Provider.of<TimerService>(context, listen: false).equipTheme(id);
    Navigator.pop(context); // Cerrar menú
  }

  @override
  Widget build(BuildContext context) {
    final timerService = Provider.of<TimerService>(context);

    // --- OBTENER TEMA ACTUAL ---
    AppTheme currentTheme = GameData.getThemeById(timerService.equippedThemeId);

    final screenHeight = MediaQuery.of(context).size.height;

    // Configuración de Botones basada en el TEMA
    Color primaryColor = currentTheme.primaryColor;
    Color bgColor = currentTheme.backgroundColor;
    Color textColor = currentTheme.textColor;

    String buttonText;
    Color buttonColor;
    IconData buttonIcon;
    VoidCallback? buttonAction;

    if (timerService.state == TimerState.dead) {
      buttonText = "REVIVIR (Ver Video)";
      buttonColor = Colors.grey[800]!;
      buttonIcon = Icons.refresh;
      buttonAction = () => timerService.revivePet();
    } else if (timerService.state == TimerState.finished) {
      buttonText = "CONTINUAR";
      buttonColor = Colors.green;
      buttonIcon = Icons.arrow_upward;
      buttonAction = () => timerService.nextSession();
    } else if (timerService.state == TimerState.running) {
      buttonText = "ENFOCADO...";
      buttonColor = primaryColor.withOpacity(0.5);
      buttonIcon = Icons.timelapse;
      buttonAction = null;
    } else {
      buttonText = "COMENZAR";
      buttonColor = primaryColor;
      buttonIcon = Icons.play_arrow;
      buttonAction = () => timerService.startTimerDefault();
    }

    return Scaffold(
      backgroundColor: bgColor, // <--- COLOR DE FONDO DINÁMICO
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // BOTÓN DE DEBUG (Llave inglesa)
          IconButton(
            icon: const Icon(Icons.build, color: Colors.white54),
            onPressed: () => _showDebugMenu(context),
          ),
          // CONTADOR DE MONEDAS
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${timerService.coins}",
                      style: TextStyle(color: textColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER (Mensaje)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (timerService.state == TimerState.dead)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.dangerous,
                        color: Colors.grey,
                        size: 30,
                      ),
                    ),
                  Flexible(
                    child: Text(
                      _getMessage(timerService.state),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 2),

              // MONSTRUO
              SizedBox(
                height: screenHeight * 0.30,
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child:
                            const MonsterWidget(), // <--- Ahora carga la imagen dinámica
                      ),
                    ),
                    // Burbuja...
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutBack,
                      top: _showBubble ? -30 : 20,
                      child: AnimatedOpacity(
                        opacity: _showBubble ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _currentMessage,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // BARRA DE XP
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40.0,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: timerService.xpProgress,
                        backgroundColor: Colors.white10,
                        color: primaryColor, // <--- COLOR DINÁMICO
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Nivel ${timerService.level} (Total: ${(timerService.totalTime / 60).toStringAsFixed(1)} min)",
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // SELECTOR DE TIEMPO
              if (timerService.state == TimerState.initial)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TimeButton(
                        label: "TEST (5s)",
                        seconds: 5,
                        isSelected: timerService.maxSeconds == 5,
                        activeColor: primaryColor,
                        onTap: () => timerService.setDuration(5),
                      ),
                      const SizedBox(width: 10),
                      _TimeButton(
                        label: "Focus (25m)",
                        seconds: 25 * 60,
                        isSelected: timerService.maxSeconds == 25 * 60,
                        activeColor: primaryColor,
                        onTap: () => timerService.setDuration(25 * 60),
                      ),
                      const SizedBox(width: 10),
                      _TimeButton(
                        label: "Custom",
                        seconds: 0,
                        isSelected:
                            timerService.maxSeconds != 5 &&
                            timerService.maxSeconds != 25 * 60 &&
                            timerService.maxSeconds != 50 * 60,
                        activeColor: primaryColor,
                        onTap: () => _showCustomTimeDialog(context),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // RELOJ
              CircularPercentIndicator(
                radius: 100.0,
                lineWidth: 10.0,
                percent: timerService.progress,
                center: Text(
                  _formatTime(timerService.currentSeconds),
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                progressColor: timerService.state == TimerState.finished
                    ? Colors.greenAccent
                    : primaryColor,
                backgroundColor: Colors.white10,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animateFromLastPercent: true,
                animationDuration: 500,
              ),

              const Spacer(flex: 3),

              // BOTÓN PRINCIPAL
              Visibility(
                visible:
                    timerService.state != TimerState.hatching &&
                    timerService.state != TimerState.levelUp,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: buttonAction,
                    icon: Icon(buttonIcon),
                    label: Text(buttonText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors
                          .white, // Podrías cambiarlo a textColor si el fondo es claro
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  // Helpers de color y texto...
  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  String _getMessage(TimerState state) {
    switch (state) {
      case TimerState.initial:
        return "Elige tu tiempo";
      case TimerState.running:
        return "¡A trabajar!";
      case TimerState.paused:
        return "Pausado";
      case TimerState.hatching:
        return "¡Se está rompiendo! 🥚";
      case TimerState.levelUp:
        return "¡NIVEL SUBIDO! ✨";
      case TimerState.finished:
        return "¡Completado!";
      case TimerState.dead:
        return "Murió...";
    }
  }
}

// Botón Privado Actualizado con Color Dinámico
class _TimeButton extends StatelessWidget {
  final String label;
  final int seconds;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor; // Nuevo

  const _TimeButton({
    required this.label,
    required this.seconds,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _DebugButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DebugButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }
}
