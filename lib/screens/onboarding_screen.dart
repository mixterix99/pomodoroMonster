import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/timer_service.dart';
import '../data/game_data.dart';
import '../models/pet_model.dart';
import '../models/theme_model.dart';
import 'tutorial_screen.dart'; // <--- IMPORTANTE: Conexión con el Tutorial

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0; // 0: Elegir Mascota, 1: Elegir Tema
  String? _selectedPetId;
  String? _selectedThemeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // HEADER
              const SizedBox(height: 20),
              Text(
                _currentStep == 0 ? "Elige tu Compañero" : "Elige tu Ambiente",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _currentStep == 0
                    ? "Este será tu primer Focus Monster.\nLos demás tendrás que desbloquearlos."
                    : "Selecciona donde te gusta estudiar.\nPodrás cambiarlo después.",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // CONTENIDO PRINCIPAL (CAMBIA SEGÚN EL PASO)
              Expanded(
                child: _currentStep == 0
                    ? _buildPetSelector()
                    : _buildThemeSelector(),
              ),

              // BOTÓN DE CONTINUAR
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_currentStep == 0 && _selectedPetId == null) ||
                          (_currentStep == 1 && _selectedThemeId == null)
                      ? null // Deshabilitado si no ha seleccionado nada
                      : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentStep == 0 ? "SIGUIENTE" : "CONTINUAR",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Si estamos en el paso 1, vamos al paso 2
      setState(() {
        _currentStep = 1;
      });
    } else {
      // Si estamos en el paso 2, VAMOS AL TUTORIAL
      // Pasamos las elecciones del usuario al TutorialScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TutorialScreen(
            selectedPetId: _selectedPetId!,
            selectedThemeId: _selectedThemeId!,
          ),
        ),
      );
    }
  }

  // WIDGET SELECCIÓN DE MASCOTA (GRID)
  Widget _buildPetSelector() {
    return GridView.builder(
      itemCount: GameData.pets.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemBuilder: (context, index) {
        final pet = GameData.pets[index];
        final isSelected = _selectedPetId == pet.id;

        return GestureDetector(
          onTap: () => setState(() => _selectedPetId = pet.id),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.orangeAccent.withOpacity(0.2)
                  : Colors.white10,
              border: Border.all(
                color: isSelected ? Colors.orangeAccent : Colors.transparent,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    // Mostramos la versión adulta para que el usuario sepa a qué aspira
                    child: Image.asset(pet.assetAdult, fit: BoxFit.contain),
                  ),
                ),
                Text(
                  pet.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // WIDGET SELECCIÓN DE TEMA (LISTA VERTICAL)
  Widget _buildThemeSelector() {
    return ListView.builder(
      itemCount: GameData.themes.length,
      itemBuilder: (context, index) {
        final theme = GameData.themes[index];
        final isSelected = _selectedThemeId == theme.id;

        return GestureDetector(
          onTap: () => setState(() => _selectedThemeId = theme.id),
          child: Container(
            height: 100, // Altura fija para tarjeta
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.2),
              border: Border.all(
                color: isSelected ? theme.primaryColor : Colors.transparent,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(16),
              image: theme.backgroundAsset != null
                  ? DecorationImage(
                      image: AssetImage(theme.backgroundAsset!),
                      fit: BoxFit.cover,
                      // Filtro oscuro para que se lea el texto
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.6),
                        BlendMode.darken,
                      ),
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                theme.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
