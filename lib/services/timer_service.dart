import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/game_data.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:is_lock_screen/is_lock_screen.dart';
import 'notification_service.dart';

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
  static const int _secondsForBaby = 25 * 60; // 25 min para nacer
  static const int _secondsForAdult = 8 * 60 * 60; // 8 horas para ser Adulto
  static const int _secondsPerUserLevel = 4 * 60 * 60; // 4 horas por Nivel

  /*
  // --- B. MODO DEBUG (PRUEBAS RÁPIDAS - DESCOMENTAR PARA TESTEAR) ---
  static const int _secondsForBaby = 10; 
  static const int _secondsForAdult = 30; 
  static const int _secondsPerUserLevel = 20; 
  */
  // ====================================================================

  // Dependencias
  final Box _box = Hive.box('focus_data');
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Variables de Estado del Timer
  int _selectedDuration = 0;
  int _currentSeconds = 0;
  Timer? _timer;
  TimerState _state = TimerState.initial;
  DateTime? _lockTime; // Guardará la hora exacta en que se bloqueó

  // Variables de Progreso del Usuario
  int _totalTimeFocused = 0;
  int _coins = 0;

  // Variables de Personalización e Inventario
  String _equippedPetId = 'classic';
  String _equippedThemeId = 'space';

  // Listas de desbloqueados
  List<String> _unlockedPetIds = ['classic'];
  List<String> _unlockedThemeIds = ['space'];

  // Configuración
  bool _isMuted = false;
  bool _isFirstTime = true; // Control de Onboarding

  // --- VARIABLES DE LÍMITE DE ANUNCIOS (Monedas) ---
  int _adsWatchedToday = 0;
  DateTime _lastAdDate = DateTime.now();
  static const int _maxDailyAds = 2;

  // --- VARIABLES DE LÍMITE DE REVIVIR ---
  int _revivalsUsedToday = 0;
  DateTime _lastRevivalDate = DateTime.now();
  static const int _maxDailyRevivals = 2;

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
  List<String> get unlockedThemeIds => _unlockedThemeIds;

  // Getters de Anuncios
  int get adsWatchedToday => _adsWatchedToday;
  int get maxDailyAds => _maxDailyAds;
  bool get canWatchAd => _adsWatchedToday < _maxDailyAds;

  // Getters de Revivir
  int get revivalsUsedToday => _revivalsUsedToday;
  int get maxDailyRevivals => _maxDailyRevivals;
  bool get canRevive => _revivalsUsedToday < _maxDailyRevivals;

  double get progress =>
      _selectedDuration == 0 ? 0 : 1 - (_currentSeconds / _selectedDuration);

  int get userLevel => (_totalTimeFocused / _secondsPerUserLevel).floor();

  int get evolutionStage {
    if (_totalTimeFocused >= _secondsForAdult) return 2;
    if (_totalTimeFocused >= _secondsForBaby) return 1;
    return 0;
  }

  String get userTitle {
    int lvl = userLevel;
    if (lvl < 10) return "Novato 🌱";
    if (lvl < 20) return "Aprendiz 🔨";
    if (lvl < 30) return "Estudiante 📚";
    if (lvl < 40) return "Académico 🎓";
    if (lvl < 50) return "Maestro 🧘";
    return "Doctor en Focus 🏆";
  }

  double get xpProgress {
    int currentLevelSeconds = userLevel * _secondsPerUserLevel;
    int secondsInThisLevel = _totalTimeFocused - currentLevelSeconds;
    return (secondsInThisLevel / _secondsPerUserLevel).clamp(0.0, 1.0);
  }

  // --------------------------------------------------------------------
  // INICIALIZACIÓN Y PERSISTENCIA
  // --------------------------------------------------------------------

  TimerService() {
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    NotificationService.init();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  void _loadData() {
    _totalTimeFocused = _box.get('totalTime', defaultValue: 0);
    _coins = _box.get('coins', defaultValue: 0);
    _equippedPetId = _box.get('equippedPetId', defaultValue: 'classic');
    _equippedThemeId = _box.get('equippedThemeId', defaultValue: 'space');

    _unlockedPetIds = List<String>.from(
      _box.get('unlockedPetIds', defaultValue: ['classic']),
    );

    _unlockedThemeIds = List<String>.from(
      _box.get('unlockedThemeIds', defaultValue: ['space']),
    );

    _isMuted = _box.get('isMuted', defaultValue: false);
    _isFirstTime = _box.get('isFirstTime', defaultValue: true);

    _adsWatchedToday = _box.get('adsWatchedToday', defaultValue: 0);
    String? dateStr = _box.get('lastAdDate');
    _lastAdDate = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

    _revivalsUsedToday = _box.get('revivalsUsedToday', defaultValue: 0);
    String? revivalDateStr = _box.get('lastRevivalDate');
    _lastRevivalDate = revivalDateStr != null
        ? DateTime.parse(revivalDateStr)
        : DateTime.now();

    _checkDailyReset();

    if (_isFirstTime) {
      _unlockedPetIds = [];
      _unlockedThemeIds = [];
    }

    notifyListeners();
  }

  void _saveData() {
    _box.put('totalTime', _totalTimeFocused);
    _box.put('coins', _coins);
    _box.put('equippedPetId', _equippedPetId);
    _box.put('equippedThemeId', _equippedThemeId);

    _box.put('unlockedPetIds', _unlockedPetIds);
    _box.put('unlockedThemeIds', _unlockedThemeIds);

    _box.put('isMuted', _isMuted);
    _box.put('isFirstTime', _isFirstTime);

    _box.put('adsWatchedToday', _adsWatchedToday);
    _box.put('lastAdDate', _lastAdDate.toIso8601String());

    _box.put('revivalsUsedToday', _revivalsUsedToday);
    _box.put('lastRevivalDate', _lastRevivalDate.toIso8601String());
  }

  void _checkDailyReset() {
    final now = DateTime.now();

    if (!_isSameDay(now, _lastAdDate)) {
      _adsWatchedToday = 0;
      _lastAdDate = now;
    }

    if (!_isSameDay(now, _lastRevivalDate)) {
      _revivalsUsedToday = 0;
      _lastRevivalDate = now;
    }

    _saveData();
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.day == d2.day && d1.month == d2.month && d1.year == d2.year;
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
  // ONBOARDING
  // --------------------------------------------------------------------
  void completeOnboarding(String pickedPetId, String pickedThemeId) {
    _unlockedPetIds = [pickedPetId];
    _unlockedThemeIds = [pickedThemeId];
    _equippedPetId = pickedPetId;
    _equippedThemeId = pickedThemeId;
    _isFirstTime = false;
    _coins = 50;
    _saveData();
    notifyListeners();
  }

  // --------------------------------------------------------------------
  // AUDIO
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
  // MUERTE SÚBITA
  // --------------------------------------------------------------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (_state != TimerState.running) return;

    if (state == AppLifecycleState.paused) {
      _isBackground = true;
      _stopAmbientSound();

      bool? isLocked = await isLockScreen();

      if (isLocked == true) {
        // ✅ Se bloqueó la pantalla. Anotamos la hora exacta.
        _lockTime = DateTime.now();
        debugPrint("Pantalla bloqueada a las: $_lockTime");
      } else {
        // ❌ Salió de la app. Inicia la muerte súbita.
        _deathTimer = Timer(const Duration(seconds: 10), () {
          if (_isBackground) _killPet();
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _isBackground = false;
      _deathTimer?.cancel();

      // 💡 NUEVO: Recalcular el tiempo perdido mientras estuvo bloqueado
      if (_lockTime != null && _state == TimerState.running) {
        final secondsPassed = DateTime.now().difference(_lockTime!).inSeconds;
        _currentSeconds -=
            secondsPassed; // Restamos el tiempo que pasó en la vida real

        if (_currentSeconds <= 0) {
          // Si el tiempo se acabó mientras estaba bloqueado
          _currentSeconds = 0;
          _handleTimerComplete();
        }
        _lockTime = null; // Limpiamos la variable
      }

      if (_state == TimerState.running) {
        _playAmbientSound();
      }
    }
  }

  // --------------------------------------------------------------------
  // TIMER PRINCIPAL
  // --------------------------------------------------------------------
  void setDuration(int seconds) {
    if (_state == TimerState.running) return;
    _selectedDuration = seconds;
    _currentSeconds = seconds;
    notifyListeners();
  }

  void startTimer() {
    if (_state == TimerState.running) return;
    NotificationService.scheduleNotification(
      _selectedDuration,
      "¡Tiempo completado! 🎉",
      "¡Entra a ver qué pasó!",
    );
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

  // --- MÉTODO FALTANTE CORREGIDO ---
  void startTimerDefault() {
    startTimer();
  }

  void _handleTimerComplete() {
    _stopAmbientSound();
    _timer?.cancel();
    int previousStage = evolutionStage;
    int previousLevel = userLevel;
    _totalTimeFocused += _selectedDuration;

    bool isValidForCoins = _selectedDuration >= 300;
    if (_secondsPerUserLevel < 100) isValidForCoins = true;

    if (isValidForCoins) {
      int earnedCoins = (_selectedDuration / 60).ceil();
      if (earnedCoins > 100) earnedCoins = 100;
      if (earnedCoins < 1) earnedCoins = 1;
      _coins += earnedCoins;
    }

    int newStage = evolutionStage;
    int newLevel = userLevel;
    _saveData();

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
    NotificationService.cancelAll();
    _stopAmbientSound();
    _timer?.cancel();
    _state = TimerState.dead;
    _currentSeconds = _selectedDuration;
    WakelockPlus.disable();
    _saveData();
    notifyListeners();
  }

  // --------------------------------------------------------------------
  // REINICIOS Y REVIVIR
  // --------------------------------------------------------------------

  // --- MÉTODO FALTANTE CORREGIDO ---
  void nextSession() {
    _timer?.cancel();
    _currentSeconds = _selectedDuration;
    _state = TimerState.initial;
    notifyListeners();
  }

  void revivePet() {
    // Método simple de revivir (usado por el botón de castigo antiguo si hiciera falta)
    _timer?.cancel();
    _currentSeconds = _selectedDuration;
    _state = TimerState.initial;
    _saveData();
    notifyListeners();
  }

  void revivePetWithAd() {
    _checkDailyReset();

    if (_revivalsUsedToday < _maxDailyRevivals) {
      _revivalsUsedToday++;
      _lastRevivalDate = DateTime.now();

      _timer?.cancel();
      _currentSeconds = _selectedDuration;
      _state = TimerState.initial;

      _saveData();
      notifyListeners();
    }
  }

  void acceptDeathAndReset() {
    _timer?.cancel();
    _currentSeconds = _selectedDuration;
    _state = TimerState.initial;
    _totalTimeFocused = 0; // Se pierde el progreso
    _saveData();
    notifyListeners();
  }

  // --------------------------------------------------------------------
  // TIENDA E INVENTARIO
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

  bool buyTheme(String themeId, int cost) {
    if (_coins >= cost && !_unlockedThemeIds.contains(themeId)) {
      _coins -= cost;
      _unlockedThemeIds.add(themeId);
      _equippedThemeId = themeId;
      _saveData();
      notifyListeners();
      return true;
    }
    return false;
  }

  bool tryAddRewardCoins(int amount) {
    _checkDailyReset();
    if (canWatchAd) {
      _coins += amount;
      _adsWatchedToday++;
      _lastAdDate = DateTime.now();
      _saveData();
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  void addRewardCoins(int amount) {
    _coins += amount;
    _box.put('coins', _coins);
    notifyListeners();
  }
}
