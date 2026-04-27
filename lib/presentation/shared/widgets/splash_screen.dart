import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Logo entrance
  late AnimationController _logoCtrl;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<Offset> _logoSlide;

  // Text & subtitle stagger
  late AnimationController _textCtrl;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleFade;

  // Pulsing glow ring
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Rotating radar ring
  late AnimationController _radarCtrl;
  late Animation<double> _radarAnim;

  // Ambient orb drift
  late AnimationController _orbCtrl;
  late Animation<double> _orbAnim;

  // Loading dots
  late AnimationController _dotsCtrl;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoFade =
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic));

    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: const Interval(0.0, 0.6)));
    _titleSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _textCtrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: const Interval(0.4, 1.0)));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _radarCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
    _radarAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(
        CurvedAnimation(parent: _radarCtrl, curve: Curves.linear));

    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5000))
      ..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);

    _dotsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();

    // Stagger entrance animations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _logoCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textCtrl.forward();
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    _radarCtrl.dispose();
    _orbCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── Layer 1: Deep gradient background ──────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF020510),
                  Color(0xFF050C1A),
                  Color(0xFF030814),
                ],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── Layer 2: Ambient floating orbs ────────────────────────────
          AnimatedBuilder(
            animation: _orbAnim,
            builder: (_, _) {
              final t = _orbAnim.value;
              return Stack(
                children: [
                  // Top-left large orb
                  Positioned(
                    left: -size.width * 0.2 + t * 30,
                    top: -size.height * 0.05 + t * 20,
                    child: _GlowOrb(
                      size: size.width * 0.7,
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  // Bottom-right orb
                  Positioned(
                    right: -size.width * 0.15,
                    bottom: -size.height * 0.05 + t * 40,
                    child: _GlowOrb(
                      size: size.width * 0.65,
                      color: AppColors.accent.withValues(alpha: 0.06),
                    ),
                  ),
                  // Center-right smaller orb
                  Positioned(
                    right: size.width * 0.05 - t * 20,
                    top: size.height * 0.3 + t * 15,
                    child: _GlowOrb(
                      size: size.width * 0.4,
                      color: AppColors.sos.withValues(alpha: 0.04),
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Layer 3: Grid / scan lines overlay ───────────────────────
          CustomPaint(
            size: Size(size.width, size.height),
            painter: _GridPainter(),
          ),

          // ── Layer 4: Central radar ring ───────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _radarAnim,
              builder: (_, _) {
                return CustomPaint(
                  size: const Size(300, 300),
                  painter: _RadarPainter(_radarAnim.value),
                );
              },
            ),
          ),

          // ── Layer 5: Pulsing glow circle behind logo ──────────────────
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, _) {
                return Container(
                  width: 150 * _pulseAnim.value,
                  height: 150 * _pulseAnim.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.04),
                    border: Border.all(
                      color: AppColors.accent.withValues(
                          alpha: 0.12 * (2 - _pulseAnim.value)),
                      width: 1,
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Layer 6: Main content ──────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo icon
                FadeTransition(
                  opacity: _logoFade,
                  child: SlideTransition(
                    position: _logoSlide,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: _LogoIcon(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // App name
                FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.accentGradient.createShader(bounds),
                      child: Text(
                        'CRISISCONNECT',
                        style: GoogleFonts.rajdhani(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                FadeTransition(
                  opacity: _subtitleFade,
                  child: Text(
                    'EVERY SECOND COUNTS',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHint,
                      letterSpacing: 3.5,
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                // Animated loading dots
                FadeTransition(
                  opacity: _subtitleFade,
                  child: _LoadingDots(controller: _dotsCtrl),
                ),
              ],
            ),
          ),

          // ── Layer 7: Bottom status bar ────────────────────────────────
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _subtitleFade,
              child: Text(
                'INITIALIZING RESPONSE NETWORK',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint.withValues(alpha: 0.6),
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Logo Icon ────────────────────────────────────────────────────────────────

class _LogoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF0A2D6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.25),
            blurRadius: 40,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.crisis_alert_rounded,
          color: Colors.white, size: 58),
    );
  }
}

// ─── Animated Orb ─────────────────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// ─── Grid Painter (scan lines) ────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Radar Ring CustomPainter ─────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  final double angle;
  _RadarPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Static concentric rings
    for (int i = 1; i <= 4; i++) {
      final radius = (size.width / 2) * (i / 4);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.04 + (i * 0.01))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // Rotating sweep segment
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: angle - 1.2,
        endAngle: angle,
        colors: [
          Colors.transparent,
          AppColors.accent.withValues(alpha: 0.15),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2))
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width / 2),
      angle - 1.2,
      1.2,
      true,
      sweepPaint,
    );

    // Sweep leading edge dot
    final edgeX = center.dx + (size.width / 2) * math.cos(angle);
    final edgeY = center.dy + (size.width / 2) * math.sin(angle);
    canvas.drawCircle(
      Offset(edgeX, edgeY),
      3,
      Paint()..color = AppColors.accent.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.angle != angle;
}

// ─── Animated Loading Dots ────────────────────────────────────────────────────

class _LoadingDots extends StatelessWidget {
  final AnimationController controller;
  const _LoadingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Each dot staggers by 0.2
            final phase = (controller.value - i * 0.2).clamp(0.0, 1.0);
            final opacity = math.sin(phase * math.pi).clamp(0.2, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
