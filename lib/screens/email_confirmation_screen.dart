// ─────────────────────────────────────────
// lib/screens/email_confirmation_screen.dart
// ─────────────────────────────────────────

import 'package:cantillana_incidencias/config/CantillanaTheme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmailConfirmationScreen extends StatefulWidget {
  const EmailConfirmationScreen({super.key});

  @override
  State<EmailConfirmationScreen> createState() =>
      _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    // La confirmación ya ocurrió en Supabase antes de llegar aquí
    WidgetsBinding.instance.addPostFrameCallback((_) => _animCtrl.forward());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [CantillanaTheme.rojo, CantillanaTheme.rojoOscuro],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: _SuccessView(
                scaleAnim: _scaleAnim,
                fadeAnim: _fadeAnim,
                onGoToLogin: () => context.go('/login'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final Animation<double> scaleAnim;
  final Animation<double> fadeAnim;
  final VoidCallback onGoToLogin;

  const _SuccessView({
    required this.scaleAnim,
    required this.fadeAnim,
    required this.onGoToLogin,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: scaleAnim,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: CantillanaTheme.verdeOscuro,
                shape: BoxShape.circle,
                border: Border.all(color: CantillanaTheme.dorado, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: CantillanaTheme.dorado.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: CantillanaTheme.dorado,
                size: 56,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            '¡Cuenta verificada!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Tu correo ha sido confirmado.\nYa puedes iniciar sesión.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          FilledButton.icon(
            onPressed: onGoToLogin,
            icon: const Icon(Icons.login_rounded),
            label: const Text('Ir al inicio de sesión'),
            style: FilledButton.styleFrom(
              backgroundColor: CantillanaTheme.dorado,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
