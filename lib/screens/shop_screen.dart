import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/timer_service.dart';
import '../services/ad_service.dart';
import '../data/game_data.dart';
import '../models/pet_model.dart';
import '../models/theme_model.dart';

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
          children: [_PetsTab(), _ThemesTab(), _CoinsTab()],
        ),
      ),
    );
  }
}

// --- PESTAÑA 1: MASCOTAS + ADS (LÓGICA ACTUALIZADA) ---
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
      itemCount: pets.length + 1,
      itemBuilder: (context, index) {
        // --- 1. TARJETA DE RECOMPENSA (INDEX 0) ---
        if (index == 0) {
          // Verificamos si tiene permitido ver anuncios hoy
          bool canWatch = service.canWatchAd;
          int adsLeft = service.maxDailyAds - service.adsWatchedToday;

          return _AdRewardCard(
            isEnabled: canWatch,
            adsLeft: adsLeft,
            onWatch: () {
              if (!canWatch) return;

              adService.showRewarded(() {
                // Callback si ve el video completo
                bool success = service.tryAddRewardCoins(15);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.amber,
                      content: Text("¡+15 Monedas recibidas! 💰"),
                    ),
                  );
                }
              });
            },
          );
        }

        // --- 2. TARJETAS DE MASCOTAS ---
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
              if (canAfford) {
                if (service.buyPet(pet.id, pet.priceCoins))
                  _showSuccess(context, "¡Bienvenido ${pet.name}!");
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

// --- PESTAÑA 2: TEMAS ---
class _ThemesTab extends StatelessWidget {
  const _ThemesTab();

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<TimerService>(context);
    final themes = GameData.themes;

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

        // Asumimos que los temas 'Free' están desbloqueados.
        // Si implementas compra de temas, usa lógica similar a mascotas.
        bool isUnlocked = theme.isFree;

        return _ShopCard(
          title: theme.name,
          subtitle: theme.isFree ? "Gratis" : "${theme.priceCoins} 💰",
          imageAsset: theme.backgroundAsset ?? "",
          isUnlocked: isUnlocked,
          isEquipped: isEquipped,
          isPremium: !theme.isFree,
          onAction: () {
            if (theme.isFree) {
              service.equipTheme(theme.id);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("🔒 Desbloqueo de temas premium próximamente"),
                ),
              );
            }
          },
        );
      },
    );
  }
}

// --- PESTAÑA 3: PAQUETES DE MONEDAS (UI PREPARADA) ---
class _CoinsTab extends StatelessWidget {
  const _CoinsTab();

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> coinPacks = [
      {
        "coins": 25,
        "price": "US\$ 1.99",
        "color": Colors.amber[300],
        "id": "coins_100",
      },
      {
        "coins": 50,
        "price": "US\$ 2.99",
        "color": Colors.amber[500],
        "id": "coins_500",
        "tag": "POPULAR",
      },
      {
        "coins": 150,
        "price": "US\$ 4.99",
        "color": Colors.amber[700],
        "id": "coins_1200",
        "tag": "MEJOR VALOR",
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: coinPacks.length,
      itemBuilder: (context, index) {
        final pack = coinPacks[index];
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (pack["color"] as Color).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monetization_on,
                  color: pack["color"],
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pack.containsKey("tag"))
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
                          pack["tag"],
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Text(
                      "${pack["coins"]} Monedas",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("💳 Conexión con Store próximamente..."),
                    ),
                  );
                },
                child: Text(
                  pack["price"],
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

// --- WIDGET TARJETA DE RECOMPENSA (ADS) CON ESTADO ---
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

// --- WIDGET TARJETA ESTÁNDAR ---
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

void _showSuccess(BuildContext context, String msg) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(backgroundColor: Colors.green, content: Text(msg)));
void _showError(BuildContext context, String msg) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(msg)));
