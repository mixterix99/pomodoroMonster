import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/game_data.dart';

// Estados posibles de la app
enum TimerState {
  initial, // Esperando
  running, // Estudiando
  paused, // (Reservado)
  hatching, // Animación: Huevo -> Bebé
  levelUp, // Animación: Subir Nivel Usuario
  finished, // Sesión terminada
  dead, // Muerte por salir de la app
}

class TimerService extends ChangeNotifier with WidgetsBindingObserver {
  // ====================================================================
  // ⚙️ CONFIGURACIÓN DE BALANCEO (TIEMPO)
  // ====================================================================

  // --- A. MODO PRODUCCIÓN (REAL) ---
  // (Descomenta esto cuando vayas a publicar la App)
  /*
  static const int _secondsForBaby = 25 * 60;        // 25 min para nacer
  static const int _secondsForAdult = 8 * 60 * 60;   // 8 horas para ser Adulto
  static const int _secondsPerUserLevel = 4 * 60 * 60; // 4 horas por Nivel de Usuario
  */

  // --- B. MODO DEBUG (PRUEBAS RÁPIDAS) ---
  // (Usa esto ahora para ver cambios en segundos)
  static const int _secondsForBaby = 10; // 10 seg para nacer
  static const int _secondsForAdult = 30; // 30 seg para ser Adulto
  static const int _secondsPerUserLevel = 20; // 20 seg por Nivel de Usuario

  // ====================================================================

  // Dependencias
  final Box _box = Hive.box('focus_data');
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Variables de Estado del Timer
  int _selectedDuration = 5;
  int _currentSeconds = 5;
  Timer? _timer;
  TimerState _state = TimerState.initial;

  // Variables de Progreso del Usuario
  int _totalTimeFocused = 0;
  int _coins = 0;

  // Variables de Personalización e Inventario
  String _equippedPetId = 'classic';
  String _equippedThemeId = 'space';
  List<String> _unlockedPetIds = ['classic'];

  // Configuración
  bool _isMuted = false;
  bool _isFirstTime = true; // Control de Onboarding

  // --- VARIABLES DE LÍMITE DE ANUNCIOS (NUEVO) ---
  int _adsWatchedToday = 0;
  DateTime _lastAdDate = DateTime.now();
  static const int _maxDailyAds = 2; // Límite de 2 videos al día

  // Lógica de Muerte (Background)
  Timer? _deathTimer;
  bool _isBackground = false;

  // --------------------------------------------------------------------
  // GETTERS (Lo que la UI ve)
  // --------------------------------------------------------------------

  int get currentSeconds => _currentSeconds;
  int get maxSeconds => _selectedDuration;
  TimerState get state => _state;
  int get totalTime => _totalTimeFocused;
  int get coins => _coins;
  bool get isMuted => _isMuted;
  bool get isFirstTime => _isFirstTime;

  String get equippedPetId => _equippedPetId;
  String get equippedThemeId => _equippedThemeId;
  List<String> get unlockedPetIds => _unlockedPetIds;

  // Getters de Anuncios
  int get adsWatchedToday => _adsWatchedToday;
  int get maxDailyAds => _maxDailyAds;
  bool get canWatchAd => _adsWatchedToday < _maxDailyAds;

  double get progress =>
      _selectedDuration == 0 ? 0 : 1 - (_currentSeconds / _selectedDuration);

  // 1. CÁLCULO DE NIVEL DE USUARIO (Infinito)
  int get userLevel => (_totalTimeFocused / _secondsPerUserLevel).floor();

  // 2. CÁLCULO DE FASE DE MASCOTA (0=Huevo, 1=Bebé, 2=Adulto)
  int get evolutionStage {
    if (_totalTimeFocused >= _secondsForAdult) return 2;
    if (_totalTimeFocused >= _secondsForBaby) return 1;
    return 0;
  }

  // 3. TÍTULO DEL USUARIO (Rango basado en nivel) 🎖️
  String get userTitle {
    int lvl = userLevel;
    if (lvl < 10) return "Novato 🌱";
    if (lvl < 20) return "Aprendiz 🔨";
    if (lvl < 30) return "Estudiante 📚";
    if (lvl < 40) return "Académico 🎓";
    if (lvl < 50) return "Maestro 🧘";
    return "Doctor en Focus 🏆";
  }

