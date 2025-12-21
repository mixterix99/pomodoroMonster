import 'package:flutter/material.dart';

class AppTheme {
  final String id;
  final String name;

  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;

  // NUEVAS PROPIEDADES
  final String? backgroundAsset; // Ruta de la imagen de fondo
  final String? soundAsset; // Ruta del sonido ambiental (MP3)

  final int priceCoins;
  final bool isFree;

  const AppTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.backgroundColor,
    this.textColor = Colors.white,
    this.backgroundAsset, // <--- Ahora lo usaremos
    this.soundAsset, // <--- Nuevo
    this.priceCoins = 0,
    this.isFree = false,
  });
}
