// ─────────────────────────────────────────
// lib/controllers/AuthController.dart
// ─────────────────────────────────────────

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cantillana_incidencias/models/userModel.dart';
import 'package:cantillana_incidencias/services/supabase_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  pendingVerification,
  error,
}

class AuthController extends GetxController {
  final _sb = SupabaseService.client;

  final status = AuthStatus.initial.obs;
  final currentUser = Rxn<UserModel>();
  final errorMessage = ''.obs;

  bool get isAuthenticated => status.value == AuthStatus.authenticated;
  bool get isLoading => status.value == AuthStatus.loading;
  bool get isPendingVerification =>
      status.value == AuthStatus.pendingVerification;
  UserModel? get user => currentUser.value;
  String get userId => currentUser.value?.id ?? '';
  bool get isAdmin => currentUser.value?.isAdmin ?? false;

  @override
  void onInit() {
    super.onInit();
    _checkSession();

    _sb.auth.onAuthStateChange.listen((data) async {
      switch (data.event) {
        case AuthChangeEvent.signedIn:
          if (data.session != null) {
            await _loadProfile(
              data.session!.user.id,
              data.session!.user.email,
            );
          }
          break;

        case AuthChangeEvent.tokenRefreshed:
          if (data.session != null && !isAuthenticated) {
            await _loadProfile(
              data.session!.user.id,
              data.session!.user.email,
            );
          }
          break;

        case AuthChangeEvent.signedOut:
          currentUser(null);
          status(AuthStatus.unauthenticated);
          break;

        case AuthChangeEvent.userUpdated:
          if (data.session != null) {
            await _loadProfile(
              data.session!.user.id,
              data.session!.user.email,
            );
          }
          break;

        default:
          break;
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
            .select('email')
            .eq('telefono', credencial.trim())
            .maybeSingle();

        if (row == null || row['email'] == null) {
          throw Exception('Teléfono no registrado o sin email asociado');
        }
        email = row['email'] as String;
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
    bool isAdmin = false,
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

      final authEmail = emailT?.isNotEmpty == true
          ? emailT!
          : '${telefonoT!.replaceAll(RegExp(r'\D'), '')}@cantillana.local';

      final res = await _sb.auth.signUp(
        email: authEmail,
        password: contrasena,
        emailRedirectTo:
            'https://alumno26.fpcantillana.org/verificado.html',
        data: {
          'nombre': nombre.trim(),
          if (telefonoT?.isNotEmpty == true) 'telefono': telefonoT,
          if (isAdmin) 'rol': 'admin',
        },
      );

      if (res.user == null) throw Exception('No se pudo crear el usuario');

      if (res.session == null) {
        status(AuthStatus.pendingVerification);
        errorMessage('');
        return false;
      }

      await _sb.from('usuarios').upsert({
        'id': res.user!.id,
        'nombre': nombre.trim(),
        if (telefonoT?.isNotEmpty == true) 'telefono': telefonoT,
        'rol': isAdmin ? 'admin' : 'usuario',
      });

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

  // ── Cambiar rol (solo desde panel admin) ──────────────────────────────
  Future<void> setRol(String uid, String rol) async {
    await _sb.from('usuarios').update({'rol': rol}).eq('id', uid);
    if (uid == userId) {
      currentUser(currentUser.value!.copyWith(
        rol: UserModel.parseRol(rol),
      ));
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _sb.auth.signOut();
    currentUser(null);
    status(AuthStatus.unauthenticated);
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  Future<void> _loadProfile(String uid, String? email) async {
    try {
      final row = await _sb.from('usuarios').select().eq('id', uid).single();

      currentUser(UserModel(
        id: uid,
        nombre: row['nombre'] as String,
        email: email,
        telefono: row['telefono'] as String?,
        fechaRegistro: DateTime.parse(row['fecha_registro'] as String),
        rol: UserModel.parseRol(row['rol'] as String?),
      ));
      status(AuthStatus.authenticated);
    } catch (_) {
      status(AuthStatus.unauthenticated);
    }
  }

  String _mapAuthError(String msg) {
    if (msg.contains('Invalid login')) return 'Email o contraseña incorrectos';
    if (msg.contains('already registered'))
      return 'El email ya está registrado';
    if (msg.contains('Password should'))
      return 'La contraseña debe tener al menos 6 caracteres';
    if (msg.contains('Email not confirmed'))
      return 'Confirma tu email antes de iniciar sesión';
    return msg;
  }
}
