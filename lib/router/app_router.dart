// ─────────────────────────────────────────
// lib/router/app_router.dart
// ─────────────────────────────────────────
//
// Integra GoRouter con AuthController para
// proteger rutas que requieren sesión.
// ─────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/screens/login_screen.dart';
import 'package:cantillana_incidencias/screens/citizen_home_screen.dart';
import 'package:cantillana_incidencias/screens/profile_screen.dart';
import 'package:cantillana_incidencias/screens/incident_detail_screen.dart';

// Rutas con nombre para evitar strings mágicos en el código
abstract class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const profile = '/profile';
  static const createIncident = '/create-incident';
  static const incidentDetail = '/incident/:id';
}

class AppRouter {
  AppRouter._();

  static final AuthController _auth = Get.put(AuthController());

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: _AuthListenable(_auth),
    redirect: _guard,
    routes: [
      // ── Login ──────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _slide(state, const LoginScreen()),
      ),

      // ── Home ───────────────────────────
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) =>
            _fade(state, const CitizenHomeScreen()),
        routes: [
          // Sub-ruta: perfil
          GoRoute(
            path: 'profile',
            name: 'profile',
            pageBuilder: (context, state) =>
                _slide(state, const ProfileScreen()),
          ),
          // Sub-ruta: nueva incidencia
          GoRoute(
            path: 'create-incident',
            name: 'createIncident',
            pageBuilder: (context, state) => _slide(
              state,
              const _PlaceholderScreen(title: 'Crear incidencia'),
            ),
          ),
          // Sub-ruta: detalle de incidencia
          GoRoute(
            path: 'incident/:id',
            name: 'incidentDetail',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return _slide(state, IncidentDetailScreen(incidentId: id));
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Ruta no encontrada: ${state.uri}'))),
  );

  // ── Guard: redirige si no hay sesión ───
  static String? _guard(BuildContext context, GoRouterState state) {
    final isAuth = _auth.isAuthenticated;
    final isOnLogin = state.uri.toString() == AppRoutes.login;

    if (!isAuth && !isOnLogin) return AppRoutes.login;
    if (isAuth && isOnLogin) return AppRoutes.home;
    return null; // sin redirección
  }

  // ── Transiciones ───────────────────────
  static CustomTransitionPage _fade(GoRouterState state, Widget child) =>
      CustomTransitionPage(
        key: state.pageKey,
        child: child,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      );

  static CustomTransitionPage _slide(GoRouterState state, Widget child) =>
      CustomTransitionPage(
        key: state.pageKey,
        child: child,
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
          child: child,
        ),
      );
}

// ─────────────────────────────────────────
// Listenable que dispara al cambiar AuthStatus
// ─────────────────────────────────────────

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(AuthController auth) {
    auth.status.listen((_) => notifyListeners());
  }
}

// ─────────────────────────────────────────
// Pantalla placeholder para rutas futuras
// ─────────────────────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Text(
        '$title\n(por implementar)',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey),
      ),
    ),
  );
}
