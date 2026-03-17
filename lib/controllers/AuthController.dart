// ─────────────────────────────────────────
// lib/controllers/AuthController.dart
// ─────────────────────────────────────────

import 'package:get/get.dart';
import 'package:cantillana_incidencias/models/userModel.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthController extends GetxController {
  // ── Estado ─────────────────────────────
  final status = AuthStatus.initial.obs;
  final currentUser = Rxn<UserModel>();
  final errorMessage = ''.obs;

  // ── Getters helpers ────────────────────
  bool get isAuthenticated => status.value == AuthStatus.authenticated;
  bool get isLoading => status.value == AuthStatus.loading;
  UserModel? get user => currentUser.value;
  String get userId => currentUser.value?.id ?? '';

  // ── Ciclo de vida ──────────────────────
  @override
  void onInit() {
    super.onInit();
    _checkSession();
  }

  // ── Comprobación de sesión guardada ────
  Future<void> _checkSession() async {
    status(AuthStatus.loading);
    // En una app real leerías un token guardado (SharedPreferences / FlutterSecureStorage)
    await Future.delayed(const Duration(milliseconds: 800));
    status(AuthStatus.unauthenticated);
  }

  // ── Login ──────────────────────────────
  Future<bool> login(String email, String password) async {
    try {
      status(AuthStatus.loading);
      errorMessage('');

      // Simula llamada a API (reemplaza con tu lógica real)
      await Future.delayed(const Duration(seconds: 1));

      // Validación mock: cualquier email con password >= 6 chars
      if (password.length < 6) {
        throw Exception('Contraseña incorrecta');
      }

      // Usuario simulado
      final user = UserModel(
        id: 'u_${email.hashCode.abs()}',
        name: _nameFromEmail(email),
        email: email,
        phone: '+34 600 000 000',
        role: email.contains('admin') ? UserRole.admin : UserRole.citizen,
        createdAt: DateTime(2024, 1, 15),
      );

      currentUser(user);
      status(AuthStatus.authenticated);
      return true;
    } catch (e) {
      errorMessage(e.toString().replaceFirst('Exception: ', ''));
      status(AuthStatus.error);
      return false;
    }
  }

  // ── Registro ───────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      status(AuthStatus.loading);
      errorMessage('');

      await Future.delayed(const Duration(seconds: 1));

      if (password.length < 6) {
        throw Exception('La contraseña debe tener al menos 6 caracteres');
      }

      final user = UserModel(
        id: 'u_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        email: email.trim(),
        phone: phone?.trim(),
        role: UserRole.citizen,
        createdAt: DateTime.now(),
      );

      currentUser(user);
      status(AuthStatus.authenticated);
      return true;
    } catch (e) {
      errorMessage(e.toString().replaceFirst('Exception: ', ''));
      status(AuthStatus.error);
      return false;
    }
  }

  // ── Actualizar perfil ──────────────────
  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    if (currentUser.value == null) return;
    status(AuthStatus.loading);
    await Future.delayed(const Duration(milliseconds: 600));
    currentUser(
      currentUser.value!.copyWith(name: name.trim(), phone: phone.trim()),
    );
    status(AuthStatus.authenticated);
  }

  // ── Logout ─────────────────────────────
  Future<void> logout() async {
    // Aquí limpiarías tokens guardados
    currentUser(null);
    status(AuthStatus.unauthenticated);
  }

  // ── Helpers ────────────────────────────
  String _nameFromEmail(String email) {
    final local = email.split('@').first;
    return local
        .split('.')
        .map((p) {
          if (p.isEmpty) return p;
          return p[0].toUpperCase() + p.substring(1);
        })
        .join(' ');
  }
}
