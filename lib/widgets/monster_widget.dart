import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/timer_service.dart';
import '../data/game_data.dart'; // <--- Importamos los datos
import '../models/pet_model.dart'; // <--- Importamos el modelo

class MonsterWidget extends StatefulWidget {
  const MonsterWidget({super.key});

  @override
  State<MonsterWidget> createState() => _MonsterWidgetState();
}

class _MonsterWidgetState extends State<MonsterWidget>
    with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late AnimationController _wobbleController;
  Timer? _randomActionTimer;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);

    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _startRandomBehavior();
  }

  void _startRandomBehavior() {
    _randomActionTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && Random().nextBool()) {
        _wobbleController
            .forward(from: 0.0)
            .then((_) => _wobbleController.reverse());
      }
    });
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _wobbleController.dispose();
    _randomActionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerService = Provider.of<TimerService>(context);

    // --- LÓGICA DINÁMICA ---
    // 1. Obtenemos el ID de la mascota equipada
    String petId = timerService.equippedPetId;
    // 2. Buscamos los datos reales en GameData
    Pet currentPet = GameData.getPetById(petId);

    return SizedBox(
      height: 250,
      width: 250,
      child: _buildContent(timerService, currentPet),
    );
  }

  Widget _buildContent(TimerService service, Pet pet) {
    // 1. MUERTE 💀 (Esta imagen es global o podría ser por mascota)
    if (service.state == TimerState.dead) {
      return _animateFloating(
        Image.asset('assets/images/ghost.png', fit: BoxFit.contain),
      );
    }

    // 2. TRANSICIÓN: ECLOSIÓN 🥚💥
    if (service.state == TimerState.hatching) {
      // Podrías tener un huevo roto específico por mascota (pet.assetBrokenEgg)
      // Por ahora usaremos el genérico o el huevo normal temblando fuerte
      return _animateShake(
        Image.asset('assets/images/broken_egg.png', fit: BoxFit.contain),
      );
    }

    // 3. TRANSICIÓN: LEVEL UP ✨
    if (service.state == TimerState.levelUp) {
      return _animateBreathAndJump(
        Image.asset(pet.assetAdult, fit: BoxFit.contain),
      );
    }

    // 4. ESTADO NORMAL
    if (service.level == 0) {
      // HUEVO ESPECÍFICO DE LA MASCOTA
      return _animateWobble(Image.asset(pet.assetEgg, fit: BoxFit.contain));
    } else if (service.level == 1) {
      // BEBÉ ESPECÍFICO
      return _animateBreathAndJump(
        Image.asset(pet.assetBaby, fit: BoxFit.contain),
      );
    } else {
      // ADULTO ESPECÍFICO
      return _animateBreathAndJump(
        Image.asset(pet.assetAdult, fit: BoxFit.contain),
      );
    }
  }

  // --- ANIMACIONES (Sin cambios) ---
  Widget _animateWobble(Widget child) {
    return AnimatedBuilder(
      animation: _wobbleController,
      builder: (context, c) {
        double rotation = sin(_wobbleController.value * pi * 2) * 0.05;
        return Transform.rotate(angle: rotation, child: c);
      },
      child: child,
    );
  }

  Widget _animateBreathAndJump(Widget child) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breatheController, _wobbleController]),
      builder: (context, c) {
        double scale = _breatheController.value;
        double jump = _wobbleController.value * -20;
        return Transform.translate(
          offset: Offset(0, jump),
          child: Transform.scale(scale: scale, child: c),
        );
      },
      child: child,
    );
  }

  Widget _animateFloating(Widget child) {
    return AnimatedBuilder(
      animation: _breatheController,
      builder: (context, c) {
        double float = (_breatheController.value - 1.0) * 30;
        return Transform.translate(
          offset: Offset(0, float),
          child: Opacity(opacity: 0.8, child: c),
        );
      },
      child: child,
    );
  }

  Widget _animateShake(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -5.0, end: 5.0),
      duration: const Duration(milliseconds: 100),
      builder: (context, value, child) {
        return Transform.translate(offset: Offset(value, 0), child: child);
      },
      child: child,
    );
  }
}
