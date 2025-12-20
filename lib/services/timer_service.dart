import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum TimerState { initial, running, paused, hatching, levelUp, finished, dead }

class TimerService extends ChangeNotifier with WidgetsBindingObserver {
  // CONFIGURACIÓN DE NIVELES
  static const int _secondsToReachLevel1 = 15;
  static const int _secondsToReachLevel2 = 30;

  final Box _box = Hive.box('focus_data');

  // --- VARIABLES DE ESTADO ---
  int _selectedDuration = 5;
  int _currentSeconds = 5;
  Timer? _timer;
  TimerState _state = TimerState.initial;

  // --- VARIABLES DE PROGRESO ---
  int _totalTimeFocused = 0;
  int _level = 0;
  int _coins = 0; // 💰 Nuevo: Monedas

  // --- VARIABLES DE PERSONALIZACIÓN (Ids) ---
  String _equippedPetId = 'classic';
  String _equippedThemeId = 'space';
  List<String> _unlockedPetIds = ['classic'];
  // List<String> _unlockedThemeIds = ['space', 'library', 'beach']; // Descomentar en fase 2

  Timer? _deathTimer;
  bool _isBackground = false;

  // GETTERS
  int get currentSeconds => _currentSeconds;
  int get maxSeconds => _selectedDuration;
  TimerState get state => _state;
  int get level => _level;
  int get totalTime => _totalTimeFocused;
  int get coins => _coins; // Nuevo getter

  // Getters de Personalización
  String get equippedPetId => _equippedPetId;
  String get equippedThemeId => _equippedThemeId;
  List<String> get unlockedPetIds => _unlockedPetIds;

  double get progress =>
      _selectedDuration == 0 ? 0 : 1 - (_currentSeconds / _selectedDuration);

  double get xpProgress {
    if (_level == 0) {
      return (_totalTimeFocused / _secondsToReachLevel1).clamp(0.0, 1.0);
    } else if (_level == 1) {
      return ((_totalTimeFocused - _secondsToReachLevel1) /
              (_secondsToReachLevel2 - _secondsToReachLevel1))
          .clamp(0.0, 1.0);
    }
    return 1.0;
  }

  TimerService() {
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  // --- PERSISTENCIA MEJORADA ---
  void _loadData() {
    _totalTimeFocused = _box.get('totalTime', defaultValue: 0);
    _level = _box.get('level', defaultValue: 0);
    _coins = _box.get('coins', defaultValue: 0);

    _equippedPetId = _box.get('equippedPetId', defaultValue: 'classic');
    _equippedThemeId = _box.get('equippedThemeId', defaultValue: 'space');
    _unlockedPetIds = List<String>.from(
      _box.get('unlockedPetIds', defaultValue: ['classic']),
    );

    notifyListeners();
  }

  void _saveData() {
    _box.put('totalTime', _totalTimeFocused);
    _box.put('level', _level);
    _box.put('coins', _coins);

    _box.put('equippedPetId', _equippedPetId);
    _box.put('equippedThemeId', _equippedThemeId);
    _box.put('unlockedPetIds', _unlockedPetIds);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _deathTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_state != TimerState.running) return;

    if (state == AppLifecycleState.paused) {
      _isBackground = true;
      _deathTimer = Timer(const Duration(seconds: 10), () {
        if (_isBackground) _killPet();
      });
    } else if (state == AppLifecycleState.resumed) {
      _isBackground = false;
      _deathTimer?.cancel();
    }
  }

  void _killPet() {
    _timer?.cancel();
    _state = TimerState.dead;

    _totalTimeFocused = 0;
    _level = 0;
    _currentSeconds = _selectedDuration;

    _saveData();
    notifyListeners();
  }

  void setDuration(int seconds) {
    if (_state == TimerState.running) return;
    _selectedDuration = seconds;
    _currentSeconds = seconds;
    notifyListeners();
  }

  void startTimer() {
    if (_state == TimerState.running) return;
    _currentSeconds = _selectedDuration;
    _state = TimerState.running;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSeconds > 0) {
        _currentSeconds--;
        notifyListeners();
      } else {
        _handleTimerComplete();
      }
    });
  }

  void startTimerDefault() {
    startTimer();
  }

  void _handleTimerComplete() {
    _timer?.cancel();

    _totalTimeFocused += _selectedDuration;

    // GANAR MONEDAS: 1 moneda por minuto (aprox)
    int earnedCoins = (_selectedDuration / 60).ceil();
    if (earnedCoins < 1) earnedCoins = 1; // Mínimo 1 moneda
    _coins += earnedCoins;

    int newLevel = 0;
    if (_totalTimeFocused >= _secondsToReachLevel2)
      newLevel = 2;
    else if (_totalTimeFocused >= _secondsToReachLevel1)
      newLevel = 1;

    bool leveledUp = newLevel > _level;
    _level = newLevel;

    _saveData();

    if (leveledUp) {
      _state = (_level == 1) ? TimerState.hatching : TimerState.levelUp;
      notifyListeners();
      Future.delayed(const Duration(seconds: 2), () {
        _state = TimerState.finished;
        notifyListeners();
      });
    } else {
      _state = TimerState.finished;
      notifyListeners();
    }
  }

  void revivePet() {
    _timer?.cancel();
    _currentSeconds = _selectedDuration;
    _state = TimerState.initial;
    _totalTimeFocused = 0;
    _level = 0;
    _saveData();
    notifyListeners();
  }

  void nextSession() {
    _timer?.cancel();
    _currentSeconds = _selectedDuration;
    _state = TimerState.initial;
    notifyListeners();
  }

  void resetTimer() {
    revivePet();
  }

  // --- MÉTODOS DE LA TIENDA/INVENTARIO ---

  // Cambiar Mascota
  void equipPet(String petId) {
    if (_state == TimerState.running) return; // No cambiar mientras estudias
    if (_unlockedPetIds.contains(petId)) {
      _equippedPetId = petId;
      _saveData();
      notifyListeners();
    }
  }

  // Cambiar Tema
  void equipTheme(String themeId) {
    _equippedThemeId = themeId;
    _saveData();
    notifyListeners();
  }

  // Comprar Mascota (Lógica base)
  bool buyPet(String petId, int cost) {
    if (_coins >= cost && !_unlockedPetIds.contains(petId)) {
      _coins -= cost;
      _unlockedPetIds.add(petId);
      _saveData();
      notifyListeners();
      return true; // Compra exitosa
    }
    return false; // Fondos insuficientes
  }

  void debugEquipPet(String petId) {
    // 1. Si no la tenemos desbloqueada, la agregamos a la fuerza
    if (!_unlockedPetIds.contains(petId)) {
      _unlockedPetIds.add(petId);
      _box.put('unlockedPetIds', _unlockedPetIds); // Guardar desbloqueo
    }

    // 2. Equipamos directamente sin preguntar precio
    _equippedPetId = petId;
    _box.put('equippedPetId', _equippedPetId); // Guardar elección

    notifyListeners(); // ¡Actualizar pantalla!
  }
}
