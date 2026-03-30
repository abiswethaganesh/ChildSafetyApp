// lib/screens/login_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  bool _loading = false;
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final result = await AuthService().signInWithGoogle();
      if (result != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ShellScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sign-in failed: $e'),
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ── Soft blob background ──────────────────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: _Blob(color: AppColors.tealLight, size: 280),
          ),
          Positioned(
            bottom: -40,
            left: -60,
            child: _Blob(color: AppColors.amberLight, size: 220),
          ),
          Positioned(
            top: size.height * 0.35,
            left: -80,
            child: _Blob(color: AppColors.lavenderLight, size: 180),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              child: SizedBox(
                height: size.height - MediaQuery.of(context).padding.top,
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // ── Floating illustration ───────────────────────────────
                    AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, -_floatAnim.value),
                        child: child,
                      ),
                      child: _ParentChildIllustration(),
                    ),

                    const SizedBox(height: 32),

                    // ── Brand ───────────────────────────────────────────────
                    const Text(
                      'Guardian',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: AppColors.teal,
                        letterSpacing: -1,
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),

                    const SizedBox(height: 8),
                    const Text(
                      'Your child, always within reach 💛',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textMid,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 400.ms),

                    const Spacer(),

                    // ── Feature pills ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: const [
                          _Pill('📍 Live GPS tracking'),
                          _Pill('🔴 Red zone alerts'),
                          _Pill('🆘 SOS escalation'),
                          _Pill('👥 Community watch'),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms),

                    const SizedBox(height: 40),

                    // ── Sign-in button ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.textDark,
                            side: const BorderSide(
                                color: AppColors.divider, width: 1.5),
                            elevation: 2,
                            shadowColor: AppColors.shadow,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.teal),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _GoogleG(),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

                    const SizedBox(height: 16),
                    const Text(
                      'Only verified Google accounts · No anonymous access',
                      style: TextStyle(
                          color: AppColors.textLight, fontSize: 12),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 700.ms),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cute drawn illustration ───────────────────────────────────────────────────
class _ParentChildIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 220,
      child: CustomPaint(painter: _IllustrationPainter()),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;

    // ── Ground / grass ────────────────────────────────────────────────────
    p.color = const Color(0xFFE8F5E9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.75, size.width, size.height * 0.25),
        const Radius.circular(20),
      ),
      p,
    );

    // ── Shield / badge (background glow) ─────────────────────────────────
    p.color = AppColors.tealLight;
    canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.42), 78, p);

    // ── Parent (left, taller) ─────────────────────────────────────────────
    _drawPerson(
      canvas,
      center: Offset(size.width * 0.38, size.height * 0.5),
      bodyColor: AppColors.teal,
      headColor: const Color(0xFFFDCB9E),
      size: 1.15,
      isParent: true,
    );

    // ── Child (right, smaller) ────────────────────────────────────────────
    _drawPerson(
      canvas,
      center: Offset(size.width * 0.62, size.height * 0.55),
      bodyColor: AppColors.amber,
      headColor: const Color(0xFFFDCB9E),
      size: 0.82,
      isParent: false,
    );

    // ── Joining hands (simple line) ───────────────────────────────────────
    final handPaint = Paint()
      ..color = AppColors.teal.withOpacity(0.5)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.47, size.height * 0.57),
      Offset(size.width * 0.55, size.height * 0.60),
      handPaint,
    );

    // ── Heart floating above child ────────────────────────────────────────
    _drawHeart(canvas, Offset(size.width * 0.67, size.height * 0.18), 10);

    // ── Small location pin ────────────────────────────────────────────────
    _drawPin(canvas, Offset(size.width * 0.62, size.height * 0.08));
  }

  void _drawPerson(Canvas canvas,
      {required Offset center,
      required Color bodyColor,
      required Color headColor,
      required double size,
      required bool isParent}) {
    final p = Paint()..style = PaintingStyle.fill;

    final headR = 18.0 * size;
    final bodyW = 28.0 * size;
    final bodyH = 36.0 * size;
    final headY = center.dy - bodyH / 2 - headR - 2;

    // body
    p.color = bodyColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(center.dx, center.dy), width: bodyW, height: bodyH),
        Radius.circular(bodyW / 2),
      ),
      p,
    );

    // head
    p.color = headColor;
    canvas.drawCircle(Offset(center.dx, headY), headR, p);

    // hair
    p.color = isParent ? const Color(0xFF4A3728) : const Color(0xFF8B5E3C);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center.dx, headY), radius: headR),
      math.pi,
      math.pi,
      false,
      p,
    );

    // eyes
    p.color = const Color(0xFF333333);
    canvas.drawCircle(
        Offset(center.dx - headR * 0.3, headY + 2), 2.5 * size, p);
    canvas.drawCircle(
        Offset(center.dx + headR * 0.3, headY + 2), 2.5 * size, p);

    // smile
    final smilePaint = Paint()
      ..color = const Color(0xFF555555)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(center.dx, headY + 3), width: 12 * size, height: 7 * size),
      0,
      math.pi,
      false,
      smilePaint,
    );
  }

  void _drawHeart(Canvas canvas, Offset center, double r) {
    final p = Paint()
      ..color = AppColors.coral
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(center.dx, center.dy + r * 0.6);
    path.cubicTo(center.dx - r * 1.5, center.dy - r * 0.5, center.dx - r * 2,
        center.dy - r * 2, center.dx, center.dy - r * 1.1);
    path.cubicTo(center.dx + r * 2, center.dy - r * 2, center.dx + r * 1.5,
        center.dy - r * 0.5, center.dx, center.dy + r * 0.6);
    canvas.drawPath(path, p);
  }

  void _drawPin(Canvas canvas, Offset center) {
    final p = Paint()..color = AppColors.teal;
    canvas.drawCircle(center, 8, p);
    p.color = Colors.white;
    canvas.drawCircle(center, 4, p);
    p.color = AppColors.teal;
    final path = Path()
      ..moveTo(center.dx - 5, center.dy + 4)
      ..lineTo(center.dx + 5, center.dy + 4)
      ..lineTo(center.dx, center.dy + 14)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.tealLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.tealDark,
        ),
      ),
    );
  }
}

class _GoogleG extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Simple G painted with correct Google brand colors
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 1;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 3;

    // Blue arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r),
        -math.pi / 4, math.pi * 1.25, false, paint);

    // Red arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r),
        math.pi, math.pi / 4, false, paint);

    // Yellow arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r),
        math.pi * 1.25, math.pi / 4, false, paint);

    // Green horizontal bar
    paint.color = const Color(0xFF34A853);
    paint.style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2, size.height / 2 - 1.5,
          r + 1, 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}