  // 4. BARRA DE XP (Progreso hacia el SIGUIENTE nivel)
  double get xpProgress {
    int currentLevelSeconds = userLevel * _secondsPerUserLevel;
    int secondsInThisLevel = _totalTimeFocused - currentLevelSeconds;
    return (secondsInThisLevel / _secondsPerUserLevel).clamp(0.0, 1.0);
  }

  // --------------------------------------------------------------------
  // INICIALIZACIÓN Y PERSISTENCIA (HIVE)
  // --------------------------------------------------------------------

  TimerService() {
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _audioPlayer.setReleaseMode(ReleaseMode.loop); // Audio en bucle
  }

  void _loadData() {
    _totalTimeFocused = _box.get('totalTime', defaultValue: 0);
    _coins = _box.get('coins', defaultValue: 0);
    _equippedPetId = _box.get('equippedPetId', defaultValue: 'classic');
    _equippedThemeId = _box.get('equippedThemeId', defaultValue: 'space');
    _unlockedPetIds = List<String>.from(
      _box.get('unlockedPetIds', defaultValue: ['classic']),
    );
    _isMuted = _box.get('isMuted', defaultValue: false);
    _isFirstTime = _box.get('isFirstTime', defaultValue: true);

    // Carga de datos de anuncios
    _adsWatchedToday = _box.get('adsWatchedToday', defaultValue: 0);
    String? dateStr = _box.get('lastAdDate');
    _lastAdDate = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

    // Verificar si es un nuevo día para resetear anuncios
    _checkDailyReset();

    // Si es onboarding, asegurar que la lista empiece limpia
    if (_isFirstTime) {
      _unlockedPetIds = [];
    }

    notifyListeners();
  }

  void _saveData() {
    _box.put('totalTime', _totalTimeFocused);
    _box.put('coins', _coins);
    _box.put('equippedPetId', _equippedPetId);
    _box.put('equippedThemeId', _equippedThemeId);
    _box.put('unlockedPetIds', _unlockedPetIds);
    _box.put('isMuted', _isMuted);
    _box.put('isFirstTime', _isFirstTime);

    // Guardar datos de anuncios
    _box.put('adsWatchedToday', _adsWatchedToday);
    _box.put('lastAdDate', _lastAdDate.toIso8601String());
  }

  // Lógica de reinicio diario de anuncios
  void _checkDailyReset() {
    final now = DateTime.now();
    if (now.day != _lastAdDate.day ||
        now.month != _lastAdDate.month ||
        now.year != _lastAdDate.year) {
      _adsWatchedToday = 0;
      _lastAdDate = now;
      _saveData();
      print("📅 ¡Nuevo día! Contador de anuncios reiniciado.");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _deathTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------
  // LÓGICA DE ONBOARDING (PRIMERA VEZ)
  // --------------------------------------------------------------------

  void completeOnboarding(String pickedPetId, String pickedThemeId) {
    // 1. Desbloqueamos y equipamos SOLO lo elegido
    _unlockedPetIds = [pickedPetId];
    _equippedPetId = pickedPetId;
    _equippedThemeId = pickedThemeId;

    // 2. Ya no es primera vez
    _isFirstTime = false;

    // 3. Regalo de bienvenida (50 monedas)
    _coins = 50;

    _saveData();
    notifyListeners();
  }

  // --------------------------------------------------------------------
  // LÓGICA DE AUDIO
  // --------------------------------------------------------------------

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _stopAmbientSound();
    } else if (_state == TimerState.running) {
      _playAmbientSound();
    }
    _saveData();
    notifyListeners();
  }

  Future<void> _playAmbientSound() async {
    if (_isMuted) return;

    try {
      final theme = GameData.getThemeById(_equippedThemeId);
      if (theme.soundAsset != null) {
        String path = theme.soundAsset!.replaceFirst('assets/', '');
        await _audioPlayer.play(AssetSource(path));
      }
    } catch (e) {
      print("Error reproduciendo audio: $e");
    }
  }

