// ─────────────────────────────────────────
// lib/screens/login_screen.dart
// ─────────────────────────────────────────

import 'package:cantillana_incidencias/config/CantillanaTheme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _authController = Get.find<AuthController>();

  final _nombreCtrl = TextEditingController();
  final _credencialCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isRegisterMode = false;
  bool _obscureContrasena = true;
  bool _pendingAdmin = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _credencialCtrl.addListener(_checkAdminCommand);
  }

  void _checkAdminCommand() {
    if (_credencialCtrl.text.trim() == '/admincantillana') {
      _credencialCtrl.removeListener(_checkAdminCommand);
      _credencialCtrl.clear();
      _credencialCtrl.addListener(_checkAdminCommand);

      setState(() => _pendingAdmin = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.shield_outlined,
                  color: CantillanaTheme.dorado, size: 16),
              SizedBox(width: 8),
              Text('Modo administrador activado para el próximo registro.'),
            ],
          ),
          backgroundColor: const Color(0xFF0E4023),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: CantillanaTheme.dorado, width: 1.5),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _credencialCtrl.removeListener(_checkAdminCommand);
    _nombreCtrl.dispose();
    _credencialCtrl.dispose();
    _telefonoCtrl.dispose();
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _pendingAdmin = false;
    });
    _animCtrl.forward(from: 0);
    _formKey.currentState?.reset();
    _authController.errorMessage('');
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final bool esAdmin = _pendingAdmin;

    bool ok;
    if (_isRegisterMode) {
      ok = await _authController.register(
        nombre: _nombreCtrl.text.trim(),
        contrasena: _contrasenaCtrl.text,
        email: _credencialCtrl.text.contains('@')
            ? _credencialCtrl.text.trim()
            : null,
        telefono:
            _telefonoCtrl.text.isNotEmpty ? _telefonoCtrl.text.trim() : null,
        isAdmin: esAdmin,
      );
      if (mounted) setState(() => _pendingAdmin = false);
    } else {
      ok = await _authController.login(
        _credencialCtrl.text.trim(),
        _contrasenaCtrl.text,
      );
    }

    if (ok && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [CantillanaTheme.rojo, CantillanaTheme.rojoOscuro],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            if (_authController.isPendingVerification) {
              return _VerificationPendingView(
                onBackToLogin: () {
                  _authController.status(AuthStatus.unauthenticated);
                  _authController.errorMessage('');
                  setState(() {
                    _isRegisterMode = false;
                    _pendingAdmin = false;
                  });
                  _formKey.currentState?.reset();
                },
              );
            }

            return Column(
              children: [
                // ── Cabecera ──────────────────────────────────────────
                Expanded(
                  flex: 2,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: CantillanaTheme.dorado, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/cantillan.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.location_city,
                                size: 45,
                                color: CantillanaTheme.rojo,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Cantillana',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Incidencias Municipales',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              letterSpacing: 0.5),
                        ),
                        if (_pendingAdmin) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: CantillanaTheme.dorado
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: CantillanaTheme.dorado, width: 1),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield_outlined,
                                    color: CantillanaTheme.dorado, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Modo Admin',
                                  style: TextStyle(
                                    color: CantillanaTheme.dorado,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Tarjeta formulario ────────────────────────────────
                Expanded(
                  flex: 5,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: CantillanaTheme.verdeOscuro,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(32)),
                          border: Border(
                            top: BorderSide(
                                color: CantillanaTheme.dorado, width: 4),
                          ),
                        ),
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isRegisterMode
                                      ? 'Crear cuenta'
                                      : 'Bienvenido',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: CantillanaTheme.dorado,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isRegisterMode
                                      ? 'Regístrate para reportar incidencias'
                                      : 'Inicia sesión con tu email o teléfono',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 20),
                                if (_isRegisterMode) ...[
                                  _CampoFormulario(
                                    controller: _nombreCtrl,
                                    label: 'Nombre completo',
                                    icon: Icons.person_outline,
                                    validator: (v) =>
                                        (v?.trim().isEmpty ?? true)
                                            ? 'Introduce tu nombre'
                                            : null,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                _CampoFormulario(
                                  controller: _credencialCtrl,
                                  label: _isRegisterMode
                                      ? 'Email'
                                      : 'Email o teléfono',
                                  icon: Icons.alternate_email,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v?.trim().isEmpty ?? true) {
                                      return _isRegisterMode
                                          ? 'Introduce tu email'
                                          : 'Introduce tu email o teléfono';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                if (_isRegisterMode) ...[
                                  _CampoFormulario(
                                    controller: _telefonoCtrl,
                                    label: 'Teléfono (opcional)',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                _CampoFormulario(
                                  controller: _contrasenaCtrl,
                                  label: 'Contraseña',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscureContrasena,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscureContrasena
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: CantillanaTheme.dorado,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureContrasena =
                                          !_obscureContrasena,
                                    ),
                                  ),
                                  validator: (v) => (v?.length ?? 0) < 6
                                      ? 'Mínimo 6 caracteres'
                                      : null,
                                ),
                                const SizedBox(height: 6),

                                // ── Mensaje de error ──────────────────
                                Obx(() {
                                  final msg =
                                      _authController.errorMessage.value;
                                  if (msg.isEmpty)
                                    return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: CantillanaTheme.rojo
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: CantillanaTheme.rojo,
                                            width: 1.5),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline,
                                              color: Colors.white, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(msg,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 20),

                                // ── Botón principal ───────────────────
                                Obx(
                                  () => SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: FilledButton(
                                      onPressed: _authController.isLoading
                                          ? null
                                          : _submit,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: CantillanaTheme.rojo,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          side: const BorderSide(
                                              color: CantillanaTheme.dorado,
                                              width: 2),
                                        ),
                                      ),
                                      child: _authController.isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              _isRegisterMode
                                                  ? 'Crear cuenta'
                                                  : 'Iniciar sesión',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 4),
                                Center(
                                  child: TextButton(
                                    onPressed: _toggleMode,
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13),
                                        children: [
                                          TextSpan(
                                            text: _isRegisterMode
                                                ? '¿Ya tienes cuenta? '
                                                : '¿No tienes cuenta? ',
                                          ),
                                          TextSpan(
                                            text: _isRegisterMode
                                                ? 'Inicia sesión'
                                                : 'Regístrate',
                                            style: const TextStyle(
                                              color: CantillanaTheme.dorado,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.person_outline,
                                        size: 18, color: Colors.white70),
                                    label: const Text(
                                      'Seguir como invitado',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: CantillanaTheme.dorado,
                                          width: 1.5),
                                      foregroundColor: Colors.white70,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => context.go('/'),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Pantalla de verificación pendiente
// ─────────────────────────────────────────

class _VerificationPendingView extends StatelessWidget {
  final VoidCallback onBackToLogin;
  const _VerificationPendingView({required this.onBackToLogin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: CantillanaTheme.dorado, width: 2.5),
                ),
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    'assets/cantillan.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.location_city,
                      size: 45,
                      color: CantillanaTheme.rojo,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Icon(Icons.mark_email_unread_outlined,
                size: 52, color: CantillanaTheme.dorado),
            const SizedBox(height: 20),
            const Text(
              'Verifica tu correo',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Te hemos enviado un enlace de verificación.\n'
              'Revisa tu bandeja de entrada y confirma tu cuenta para poder iniciar sesión.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            OutlinedButton.icon(
              icon:
                  const Icon(Icons.arrow_back, size: 16, color: Colors.white70),
              label: const Text('Volver al inicio de sesión',
                  style: TextStyle(color: Colors.white70)),
              style: OutlinedButton.styleFrom(
                side:
                    const BorderSide(color: CantillanaTheme.dorado, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: onBackToLogin,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Campo de formulario reutilizable
// ─────────────────────────────────────────

class _CampoFormulario extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _CampoFormulario({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: CantillanaTheme.dorado, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF1B5E20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CantillanaTheme.dorado, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CantillanaTheme.dorado, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CantillanaTheme.dorado, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CantillanaTheme.rojo, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CantillanaTheme.rojo, width: 3),
        ),
        errorStyle: const TextStyle(color: Colors.white),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
