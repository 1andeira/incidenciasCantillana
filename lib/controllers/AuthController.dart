// ─────────────────────────────────────────
// lib/controllers/AuthController.dart
// ─────────────────────────────────────────

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cantillana_incidencias/models/userModel.dart';
import 'package:cantillana_incidencias/services/supabase_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthController extends GetxController {
  final _sb = SupabaseService.client;

  final status = AuthStatus.initial.obs;
  final currentUser = Rxn<UserModel>();
  final errorMessage = ''.obs;

  bool get isAuthenticated => status.value == AuthStatus.authenticated;
  bool get isLoading => status.value == AuthStatus.loading;
  UserModel? get user => currentUser.value;
  String get userId => currentUser.value?.id ?? '';

  @override
  void onInit() {
    super.onInit();
    _checkSession();
    _sb.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        currentUser(null);
        status(AuthStatus.unauthenticated);
      }
    });
  }

  Future<void> _checkSession() async {
    status(AuthStatus.loading);
    final session = _sb.auth.currentSession;
    if (session != null) {
      await _loadProfile(session.user.id, session.user.email);
    } else {
      status(AuthStatus.unauthenticated);
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────
  Future<bool> login(String credencial, String contrasena) async {
    try {
      status(AuthStatus.loading);
      errorMessage('');

      String email = credencial.trim();
      if (!credencial.contains('@')) {
        final row = await _sb
            .from('usuarios')
            .select('id')
            .eq('telefono', credencial.trim())
            .maybeSingle();
        if (row == null) throw Exception('Teléfono no registrado');
        final authUser = await _sb.auth.admin.getUserById(row['id'] as String);
        email = authUser.user?.email ?? '';
        if (email.isEmpty) throw Exception('No se pudo obtener el email');
      }

      final res = await _sb.auth.signInWithPassword(
        email: email,
        password: contrasena,
      );
      await _loadProfile(res.user!.id, res.user!.email);
      return true;
    } on AuthException catch (e) {
      errorMessage(_mapAuthError(e.message));
      status(AuthStatus.error);
      return false;
    } catch (e) {
      errorMessage(e.toString().replaceFirst('Exception: ', ''));
      status(AuthStatus.error);
      return false;
    }
  }

  // ── Registro ───────────────────────────────────────────────────────────
  Future<bool> register({
    required String nombre,
    required String contrasena,
    String? email,
    String? telefono,
  }) async {
    try {
      status(AuthStatus.loading);
      errorMessage('');

      final emailT = email?.trim();
      final telefonoT = telefono?.trim();

      if ((emailT == null || emailT.isEmpty) &&
          (telefonoT == null || telefonoT.isEmpty)) {
        throw Exception('Introduce al menos un email o un teléfono');
      }
      if (contrasena.length < 6) {
        throw Exception('La contraseña debe tener al menos 6 caracteres');
      }

      final authEmail = emailT?.isNotEmpty == true
          ? emailT!
          : '${telefonoT!.replaceAll(RegExp(r'\D'), '')}@cantillana.local';

      final res = await _sb.auth.signUp(
        email: authEmail,
        password: contrasena,
        data: {'nombre': nombre.trim()},
      );

      await _sb.from('usuarios').update({
        'nombre': nombre.trim(),
        if (telefonoT?.isNotEmpty == true) 'telefono': telefonoT,
      }).eq('id', res.user!.id);

      await _loadProfile(res.user!.id, res.user!.email);
      return true;
    } on AuthException catch (e) {
      errorMessage(_mapAuthError(e.message));
      status(AuthStatus.error);
      return false;
    } catch (e) {
      errorMessage(e.toString().replaceFirst('Exception: ', ''));
      status(AuthStatus.error);
      return false;
    }
  }

  // ── Actualizar perfil ──────────────────────────────────────────────────
  Future<void> updateProfile({required String nombre, String? telefono}) async {
    if (currentUser.value == null) return;
    status(AuthStatus.loading);
    await _sb.from('usuarios').update({
      'nombre': nombre.trim(),
      'telefono': telefono?.trim().isNotEmpty == true ? telefono!.trim() : null,
    }).eq('id', currentUser.value!.id);

    currentUser(currentUser.value!.copyWith(
      nombre: nombre.trim(),
      telefono: telefono?.trim().isNotEmpty == true ? telefono!.trim() : null,
    ));
    status(AuthStatus.authenticated);
  }

  // ── Logout ─────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _sb.auth.signOut();
    currentUser(null);
    status(AuthStatus.unauthenticated);
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  Future<void> _loadProfile(String uid, String? email) async {
    final row = await _sb.from('usuarios').select().eq('id', uid).single();
    currentUser(UserModel(
      id: uid,
      nombre: row['nombre'] as String,
      email: email,
      telefono: row['telefono'] as String?,
      fechaRegistro: DateTime.parse(row['fecha_registro'] as String),
    ));
    status(AuthStatus.authenticated);
  }

  String _mapAuthError(String msg) {
    if (msg.contains('Invalid login')) return 'Email o contraseña incorrectos';
    if (msg.contains('already registered'))
      return 'El email ya está registrado';
    if (msg.contains('Password should'))
      return 'La contraseña debe tener al menos 6 caracteres';
    return msg;
  }
}