  Future<void> _stopAmbientSound() async {
    await _audioPlayer.stop();
  }

  // --------------------------------------------------------------------
  // DETECCIÓN DE FONDO (MUERTE SÚBITA)
  // --------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_state != TimerState.running) return;

    if (state == AppLifecycleState.paused) {
      _isBackground = true;
      _stopAmbientSound();

      _deathTimer = Timer(const Duration(seconds: 10), () {
        if (_isBackground) _killPet();
      });
    } else if (state == AppLifecycleState.resumed) {
      _isBackground = false;
      _deathTimer?.cancel();
      if (_state == TimerState.running) _playAmbientSound();
    }
  }

  // --------------------------------------------------------------------
  // LÓGICA PRINCIPAL DEL TIMER
  // --------------------------------------------------------------------

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
    _playAmbientSound();
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
    _stopAmbientSound();
    _timer?.cancel();

    int previousStage = evolutionStage;
    int previousLevel = userLevel;

    _totalTimeFocused += _selectedDuration;

    // --- LÓGICA ANTI-TRAMPA Y MONEDAS ---
    bool isValidForCoins = _selectedDuration >= 300;
    if (_secondsPerUserLevel < 100) isValidForCoins = true; // Hack debug

    if (isValidForCoins) {
      int earnedCoins = (_selectedDuration / 60).ceil();
      if (earnedCoins > 100) earnedCoins = 100;
      if (earnedCoins < 1) earnedCoins = 1;
      _coins += earnedCoins;
    }

    int newStage = evolutionStage;
    int newLevel = userLevel;

    _saveData();

    // --- SELECCIÓN DE ANIMACIÓN ---
    if (previousStage == 0 && newStage == 1) {
      _state = TimerState.hatching;
      notifyListeners();
      Future.delayed(const Duration(seconds: 2), () {
        _state = TimerState.finished;
        notifyListeners();
      });
    } else if (newLevel > previousLevel) {
      _state = TimerState.levelUp;
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

  void _killPet() {
    _stopAmbientSound();
    _timer?.cancel();
    _state = TimerState.dead;
    _totalTimeFocused = 0;
    _currentSeconds = _selectedDuration;
    _saveData();
    notifyListeners();
  }

  // --------------------------------------------------------------------
  // REINICIOS Y NAVEGACIÓN
  // --------------------------------------------------------------------

  void revivePet() {
    _timer?.cancel();
    _currentSeconds = _selectedDuration;
    _state = TimerState.initial;
    _totalTimeFocused = 0;
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

  // --------------------------------------------------------------------
  // TIENDA, INVENTARIO Y RECOMPENSAS
  // --------------------------------------------------------------------

  void equipPet(String petId) {
    if (_state == TimerState.running) return;
    if (_unlockedPetIds.contains(petId)) {
      _equippedPetId = petId;
      _saveData();
      notifyListeners();
    }
  }

  void equipTheme(String themeId) {
    _equippedThemeId = themeId;
    _saveData();
    notifyListeners();
  }

  bool buyPet(String petId, int cost) {
    if (_coins >= cost && !_unlockedPetIds.contains(petId)) {
      _coins -= cost;
      _unlockedPetIds.add(petId);
      _saveData();
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- NUEVO: Sumar monedas de recompensa CON LÍMITE DIARIO ---
  bool tryAddRewardCoins(int amount) {
    _checkDailyReset(); // Validar día

    if (canWatchAd) {
      _coins += amount;
      _adsWatchedToday++; // Incrementar contador diario
      _lastAdDate = DateTime.now(); // Actualizar fecha

      _saveData();
      notifyListeners();
      return true; // Éxito
    } else {
      return false; // Fallo (Límite alcanzado)
    }
  }

  // MODO DIOS (Debug)
  void debugEquipPet(String petId) {
    if (!_unlockedPetIds.contains(petId)) {
      _unlockedPetIds.add(petId);
      _box.put('unlockedPetIds', _unlockedPetIds);
    }
    _equippedPetId = petId;
    _box.put('equippedPetId', _equippedPetId);
    notifyListeners();
  }
}
