import 'dart:async';
import 'dart:math';
import 'dart:ui'; // Necesario para ImageFilter (Blur)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';

// Imports de tus servicios y modelos
import '../services/timer_service.dart';
import '../services/ad_service.dart'; // <--- Servicio de Anuncios
import '../widgets/monster_widget.dart';
import '../data/game_data.dart';
import '../models/theme_model.dart';
import 'shop_screen.dart'; // <--- Pantalla de Tienda

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // LÓGICA DE BURBUJAS DE TEXTO
  String _currentMessage = "";
  Timer? _bubbleTimer;
  bool _showBubble = false;

  // Lógica para no repetir el anuncio múltiples veces en el mismo "finished"
  bool _hasShownAdForThisSession = false;

  // Mensajes según la etapa de evolución de la mascota (0: Huevo, 1: Bebé, 2: Adulto)
  final Map<int, List<String>> _messagesByStage = {
    0: [
      "Concéntrate...",
      "Siento tu energía 🧠",
      "¿Listo para empezar?",
      "Zzz...",
    ],
    1: [
      "¡Goo goo, ga ga!",
      "¡Mira, estoy creciendo!",
      "Necesito foco 🍼",
      "¡Tú puedes!",
    ],
    2: [
      "Disciplina es poder.",
      "Un Pomodoro más.",
      "Excelente racha.",
      "Modo Bestia activado.",
    ],
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

  // Ciclo para que la mascota "hable" aleatoriamente
  void _startBubbleCycle() {
    _bubbleTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) return;
      final service = Provider.of<TimerService>(context, listen: false);

      // Solo habla si está viva y no está en medio de una animación crítica
      bool canTalk =
          service.state == TimerState.running ||
          service.state == TimerState.initial ||
          service.state == TimerState.finished;

      if (canTalk && Random().nextBool()) {
        _showMessageForStage(service.evolutionStage);
      }
    });
  }

  void _showMessageForStage(int stage) {
    int safeStage = stage > 2 ? 2 : stage;
    List<String> possibleMessages =
        _messagesByStage[safeStage] ?? _messagesByStage[0]!;

    setState(() {
      _currentMessage =
          possibleMessages[Random().nextInt(possibleMessages.length)];
      _showBubble = true;
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showBubble = false);
    });
  }

  // Diálogo para tiempo personalizado
  void _showCustomTimeDialog(BuildContext context) {
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
              "Ingresa los minutos (Mínimo 5):",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Ej: 45",
                hintStyle: TextStyle(color: Colors.white30),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orangeAccent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
            ),
            onPressed: () {
              final String input = _controller.text;
              if (input.isNotEmpty) {
                int minutes = int.tryParse(input) ?? 0;
                // Validación de mínimo 5 minutos
                if (minutes < 5) {
                  minutes = 5;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("⚠️ El tiempo mínimo es 5 minutos."),
                    ),
                  );
                }
                Provider.of<TimerService>(
                  context,
                  listen: false,
                ).setDuration(minutes * 60);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text(
              "Establecer",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerService = Provider.of<TimerService>(context);
    final adService = Provider.of<AdService>(context, listen: false);

    // 1. OBTENER TEMA ACTUAL
    AppTheme currentTheme = GameData.getThemeById(timerService.equippedThemeId);
    Color primaryColor = currentTheme.primaryColor;
    Color textColor = currentTheme.textColor;
    final screenHeight = MediaQuery.of(context).size.height;

    // 2. LÓGICA DE ANUNCIOS (INTERSTICIAL AL TERMINAR)
    if (timerService.state == TimerState.finished &&
        !_hasShownAdForThisSession) {
      // Pequeño delay para dejar ver la celebración primero
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) adService.showInterstitial();
      });
      _hasShownAdForThisSession = true; // Evitar loop
    }
    // Resetear flag cuando inicia uno nuevo
    if (timerService.state == TimerState.running) {
      _hasShownAdForThisSession = false;
    }

    // 3. CONFIGURACIÓN DEL BOTÓN PRINCIPAL
    String buttonText;
    Color buttonColor;
    IconData buttonIcon;
    VoidCallback? buttonAction;

    if (timerService.state == TimerState.dead) {
      buttonText = "REVIVIR (Castigo)";
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
      extendBodyBehindAppBar: true, // Permite que el fondo llegue hasta arriba
      backgroundColor: currentTheme.backgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // BOTÓN DE MUTE (Izquierda)
        leading: IconButton(
          icon: Icon(
            timerService.isMuted ? Icons.volume_off : Icons.volume_up,
            color: textColor.withOpacity(0.8),
          ),
          onPressed: () => timerService.toggleMute(),
        ),
        actions: [
          // BOTÓN DE TIENDA 🛒 (Derecha)
          IconButton(
            icon: Icon(
              Icons.store,
              color: textColor.withOpacity(0.9),
              size: 28,
            ),
            tooltip: "Tienda",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShopScreen()),
              );
            },
          ),

          // CONTADOR DE MONEDAS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "${timerService.coins}",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,

      body: Stack(
        children: [
          // CAPA 1: IMAGEN DE FONDO
          if (currentTheme.backgroundAsset != null)
            Positioned.fill(
              child: Image.asset(
                currentTheme.backgroundAsset!,
                fit: BoxFit.cover,
              ),
            ),

          // CAPA 2: DESENFOQUE Y OSCURECIMIENTO
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Blur suave
              child: Container(
                color: currentTheme.backgroundColor.withOpacity(
                  0.7,
                ), // Overlay oscuro
              ),
            ),
          ),

          // CAPA 3: CONTENIDO UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Column(
                children: [
                  // HEADER: Mensaje de Estado
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

                  // Espacio ajustable (Separación Título - Monstruo)
                  const Spacer(flex: 4),

                  // MONSTRUO + BURBUJA
                  SizedBox(
                    height: screenHeight * 0.30,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.center,
                            child: const MonsterWidget(),
                          ),
                        ),
                        // Burbuja de texto animada
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutBack,
                          // Posición ajustada para que no tape al monstruo
                          top: _showBubble ? -5 : 20,
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

                  // BARRA DE XP Y TÍTULO DE USUARIO
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40.0,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Nivel ${timerService.userLevel}",
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              timerService.userTitle.toUpperCase(),
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: timerService.xpProgress,
                            backgroundColor: Colors.white10,
                            color: primaryColor,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Total Focus: ${(timerService.totalTime / 60).toStringAsFixed(1)} min",
                          style: TextStyle(
                            color: textColor.withOpacity(0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // SELECTOR DE TIEMPO (Solo visible al inicio)
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
                            // Si no es ninguno de los defaults, es custom
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

                  // RELOJ CIRCULAR
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

                  // BOTÓN DE ACCIÓN
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
                          foregroundColor: Colors.white,
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
        ],
      ),
    );
  }

  // --- HELPERS ---

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

// Widget Botón de Tiempo
class _TimeButton extends StatelessWidget {
  final String label;
  final int seconds;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

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
