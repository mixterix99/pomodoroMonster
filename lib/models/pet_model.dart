class Pet {
  final String id; // Identificador único (ej: 'pet_fire')
  final String name; // Nombre visible (ej: 'Inferno')
  final String description; // Historia corta

  // Rutas de las imágenes
  final String assetEgg;
  final String assetBaby;
  final String assetAdult;

  // Economía
  final int priceCoins; // Costo en monedas del juego
  final bool isPremium; // ¿Requiere dinero real?

  const Pet({
    required this.id,
    required this.name,
    required this.description,
    required this.assetEgg,
    required this.assetBaby,
    required this.assetAdult,
    this.priceCoins = 0,
    this.isPremium = false,
  });
}
