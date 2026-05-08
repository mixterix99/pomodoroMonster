import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart'; // <--- Importante para IAP

// Servicios y Modelos
import '../services/timer_service.dart';
import '../services/ad_service.dart';
import '../services/purchase_service.dart'; // <--- Tu servicio de RevenueCat
import '../data/game_data.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Mascotas, Temas, Monedas
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Tienda Focus",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // CONTADOR DE MONEDAS EN TIEMPO REAL
            Consumer<TimerService>(
              builder: (context, service, _) => Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 20),
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
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "${service.coins}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.orangeAccent,
            labelColor: Colors.orangeAccent,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(icon: Icon(Icons.pets), text: "Mascotas"),
              Tab(icon: Icon(Icons.palette), text: "Temas"),
              Tab(icon: Icon(Icons.add_circle), text: "Monedas"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PetsTab(),
            _ThemesTab(), // <--- Actualizada
            _CoinsTab(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PESTAÑA 1: MASCOTAS + ADS (Video Reward)
// ============================================================================
class _PetsTab extends StatelessWidget {
  const _PetsTab();

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<TimerService>(context);
    final adService = Provider.of<AdService>(context, listen: false);
    final pets = GameData.pets;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: pets.length + 1, // +1 por el botón de anuncios
      itemBuilder: (context, index) {
        // --- TARJETA DE RECOMPENSA (Posición 0) ---
        if (index == 0) {
          bool canWatch = service.canWatchAd; // Verifica límite diario
          int adsLeft = service.maxDailyAds - service.adsWatchedToday;

          return _AdRewardCard(
            isEnabled: canWatch,
            adsLeft: adsLeft,
            onWatch: () {
              if (!canWatch) return;

              adService.showRewarded(() {
                // Callback de éxito: usuario vio todo el video
                bool success = service.tryAddRewardCoins(15);
                if (success) {
                  _showSuccess(context, "¡+15 Monedas recibidas! 💰");
                }
              });
            },
          );
        }

        // --- TARJETAS DE MASCOTAS ---
        final pet = pets[index - 1];
        final isUnlocked = service.unlockedPetIds.contains(pet.id);
        final isEquipped = service.equippedPetId == pet.id;
        final canAfford = service.coins >= pet.priceCoins;

        return _ShopCard(
          title: pet.name,
          subtitle: pet.isPremium ? "Premium" : "${pet.priceCoins} 💰",
          imageAsset: pet.assetAdult,
          isUnlocked: isUnlocked,
          isEquipped: isEquipped,
          isPremium: pet.isPremium,
          onAction: () {
            if (isEquipped) return;

            if (isUnlocked) {
              service.equipPet(pet.id);
            } else if (pet.isPremium) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("💎 Próximamente...")),
              );
            } else {
              // Intento de compra
              if (canAfford) {
                if (service.buyPet(pet.id, pet.priceCoins)) {
                  _showSuccess(context, "¡Bienvenido ${pet.name}!");
                }
              } else {
                _showError(context, "Te faltan monedas");
              }
            }
          },
        );
      },
    );
  }
}

// ============================================================================
// PESTAÑA 2: TEMAS (ACTUALIZADA)
// ============================================================================
class _ThemesTab extends StatelessWidget {
  const _ThemesTab();

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<TimerService>(context);
    final themes = GameData.themes;
    const int premiumPrice = 500; // PRECIO FIJO DEFINIDO

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        final isEquipped = service.equippedThemeId == theme.id;

        // Un tema está desbloqueado si es GRATIS o si está en la lista de comprados
        bool isUnlocked =
            theme.isFree || service.unlockedThemeIds.contains(theme.id);

        return _ShopCard(
          title: theme.name,
          // Muestra "Gratis/Adquirido" o el precio "500"
          subtitle: isUnlocked
              ? (theme.isFree ? "Gratis" : "Adquirido")
              : "$premiumPrice 💰",
          imageAsset: theme.backgroundAsset ?? "",
          isUnlocked: isUnlocked,
          isEquipped: isEquipped,
          isPremium: !theme.isFree,
          onAction: () {
            // 1. Si ya está equipado, nada
            if (isEquipped) return;

            // 2. Si está desbloqueado, equipar
            if (isUnlocked) {
              service.equipTheme(theme.id);
            }
            // 3. Si está bloqueado, intentar comprar
            else {
              if (service.coins >= premiumPrice) {
                // LLAMADA AL SERVICIO PARA COMPRAR
                if (service.buyTheme(theme.id, premiumPrice)) {
                  _showSuccess(context, "¡Tema desbloqueado! 🎨");
                } else {
                  _showError(context, "Error al comprar");
                }
              } else {
                _showError(context, "Necesitas $premiumPrice monedas");
              }
            }
          },
        );
      },
    );
  }
}

// ============================================================================
// PESTAÑA 3: MONEDAS (RevenueCat Integration)
// ============================================================================
class _CoinsTab extends StatefulWidget {
  const _CoinsTab();
  @override
  State<_CoinsTab> createState() => _CoinsTabState();
}

