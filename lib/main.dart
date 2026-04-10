// ─────────────────────────────────────────
// main.dart
// Punto de entrada de Cantillana Incidencias
// ─────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:cantillana_incidencias/config/CantillanaTheme.dart';
import 'package:cantillana_incidencias/config/router.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Silencia los avisos visuales de overflow (rayas amarillas/negras)
  // sin suprimir el resto de errores de Flutter.
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    FlutterError.presentError(details);
  };

  // Fuerza orientación vertical
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

  // Registro del AuthController de forma permanente
  // (IncidentController se registra en CitizenHomeScreen via Get.put)
  Get.put(AuthController(), permanent: true);

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

      // ── Localización ──────────────────────
      // Asegúrate de tener `intl` y el delegate de localización si usas
      // DateFormat con locale 'es'. En caso contrario quita este bloque.
      // localizationsDelegates: const [
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      //   GlobalCupertinoLocalizations.delegate,
      // ],
      // supportedLocales: const [Locale('es', 'ES')],
    );
  }
}
