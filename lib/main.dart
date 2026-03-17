// lib/main.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/router/app_router.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A5C9A), // Azul municipal
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A5C9A),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
