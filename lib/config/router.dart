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
import 'package:cantillana_incidencias/screens/admin_users_screen.dart';

/// Rutas que requieren sesión activa.
const _rutasPrivadas = {'/create-incident', '/profile'};

/// Rutas que además requieren rol admin.
const _rutasAdmin = {'/admin/users'};

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,

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

      if (isLoading) return null;

      if (isAuthenticated && isOnLogin) return '/';

      final esRutaPrivada = _rutasPrivadas.contains(location);
      if (esRutaPrivada && !isAuthenticated) return '/login';

      // Rutas exclusivas de admin → redirige a home si no es admin
      final esRutaAdmin = _rutasAdmin.contains(location);
      if (esRutaAdmin && (!isAuthenticated || !auth.isAdmin)) return '/';

      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const CitizenHomeScreen(),
      ),
      GoRoute(
        path: '/incident/:id',
        name: 'incident-detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '0';
          return IncidentDetailScreen(incidentId: id);
        },
      ),
      GoRoute(
        path: '/create-incident',
        name: 'create-incident',
        builder: (context, state) => const CreateIncidentScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      // ── Gestión de usuarios (solo admin) ────────────────────────────
      GoRoute(
        path: '/admin/users',
        name: 'admin-users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            const Text('Página no encontrada',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            Text(state.error?.toString() ?? '',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center),
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