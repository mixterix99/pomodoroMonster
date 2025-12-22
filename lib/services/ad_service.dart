import 'package:google_mobile_ads/google_mobile_ads.dart';
// Para dar las recompensas

class AdService {
  // IDs DE PRUEBA OFICIALES DE GOOGLE (ANDROID/IOS)
  // ¡No uses estos en producción!
  final String _interstitialId = 'ca-app-pub-5479522990707049/6352917593';
  final String _rewardedId = 'ca-app-pub-5479522990707049/8293503462';

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // Inicializar SDK
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitial();
    _loadRewarded();
  }

  // --- 1. INTERSTICIAL (Pantalla completa al terminar timer) ---
  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          // Cuando se cierre el anuncio, cargamos el siguiente
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitial(); // Precargar el siguiente
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (err) {
          print('Error cargando Intersticial: $err');
          _interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitial() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      // Nota: El siguiente se carga automáticamente en el callback 'onDismissed' de arriba
    } else {
      print("El anuncio intersticial aún no estaba listo.");
      _loadInterstitial(); // Intentar cargar de nuevo
    }
  }

  // --- 2. REWARDED (Video por monedas) ---
  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadRewarded(); // Precargar el siguiente
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (err) {
          print('Error cargando Rewarded: $err');
          _rewardedAd = null;
        },
      ),
    );
  }

  // Muestra el anuncio y ejecuta 'onReward' si el usuario lo ve completo
  void showRewarded(FunctionOnReward onReward) {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          // El usuario vio el video completo
          onReward();
        },
      );
      // El siguiente se carga en onAdDismissedFullScreenContent
    } else {
      print("El anuncio recompensado no estaba listo.");
      _loadRewarded();
    }
  }
}

// Definición simple para el callback
typedef FunctionOnReward = void Function();
