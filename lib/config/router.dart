// ─────────────────────────────────────────
// lib/config/router.dart
// Configuración de GoRouter para Cantillana
// ─────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/screens/login_screen.dart';
import 'package:cantillana_incidencias/screens/citizen_home_screen.dart';
import 'package:cantillana_incidencias/screens/incident_detail_screen.dart';
import 'package:cantillana_incidencias/screens/profile_screen.dart';
import 'package:cantillana_incidencias/screens/create_incident_screen.dart';

/// Rutas que requieren sesión activa.
/// El resto son públicas y accesibles en modo invitado.
const _rutasPrivadas = {'/create-incident', '/profile'};

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,

    // ── Redirección global (auth guard) ──────────────────────────────────
    redirect: (BuildContext context, GoRouterState state) {
      AuthController auth;
      try {
        auth = Get.find<AuthController>();
      } catch (_) {
        return null;
      }

      final isAuthenticated = auth.isAuthenticated;
      final isLoading = auth.isLoading;
      final location = state.matchedLocation;
      final isOnLogin = location == '/login';

      // Durante la carga inicial no redirigimos
      if (isLoading) return null;

      // Si ya está autenticado e intenta ir a /login → manda a home
      if (isAuthenticated && isOnLogin) return '/';

      // Solo protegemos las rutas privadas
      final esRutaPrivada = _rutasPrivadas.contains(location);
      if (esRutaPrivada && !isAuthenticated) return '/login';

      return null;
    },

    // ── Rutas ──────────────────────────────────────────────────────────────
    routes: [
      // -- Autenticación (pública) -----------------------------------------
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // -- Home (pública, accesible como invitado) -------------------------
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const CitizenHomeScreen(),
      ),

      // -- Detalle de incidencia (público) ---------------------------------
      GoRoute(
        path: '/incident/:id',
        name: 'incident-detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '0';
          return IncidentDetailScreen(incidentId: id);
        },
      ),

      // -- Crear nueva incidencia (PRIVADA → requiere login) ---------------
      GoRoute(
        path: '/create-incident',
        name: 'create-incident',
        builder: (context, state) => const CreateIncidentScreen(),
      ),

      // -- Perfil de usuario (PRIVADA → requiere login) --------------------
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],

    // ── Página de error 404 ───────────────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            const Text(
              'Página no encontrada',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
}
