import 'package:flutter/material.dart';
import '../models/pet_model.dart';
import '../models/theme_model.dart';

class GameData {
  // --- LISTA DE MASCOTAS ---
  static const List<Pet> pets = [
    // 1. INICIAL (Gratis)
    Pet(
      id: 'classic',
      name: 'Dino',
      description: 'El compañero clásico de estudio.',
      assetEgg: 'assets/images/pet_classic_egg.png',
      assetBaby: 'assets/images/pet_classic_baby.png',
      assetAdult: 'assets/images/pet_classic_adult.png',
      priceCoins: 150,
    ),
    // 2. FUEGO (Costoso en monedas)
    Pet(
      id: 'inferno',
      name: 'Inferno',
      description: 'Nacido en el volcán de la procrastinación.',
      assetEgg: 'assets/images/pet_fire_egg.png',
      assetBaby: 'assets/images/pet_fire_baby.png',
      assetAdult: 'assets/images/pet_fire_adult.png',
      priceCoins: 750, // 500 minutos de estudio
    ),
    // 3. AGUA (Medio)
    Pet(
      id: 'aqua',
      name: 'Bloop',
      description: 'Te mantiene fresco y concentrado.',
      assetEgg: 'assets/images/pet_water_egg.png',
      assetBaby: 'assets/images/pet_water_baby.png',
      assetAdult: 'assets/images/pet_water_adult.png',
      priceCoins: 350,
    ),
    // 4. PLANTA (Barato)
    Pet(
      id: 'flora',
      name: 'Sprout',
      description: 'Crece lento pero seguro.',
      assetEgg: 'assets/images/pet_plant_egg.png',
      assetBaby: 'assets/images/pet_plant_baby.png',
      assetAdult: 'assets/images/pet_plant_adult.png',
      priceCoins: 150,
    ),
    // 5. ROBO (Premium / Dinero Real)
    Pet(
      id: 'robo',
      name: 'Cyber-X',
      description: 'Tecnología avanzada para mentes rápidas.',
      assetEgg: 'assets/images/pet_robo_egg.png',
      assetBaby: 'assets/images/pet_robo_baby.png',
      assetAdult: 'assets/images/pet_robo_adult.png',
      isPremium: false,
      priceCoins: 500, // $$$
    ),
  ];

  // --- LISTA DE TEMAS ---
  static const List<AppTheme> themes = [
    // 1. ESPACIO (Default)
    AppTheme(
      id: 'space',
      name: 'Espacio Profundo',
      primaryColor: Colors.orangeAccent,
      backgroundColor: Color(0xFF1A1A2E),
      backgroundAsset: 'assets/images/bg_space.png', // <--- Imagen Fondo
      soundAsset: 'assets/audio/espacio.mp3', // Azul oscuro
      isFree: true,
    ),
    // 2. BIBLIOTECA (Café/Beige)
    AppTheme(
      id: 'library',
      name: 'Biblioteca Antigua',
      primaryColor: Color(0xFF8D6E63), // Marrón suave
      backgroundColor: Color(0xFF3E2723), // Marrón oscuro
      textColor: Color(0xFFFFECB3),
      backgroundAsset: 'assets/images/bg_biblio.png', // <--- Imagen Fondo
      soundAsset: 'assets/audio/libreria.mp3', // Crema
      isFree: true,
    ),
    // 3. PLAYA (Cyan/Amarillo)
    AppTheme(
      id: 'beach',
      name: 'Playa Relax',
      primaryColor: Colors.cyanAccent,
      backgroundColor: Color(0xFF006064),
      backgroundAsset: 'assets/images/bg_beach.png', // <--- Imagen Fondo
      soundAsset: 'assets/audio/playa.mp3', // Cyan oscuro
      isFree: true,
    ),
    // 4. VOLCÁN (Rojo/Negro)
    AppTheme(
      id: 'volcano',
      name: 'Cueva de Lava',
      primaryColor: Colors.redAccent,
      backgroundColor: Color(0xFF210000),
      backgroundAsset: 'assets/images/bg_fire.png', // <--- Imagen Fondo
      soundAsset: 'assets/audio/robo.mp3', // Rojo muy oscuro
      priceCoins: 200, // Este cuesta monedas desbloquearlo
    ),
    AppTheme(
      id: 'cyber',
      name: 'Futuro Neón',
      primaryColor: Colors.greenAccent, // Botones y barras verde neón
      backgroundColor: Color(0xFF050505), // Negro casi puro
      textColor: Color(
        0xFFB9FBC0,
      ), // Texto verde muy pálido (tipo terminal antigua)
      backgroundAsset: 'assets/images/bg_robo.png',
      soundAsset:
          'assets/audio/robo.mp3', // Sonido sugerido: Synthesizer o ruido eléctrico
      priceCoins: 500, // Este tema cuesta monedas desbloquearlo
      isFree: false, // No es gratis
    ),
  ];

  // Helpers para buscar por ID
  static Pet getPetById(String id) {
    return pets.firstWhere((p) => p.id == id, orElse: () => pets[0]);
  }

  static AppTheme getThemeById(String id) {
    return themes.firstWhere((t) => t.id == id, orElse: () => themes[0]);
  }
}
