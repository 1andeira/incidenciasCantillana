// ─────────────────────────────────────────
// lib/widgets/cantillana_loading.dart
// Widget de carga con el escudo de Cantillana
// ─────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cantillana_incidencias/config/CantillanaTheme.dart';

// ── Widget principal (pantalla completa) ─────────────────────────────────────
class CantillanaLoading extends StatelessWidget {
  final String? message;
  const CantillanaLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: _CantillanaLoadingCore(message: message, size: 96));
  }
}

// ── Widget inline (dentro de listas / columnas) ──────────────────────────────
class CantillanaLoadingInline extends StatelessWidget {
  final String? message;
  const CantillanaLoadingInline({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(child: _CantillanaLoadingCore(message: message, size: 72)),
    );
  }
}

// ── Core animado ─────────────────────────────────────────────────────────────
class _CantillanaLoadingCore extends StatefulWidget {
  final String? message;
  final double size;
  const _CantillanaLoadingCore({this.message, required this.size});

  @override
  State<_CantillanaLoadingCore> createState() => _CantillanaLoadingCoreState();
}

class _CantillanaLoadingCoreState extends State<_CantillanaLoadingCore>
    with TickerProviderStateMixin {
  // ── Spin: translate → rotate → translate back ──────────────────────────
  late final AnimationController _spinCtrl;
  late final Animation<double> _spinAnim;

  // ── Pulso del anillo dorado ─────────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // ── Orbita de las partículas ────────────────────────────────────────────
  late final AnimationController _orbitCtrl;

  // ── Fade in inicial ─────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _spinAnim = CurvedAnimation(parent: _spinCtrl, curve: Curves.linear);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    _orbitCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final ringOuter = s * 1.55;
    final ringInner = s * 1.22;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: ringOuter,
            height: ringOuter,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Anillo exterior pulsante ──────────────────────────────
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Container(
                    width: ringOuter,
                    height: ringOuter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CantillanaTheme.dorado
                            .withOpacity(0.15 + 0.25 * _pulseAnim.value),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                // ── Anillo interior pulsante (desfasado) ──────────────────
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Container(
                    width: ringInner,
                    height: ringInner,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CantillanaTheme.dorado
                            .withOpacity(0.3 - 0.2 * _pulseAnim.value),
                        width: 1,
                      ),
                    ),
                  ),
                ),

                // ── Partículas en órbita ──────────────────────────────────
                AnimatedBuilder(
                  animation: _orbitCtrl,
                  builder: (_, __) => CustomPaint(
                    size: Size(ringOuter, ringOuter),
                    painter: _OrbitParticlesPainter(
                      progress: _orbitCtrl.value,
                      color: CantillanaTheme.dorado,
                      orbitRadius: ringOuter / 2 - 3,
                    ),
                  ),
                ),

                // ── El escudo: translate → rotateZ → translate back ───────
                AnimatedBuilder(
                  animation: _spinAnim,
                  builder: (_, child) {
                    final angle = _spinAnim.value * 2 * math.pi;
                    final cx = s / 2;
                    final cy = s / 2;

                    return Transform(
                      alignment: Alignment.topLeft,
                      transform: Matrix4.identity()
                        ..translate(cx, cy) // 1. mover origen al centro
                        ..rotateZ(angle) // 2. rotar
                        ..translate(-cx, -cy), // 3. volver al origen
                      child: child,
                    );
                  },
                  child: _ShieldContainer(size: s),
                ),
              ],
            ),
          ),

          // ── Mensaje ───────────────────────────────────────────────────────
          if (widget.message != null) ...[
            const SizedBox(height: 18),
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Opacity(
                opacity: 0.45 + 0.55 * _pulseAnim.value,
                child: child,
              ),
              child: Text(
                widget.message!,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Contenedor del escudo ─────────────────────────────────────────────────────
class _ShieldContainer extends StatelessWidget {
  final double size;
  const _ShieldContainer({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: CantillanaTheme.dorado, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: CantillanaTheme.dorado.withOpacity(0.55),
            blurRadius: 22,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.1),
      child: Image.asset(
        'assets/cantillan.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

// ── CustomPainter: partículas en órbita ──────────────────────────────────────
class _OrbitParticlesPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double orbitRadius;

  const _OrbitParticlesPainter({
    required this.progress,
    required this.color,
    required this.orbitRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const totalDots = 5;

    for (int i = 0; i < totalDots; i++) {
      final baseAngle = (i / totalDots) * 2 * math.pi;
      final angle = baseAngle + progress * 2 * math.pi;

      // Tamaño y opacidad según posición en la órbita
      final t = (math.sin(angle * 0.5) + 1) / 2;
      final dotRadius = 2.5 + t * 2.0;
      final opacity = 0.25 + t * 0.65;

      final dotCenter = Offset(
        center.dx + orbitRadius * math.cos(angle),
        center.dy + orbitRadius * math.sin(angle),
      );

      // Halo
      canvas.drawCircle(
        dotCenter,
        dotRadius * 2.2,
        Paint()
          ..color = color.withOpacity(opacity * 0.25)
          ..style = PaintingStyle.fill,
      );

      // Núcleo
      canvas.drawCircle(
        dotCenter,
        dotRadius,
        Paint()
          ..color = color.withOpacity(opacity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitParticlesPainter old) => old.progress != progress;
}