class _CoinsTabState extends State<_CoinsTab> {
  final PurchaseService _purchaseService = PurchaseService();
  List<Package> _packages = [];
  bool _isLoading = true;
  String _statusMessage = "";

  @override
  void initState() {
    super.initState();
    _initStore();
  }

  Future<void> _initStore() async {
    try {
      await _purchaseService.initialize();
      final offers = await _purchaseService.fetchOffers();

      if (mounted) {
        setState(() {
          _packages = offers;
          // Ordenar por precio (de menor a mayor)
          _packages.sort(
            (a, b) => a.storeProduct.price.compareTo(b.storeProduct.price),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Error cargando tienda.";
        });
      }
      print("Error Store: $e");
    }
  }

  // Mapa visual: Relaciona el ID del paquete en RevenueCat con Colores/Texto
  Map<String, dynamic> _getPackageVisuals(String packageId) {
    if (packageId == 'pack_small') {
      return {"coins": 50, "color": Colors.amber[300], "tag": null};
    } else if (packageId == 'pack_medium') {
      return {"coins": 250, "color": Colors.amber[500], "tag": "POPULAR"};
    } else if (packageId == 'pack_large') {
      return {"coins": 600, "color": Colors.amber[700], "tag": "MEJOR VALOR"};
    }
    // Fallback por si cambia el ID
    return {"coins": 0, "color": Colors.grey, "tag": null};
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orangeAccent),
      );
    }

    if (_packages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "No hay ofertas disponibles.\nRevisa tu conexión o la configuración de RevenueCat.\n$_statusMessage",
            style: const TextStyle(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _packages.length,
      itemBuilder: (context, index) {
        final package = _packages[index];
        final product = package.storeProduct;

        // Obtener visuales según el ID del paquete (pack_small, etc.)
        final visuals = _getPackageVisuals(package.identifier);
        final int coinsAmount = visuals["coins"] as int;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF252540),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              // ICONO VISUAL
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (visuals["color"] as Color).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monetization_on,
                  color: visuals["color"],
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // INFO DEL PAQUETE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (visuals["tag"] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          visuals["tag"],
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Text(
                      "$coinsAmount Monedas",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      product.description,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // BOTÓN DE PRECIO (Google Play)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onPressed: () async {
                  // 1. Ejecutar compra en RevenueCat
                  bool success = await _purchaseService.purchasePackage(
                    package,
                  );

                  if (success && context.mounted) {
                    // 2. Dar monedas al usuario
                    final timerService = Provider.of<TimerService>(
                      context,
                      listen: false,
                    );

                    // Usamos addRewardCoins pero sin límite diario (porque está pagando)
                    timerService.addRewardCoins(coinsAmount);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.green,
                        content: Text(
                          "¡Compra exitosa! +$coinsAmount Monedas 💰",
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  product.priceString,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// WIDGETS AUXILIARES
// ============================================================================

// Tarjeta de "Ver Video"
class _AdRewardCard extends StatelessWidget {
  final VoidCallback onWatch;
  final bool isEnabled;
  final int adsLeft;

  const _AdRewardCard({
    required this.onWatch,
    required this.isEnabled,
    required this.adsLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isEnabled ? Colors.amber.withOpacity(0.15) : Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? Colors.amber : Colors.grey,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isEnabled ? Colors.amber : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isEnabled ? Icons.play_arrow : Icons.lock,
              size: 30,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isEnabled ? "Monedas Gratis" : "Límite Diario",
            style: TextStyle(
              color: isEnabled ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            isEnabled ? "+15 💰" : "Vuelve mañana",
            style: TextStyle(
              color: isEnabled ? Colors.amber : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "$adsLeft disponibles",
            style: TextStyle(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 30,
            child: ElevatedButton(
              onPressed: isEnabled ? onWatch : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                "VER VIDEO",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Tarjeta Estándar de Producto (Mascota/Tema)
class _ShopCard extends StatelessWidget {
  final String title, subtitle, imageAsset;
  final bool isUnlocked, isEquipped, isPremium;
  final VoidCallback onAction;

  const _ShopCard({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.isUnlocked,
    required this.isEquipped,
    required this.isPremium,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252540),
        borderRadius: BorderRadius.circular(16),
        border: isEquipped
            ? Border.all(color: Colors.greenAccent, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: Colors.black26,
                child: Image.asset(imageAsset, fit: BoxFit.contain),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEquipped
                          ? Colors.grey[700]
                          : (isUnlocked
                                ? Colors.blueAccent
                                : (isPremium
                                      ? Colors.purpleAccent
                                      : Colors.amber)),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      isEquipped
                          ? "EQUIPADO"
                          : (isUnlocked ? "EQUIPAR" : "COMPRAR"),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helpers para mensajes
void _showSuccess(BuildContext context, String msg) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(backgroundColor: Colors.green, content: Text(msg)));
}

void _showError(BuildContext context, String msg) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(msg)));
}
