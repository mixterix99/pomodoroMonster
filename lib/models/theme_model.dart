import 'package:flutter/material.dart';

class AppTheme {
  final String id;
  final String name;

  // Propiedades Visuales
  final Color primaryColor; // Color del Timer y Botones
  final Color backgroundColor; // Color de fondo
  final Color textColor; // Color de fuentes
  final String?
  backgroundAsset; // Imagen de fondo (opcional, si es null usa color)
  final String fontName; // Nombre de la fuente (ej: 'Roboto', 'Pixel')

  // Economía
  final int priceCoins;
  final bool isFree; // Si viene desbloqueado por defecto

  const AppTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.backgroundColor,
    this.textColor = Colors.white,
    this.backgroundAsset,
    this.fontName = 'Roboto', // Por defecto
    this.priceCoins = 0,
    this.isFree = false,
  });
}
