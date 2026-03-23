// lib/main.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/router/app_router.dart';
import 'package:cantillana_incidencias/config/CantillanaTheme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Registrar AuthController globalmente antes de arrancar
  Get.put(AuthController(), permanent: true);
  runApp(const CantillanaApp());
}

class CantillanaApp extends StatelessWidget {
  const CantillanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cantillana Incidencias',
      debugShowCheckedModeBanner: false,

      // ── TEMA CLARO: Rojo del escudo con fondos verde oscuro ───────────────────
      theme: CantillanaTheme.lightTheme,

      // ── TEMA OSCURO: Adaptación oscura con rojo ───────────────────────────
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: CantillanaTheme.rojo,
          brightness: Brightness.dark,
        ),
      ),

      // ── OPCIÓN ALTERNATIVA: Descomentar para usar tema DORADO ─────────────
      // theme: CantillanaTheme.lightThemeDorado,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
