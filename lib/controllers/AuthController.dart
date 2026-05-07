// ─────────────────────────────────────────
// lib/controllers/AuthController.dart
// ─────────────────────────────────────────

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cantillana_incidencias/models/userModel.dart';
import 'package:cantillana_incidencias/services/supabase_service.dart';

const _kWebClientId =
    '507662292738-5g7u0lt758e2mffnfio971fhdv3jd3tp.apps.googleusercontent.com';
const _kIosClientId = '';

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
    debugPrint('🔵 AuthController.onInit');
    _checkSession();

    _sb.auth.onAuthStateChange.listen((data) async {
      debugPrint(
          '🔔 onAuthStateChange → event=${data.event}  session=${data.session?.user.id}');
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
    debugPrint('🔵 _checkSession start');
    status(AuthStatus.loading);
    final session = _sb.auth.currentSession;
    debugPrint('🔵 _checkSession → session=${session?.user.id}');
    if (session != null) {
      await _loadProfile(session.user.id, session.user.email);
    } else {
      status(AuthStatus.unauthenticated);
      debugPrint('🔵 _checkSession → unauthenticated (no session)');
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

  // ── Login con Google ───────────────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    try {
      debugPrint('🟢 signInWithGoogle start — kIsWeb=$kIsWeb');
      status(AuthStatus.loading);
      errorMessage('');

      if (kIsWeb) {
        await _sb.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: '${Uri.base.origin}/',
        );
        return;
      }

      final googleSignIn = GoogleSignIn(
        clientId: _kIosClientId.isNotEmpty ? _kIosClientId : null,
        serverClientId: _kWebClientId,
      );

      debugPrint('🟢 googleSignIn.signIn() llamando...');
      final googleUser = await googleSignIn.signIn();
      debugPrint('🟢 googleUser=$googleUser');

      if (googleUser == null) {
        status(AuthStatus.unauthenticated);
        debugPrint('🟢 Usuario canceló Google Sign-In');
        return;
      }

      final googleAuth = await googleUser.authentication;
      debugPrint('🟢 idToken=${googleAuth.idToken != null ? "OK" : "NULL"}');
      debugPrint(
          '🟢 accessToken=${googleAuth.accessToken != null ? "OK" : "NULL"}');

      if (googleAuth.idToken == null) {
        throw Exception('No se obtuvo el ID token de Google.');
      }

      debugPrint('🟢 Llamando signInWithIdToken...');
      await _sb.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      debugPrint('🟢 signInWithIdToken completado');
    } on AuthException catch (e) {
      debugPrint('🔴 signInWithGoogle AuthException: ${e.message}');
      errorMessage(_mapAuthError(e.message));
      status(AuthStatus.error);
    } catch (e) {
      debugPrint('🔴 signInWithGoogle error: $e');
      errorMessage('No se pudo iniciar sesión con Google: $e');
      status(AuthStatus.error);
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
        emailRedirectTo: 'https://alumno26.fpcantillana.org/verificado.html',
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

      // El trigger ya crea el perfil; upsert como seguro por si acaso
      await _sb.from('usuarios').upsert(
        {
          'id': res.user!.id,
          'nombre': nombre.trim(),
          if (telefonoT?.isNotEmpty == true) 'telefono': telefonoT,
          'rol': isAdmin ? 'admin' : 'usuario',
        },
        onConflict: 'id',
        ignoreDuplicates: false,
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

  // ── Cambiar rol ────────────────────────────────────────────────────────
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
    debugPrint('🔵 _loadProfile uid=$uid email=$email');
    try {
      final row =
          await _sb.from('usuarios').select().eq('id', uid).maybeSingle();

      debugPrint('🔵 _loadProfile row=${row != null ? "FOUND" : "NULL"}');

      if (row != null) {
        currentUser(UserModel(
          id: uid,
          nombre: row['nombre'] as String,
          email: email,
          telefono: row['telefono'] as String?,
          fechaRegistro: DateTime.parse(row['fecha_registro'] as String),
          rol: UserModel.parseRol(row['rol'] as String?),
        ));
        debugPrint('🔵 _loadProfile → usuario cargado: ${row['nombre']}');
      } else {
        // El trigger on_auth_user_created puede estar en carrera con esta
        // llamada. Esperamos brevemente y reintentamos antes de crear manualmente.
        debugPrint('🔵 _loadProfile → perfil no encontrado, reintentando...');
        await Future.delayed(const Duration(milliseconds: 800));

        final retryRow =
            await _sb.from('usuarios').select().eq('id', uid).maybeSingle();

        Map<String, dynamic> newRow;

        if (retryRow != null) {
          debugPrint('🔵 _loadProfile → perfil encontrado en reintento');
          newRow = retryRow;
        } else {
          debugPrint('🔵 _loadProfile → creando perfil manualmente...');
          final authUser = _sb.auth.currentUser;
          final nombre = authUser?.userMetadata?['full_name'] as String? ??
              authUser?.userMetadata?['name'] as String? ??
              email?.split('@').first ??
              'Usuario';

          debugPrint('🔵 _loadProfile → nombre inferido: $nombre');

          // upsert con ignoreDuplicates por si el trigger llega justo a la vez
          await _sb.from('usuarios').upsert(
            {
              'id': uid,
              'nombre': nombre,
              'rol': 'usuario',
            },
            onConflict: 'id',
            ignoreDuplicates: true,
          );
          debugPrint('🔵 _loadProfile → upsert OK');

          newRow = await _sb.from('usuarios').select().eq('id', uid).single();
        }

        debugPrint('🔵 _loadProfile → newRow cargado: ${newRow['nombre']}');

        currentUser(UserModel(
          id: uid,
          nombre: newRow['nombre'] as String,
          email: email,
          telefono: newRow['telefono'] as String?,
          fechaRegistro: DateTime.parse(newRow['fecha_registro'] as String),
          rol: UserModel.parseRol(newRow['rol'] as String?),
        ));
      }

      status(AuthStatus.authenticated);
      debugPrint('✅ _loadProfile → status = authenticated');
    } catch (e, stack) {
      debugPrint('🔴 _loadProfile ERROR: $e');
      debugPrint('🔴 _loadProfile STACK: $stack');
      errorMessage('Error de perfil: ${e.toString()}');
      status(AuthStatus.error);
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
