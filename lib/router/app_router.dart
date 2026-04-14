// ─────────────────────────────────────────
// lib/router/app_router.dart
// ─────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/screens/login_screen.dart';
import 'package:cantillana_incidencias/screens/citizen_home_screen.dart';
import 'package:cantillana_incidencias/screens/profile_screen.dart';
import 'package:cantillana_incidencias/screens/incident_detail_screen.dart';
import 'package:cantillana_incidencias/screens/create_incident_screen.dart';
import 'package:cantillana_incidencias/screens/map_picker_screen.dart';

abstract class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const profile = '/profile';
  static const createIncident = '/create-incident';
  static const incidentDetail = '/incident/:id';
  static const mapPicker = '/map-picker';
}

class AppRouter {
  AppRouter._();

  // AuthController ya fue registrado en main.dart con Get.put
  static final AuthController _auth = Get.find<AuthController>();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: _AuthListenable(_auth),
    redirect: _guard,
    routes: [
      // ── Login ──────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _slide(state, const LoginScreen()),
      ),

      // ── Home ───────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) =>
            _fade(state, const CitizenHomeScreen()),
        routes: [
          GoRoute(
            path: 'profile',
            name: 'profile',
            pageBuilder: (context, state) =>
                _slide(state, const ProfileScreen()),
          ),
          GoRoute(
            path: 'create-incident',
            name: 'createIncident',
            pageBuilder: (context, state) =>
                _slide(state, const CreateIncidentScreen()),
          ),
          GoRoute(
            path: 'incident/:id',
            name: 'incidentDetail',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return _slide(state, IncidentDetailScreen(incidentId: id));
            },
          ),
          GoRoute(
            path: 'map-picker',
            name: 'mapPicker',
            pageBuilder: (context, state) =>
                _slide(state, const MapPickerScreen()),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Ruta no encontrada: ${state.uri}'))),
  );

  static String? _guard(BuildContext context, GoRouterState state) {
    final isAuth = _auth.isAuthenticated;
    final isOnLogin = state.uri.toString() == AppRoutes.login;
    if (!isAuth && !isOnLogin) return AppRoutes.login;
    if (isAuth && isOnLogin) return AppRoutes.home;
    return null;
  }

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
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
          child: child,
        ),
      );
}

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(AuthController auth) {
    auth.status.listen((_) => notifyListeners());
  }
}
