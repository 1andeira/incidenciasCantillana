// ─────────────────────────────────────────
// lib/router/app_router.dart
// ─────────────────────────────────────────

import 'package:flutter/foundation.dart';
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
import 'package:cantillana_incidencias/screens/email_confirmation_screen.dart';

abstract class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const profile = '/profile';
  static const createIncident = '/create-incident';
  static const incidentDetail = '/incident/:id';
  static const mapPicker = '/map-picker';
  static const loginCallback = '/login-callback';
}

class AppRouter {
  AppRouter._();

  static String _webStartPath = '/';

  static void captureWebPath() {
    if (kIsWeb) _webStartPath = Uri.base.path;
  }

  static final AuthController _auth = Get.find<AuthController>();

  static final GoRouter router = GoRouter(
    initialLocation: _webStartPath.isNotEmpty && _webStartPath != '/'
        ? _webStartPath
        : AppRoutes.home,
    refreshListenable: _AuthListenable(_auth),
    redirect: _guard,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _slide(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.loginCallback,
        name: 'loginCallback',
        pageBuilder: (context, state) =>
            _fade(state, const EmailConfirmationScreen()),
      ),
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
    final path = state.uri.path;
    final authStatus = _auth.status.value;

    // Esperar a que Supabase termine de inicializar / procesar el code
    if (authStatus == AuthStatus.initial || authStatus == AuthStatus.loading)
      return null;

    // Permitir el callback OAuth
    final isOnCallback = path == AppRoutes.loginCallback ||
        _webStartPath == AppRoutes.loginCallback;
    if (isOnCallback) return null;

    // Si hay ?code= en la URL (redirect de Google/email) dejar pasar
    // para que supabase_flutter lo procese en onAuthStateChange
    final hasCode = state.uri.queryParameters.containsKey('code');
    if (hasCode) return null;

    final isAuth = _auth.isAuthenticated;
    final isOnLogin = path == AppRoutes.login;

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
