// ─────────────────────────────────────────
// main.dart
// Punto de entrada de Cantillana Incidencias
// ─────────────────────────────────────────

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:cantillana_incidencias/config/CantillanaTheme.dart';
import 'package:cantillana_incidencias/config/router.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/router/app_router.dart';
import 'package:cantillana_incidencias/services/supabase_service.dart';
import 'package:cantillana_incidencias/utils/web_maps_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Capturar la ruta ANTES de que Supabase procese el ?code= y cambie la URL
  if (kIsWeb) AppRouter.captureWebPath();

  // Silencia los avisos visuales de overflow (rayas amarillas/negras)
  // sin suprimir el resto de errores de Flutter.
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    FlutterError.presentError(details);
  };

  // Fuerza orientación vertical (no aplica en web, es un no-op seguro)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Estilo de la barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Inicializa Supabase (también carga env.json con la API key de Maps)
  await SupabaseService.init();

  // Inyecta el script de Google Maps JS en web antes de arrancar la UI.
  // En móvil/escritorio es un no-op (web_maps_loader_stub.dart).
  if (kIsWeb) {
    await injectGoogleMapsScript(SupabaseService.googleMapsApiKey);
  }

  // Registro del AuthController de forma permanente
  Get.put(AuthController(), permanent: true);

  // Ejecuta la app
  runApp(const CantillanaApp());
}

class CantillanaApp extends StatelessWidget {
  const CantillanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // El router se construye UNA VEZ y se reutiliza
    final router = buildRouter();

    return MaterialApp.router(
      title: 'Cantillana Incidencias',
      debugShowCheckedModeBanner: false,

      // ── Tema ──────────────────────────────
      theme: CantillanaTheme.themeData,
      darkTheme: CantillanaTheme.themeData,
      themeMode: ThemeMode.dark,

      // ── Router (GoRouter + GetX) ───────────
      routerConfig: router,
    );
  }
}
