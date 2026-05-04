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

  // ── Controladores ──────────────────────
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

    // Detecta el comando de admin oculto
    _credencialCtrl.addListener(_checkAdminCommand);
  }

void _checkAdminCommand() {
    if (_credencialCtrl.text.trim() == '/admincantillana') {
      _credencialCtrl.clear();
      setState(() => _pendingAdmin = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.shield_outlined, color: CantillanaTheme.dorado, size: 16),
              SizedBox(width: 8),
              Text('Modo administrador activado para el próximo registro.'),
            ],
          ),
          backgroundColor: const Color(0xFF0E4023),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: CantillanaTheme.dorado, width: 1.5),
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
    setState(() => _isRegisterMode = !_isRegisterMode);
    _animCtrl.forward(from: 0);
    _formKey.currentState?.reset();
    _authController.errorMessage('');
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    bool ok;
if (_isRegisterMode) {
      ok = await _authController.register(
        nombre: _nombreCtrl.text,
        contrasena: _contrasenaCtrl.text,
        email: _credencialCtrl.text.contains('@') ? _credencialCtrl.text : null,
        telefono: _telefonoCtrl.text.isNotEmpty ? _telefonoCtrl.text : null,
        isAdmin: _pendingAdmin,
      );
      // Consumir el flag tras usarlo, sea cual sea el resultado
      setState(() => _pendingAdmin = false);
    } else {
      ok = await _authController.login(
        _credencialCtrl.text,
        _contrasenaCtrl.text,
      );
    }

    if (ok && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── Clave del fix: el Scaffold NO se redimensiona cuando sube el teclado.
      // El SingleChildScrollView de la tarjeta ya gestiona el scroll interno.
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [CantillanaTheme.rojo, CantillanaTheme.rojoOscuro],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Cabecera con escudo ───────────────
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
                            color: CantillanaTheme.dorado,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/cantillan.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
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
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Tarjeta del formulario ─────────────
              Expanded(
                flex: 5,
                child: SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: CantillanaTheme.verdeOscuro,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: CantillanaTheme.dorado,
                            width: 4,
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        // El scroll se activa automáticamente cuando el
                        // teclado reduce el espacio disponible
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isRegisterMode ? 'Crear cuenta' : 'Bienvenido',
                                style: TextStyle(
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
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Nombre (solo registro)
                              if (_isRegisterMode) ...[
                                _CampoFormulario(
                                  controller: _nombreCtrl,
                                  label: 'Nombre completo',
                                  icon: Icons.person_outline,
                                  validator: (v) => (v?.trim().isEmpty ?? true)
                                      ? 'Introduce tu nombre'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Email o teléfono
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

                              // Teléfono (solo registro, opcional)
                              if (_isRegisterMode) ...[
                                _CampoFormulario(
                                  controller: _telefonoCtrl,
                                  label: 'Teléfono (opcional)',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Contraseña
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

                              // Mensaje de error
                              Obx(() {
                                final msg = _authController.errorMessage.value;
                                if (msg.isEmpty) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          CantillanaTheme.rojo.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: CantillanaTheme.rojo,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            msg,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),

                              const SizedBox(height: 20),

                              // Botón principal
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
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: CantillanaTheme.dorado,
                                          width: 2,
                                        ),
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

                              const SizedBox(height: 12),

                              // Toggle login / registro
                              Center(
                                child: TextButton(
                                  onPressed: _toggleMode,
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
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
                                          style: TextStyle(
                                            color: CantillanaTheme.dorado,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // ── Botón invitado ──────────────────────────
                              const SizedBox(height: 18),
                              Center(
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.person_outline,
                                    size: 18,
                                    color: Colors.white70,
                                  ),
                                  label: const Text(
                                    'Seguir como invitado',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: CantillanaTheme.dorado,
                                      width: 1.5,
                                    ),
                                    foregroundColor: Colors.white70,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => context.go('/'),
                                ),
                              ),

                              // Padding extra al fondo para que el scroll
                              // deje siempre el último elemento visible
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
          ),
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
          borderSide: BorderSide(color: CantillanaTheme.dorado, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: CantillanaTheme.dorado, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: CantillanaTheme.dorado, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: CantillanaTheme.rojo, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: CantillanaTheme.rojo, width: 3),
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
