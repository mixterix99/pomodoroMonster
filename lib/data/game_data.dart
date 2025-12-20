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
      priceCoins: 0,
    ),
    // 2. FUEGO (Costoso en monedas)
    Pet(
      id: 'inferno',
      name: 'Inferno',
      description: 'Nacido en el volcán de la procrastinación.',
      assetEgg: 'assets/images/pet_fire_egg.png',
      assetBaby: 'assets/images/pet_fire_baby.png',
      assetAdult: 'assets/images/pet_fire_adult.png',
      priceCoins: 500, // 500 minutos de estudio
    ),
    // 3. AGUA (Medio)
    Pet(
      id: 'aqua',
      name: 'Bloop',
      description: 'Te mantiene fresco y concentrado.',
      assetEgg: 'assets/images/pet_water_egg.png',
      assetBaby: 'assets/images/pet_water_baby.png',
      assetAdult: 'assets/images/pet_water_adult.png',
      priceCoins: 300,
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
      isPremium: true, // $$$
    ),
  ];

  // --- LISTA DE TEMAS ---
  static const List<AppTheme> themes = [
    // 1. ESPACIO (Default)
    AppTheme(
      id: 'space',
      name: 'Espacio Profundo',
      primaryColor: Colors.orangeAccent,
      backgroundColor: Color(0xFF1A1A2E), // Azul oscuro
      isFree: true,
    ),
    // 2. BIBLIOTECA (Café/Beige)
    AppTheme(
      id: 'library',
      name: 'Biblioteca Antigua',
      primaryColor: Color(0xFF8D6E63), // Marrón suave
      backgroundColor: Color(0xFF3E2723), // Marrón oscuro
      textColor: Color(0xFFFFECB3), // Crema
      isFree: true,
    ),
    // 3. PLAYA (Cyan/Amarillo)
    AppTheme(
      id: 'beach',
      name: 'Playa Relax',
      primaryColor: Colors.cyanAccent,
      backgroundColor: Color(0xFF006064), // Cyan oscuro
      isFree: true,
    ),
    // 4. VOLCÁN (Rojo/Negro)
    AppTheme(
      id: 'volcano',
      name: 'Cueva de Lava',
      primaryColor: Colors.redAccent,
      backgroundColor: Color(0xFF210000), // Rojo muy oscuro
      priceCoins: 200, // Este cuesta monedas desbloquearlo
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
