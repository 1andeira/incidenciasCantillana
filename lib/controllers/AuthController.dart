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

  /// Devuelve 0 si no hay sesión activa
  int get userId => currentUser.value?.id ?? 0;

  // ── Ciclo de vida ──────────────────────
  @override
  void onInit() {
    super.onInit();
    _checkSession();
  }

  Future<void> _checkSession() async {
    status(AuthStatus.loading);
    // En producción: leer token de SharedPreferences / FlutterSecureStorage
    await Future.delayed(const Duration(milliseconds: 800));
    status(AuthStatus.unauthenticated);
  }

  // ── Login ──────────────────────────────
  /// [credencial] puede ser email o teléfono según lo que ingrese el usuario
  Future<bool> login(String credencial, String contrasena) async {
    try {
      status(AuthStatus.loading);
      errorMessage('');

      // Simula llamada a API (SELECT * FROM usuarios WHERE email=$1 OR telefono=$1)
      await Future.delayed(const Duration(seconds: 1));

      if (contrasena.length < 6) {
        throw Exception('Contraseña incorrecta');
      }

      final esEmail = credencial.contains('@');

      final user = UserModel(
        id: credencial.hashCode.abs() % 100000,
        nombre: _nombreDesdeCredencial(credencial),
        email: esEmail ? credencial.trim() : null,
        telefono: esEmail ? null : credencial.trim(),
        fechaRegistro: DateTime(2024, 1, 15),
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
    required String nombre,
    required String contrasena,
    String? email,
    String? telefono,
  }) async {
    try {
      status(AuthStatus.loading);
      errorMessage('');

      // Simula INSERT INTO usuarios (nombre, email, telefono, contrasena)
      await Future.delayed(const Duration(seconds: 1));

      if (contrasena.length < 6) {
        throw Exception('La contraseña debe tener al menos 6 caracteres');
      }
      final emailTrimmed = email?.trim();
      final telefonoTrimmed = telefono?.trim();
      if ((emailTrimmed == null || emailTrimmed.isEmpty) &&
          (telefonoTrimmed == null || telefonoTrimmed.isEmpty)) {
        throw Exception('Introduce al menos un email o un teléfono');
      }

      final user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        nombre: nombre.trim(),
        email: emailTrimmed?.isNotEmpty == true ? emailTrimmed : null,
        telefono: telefonoTrimmed?.isNotEmpty == true ? telefonoTrimmed : null,
        fechaRegistro: DateTime.now(),
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
  Future<void> updateProfile({required String nombre, String? telefono}) async {
    if (currentUser.value == null) return;
    status(AuthStatus.loading);

    // Simula UPDATE usuarios SET nombre=$1, telefono=$2 WHERE id=$3
    await Future.delayed(const Duration(milliseconds: 600));
    currentUser(
      currentUser.value!.copyWith(
        nombre: nombre.trim(),
        telefono: telefono?.trim().isNotEmpty == true ? telefono!.trim() : null,
      ),
    );
    status(AuthStatus.authenticated);
  }

  // ── Logout ─────────────────────────────
  Future<void> logout() async {
    currentUser(null);
    status(AuthStatus.unauthenticated);
  }

  // ── Helpers ────────────────────────────
  String _nombreDesdeCredencial(String credencial) {
    if (!credencial.contains('@')) return credencial;
    final local = credencial.split('@').first;
    return local
        .split('.')
        .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }
}
