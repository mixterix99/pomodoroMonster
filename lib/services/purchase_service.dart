import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PurchaseService {
  // ⚠️ REEMPLAZA ESTO CON TU API KEY PÚBLICA DE REVENUECAT (La que empieza con 'goog_')
  String get _apiKey => dotenv.env['REVENUECAT_API_KEY'] ?? '';

  Future<void> initialize() async {
    // Validación de seguridad por si se te olvida el .env
    if (_apiKey.isEmpty) {
      print(
        "⚠️ ERROR CRÍTICO: No se encontró la API Key de RevenueCat en el archivo .env",
      );
      return;
    }

    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_apiKey); // <--- Aquí se usa
      await Purchases.configure(configuration);
    }
  }

  // Obtener los paquetes de la "Vitrina" (Offering 'default')
  Future<List<Package>> fetchOffers() async {
    try {
      Offerings offerings = await Purchases.getOfferings();

      // Buscamos el offering "default" que creaste en el dashboard
      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        return offerings.current!.availablePackages;
      } else {
        print("⚠️ No se encontró el Offering 'default' o está vacío.");
      }
    } catch (e) {
      print("❌ Error trayendo ofertas de RevenueCat: $e");
    }
    return [];
  }

  // Procesar la compra
  Future<bool> purchasePackage(Package package) async {
    try {
      // Intentamos comprar
      await Purchases.purchase(PurchaseParams.package(package));

      // Si el código llega aquí sin lanzar error, la transacción fue exitosa.
      // Para consumibles (monedas), no necesitamos verificar 'entitlements.active',
      // el simple hecho de no haber error significa que pagó.
      return true;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        print("❌ Error en compra: ${e.message}");
      } else {
        print("User canceló la compra.");
      }
      return false;
    } catch (e) {
      print("❌ Error genérico: $e");
      return false;
    }
  }
}
