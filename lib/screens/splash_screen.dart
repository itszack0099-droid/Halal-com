import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _patternController;

  @override
  void initState() {
    super.initState();
    _patternController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _patternController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Animated geometric pattern background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _patternController,
              builder: (_, __) => CustomPaint(
                painter: _GeometricPatternPainter(_patternController.value),
              ),
            ),
          ),
          // Radial gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    AppTheme.background.withOpacity(0.3),
                    AppTheme.background.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Islamic crescent + star icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary, width: 1.5),
                    color: AppTheme.primary.withOpacity(0.08),
                  ),
                  child: const Center(
                    child: Text('☪', style: TextStyle(fontSize: 50)),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(begin: const Offset(0.5, 0.5)),
                const SizedBox(height: 24),
                Text(
                  'Halal.com',
                  style: GoogleFonts.outfit(
                    color: AppTheme.primary,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: 8),
                Text(
                  'Halal & Haram Product Tracker',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 600.ms),
                const SizedBox(height: 60),
                // Arabic basmala
                Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textMuted,
                    fontSize: 16,
                  ),
                  textDirection: TextDirection.rtl,
                )
                    .animate(delay: 800.ms)
                    .fadeIn(duration: 800.ms),
                const SizedBox(height: 40),
                // Loading indicator
                SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    backgroundColor: AppTheme.primary.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 3,
                  ),
                ).animate(delay: 1000.ms).fadeIn(duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GeometricPatternPainter extends CustomPainter {
  final double progress;
  _GeometricPatternPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary.withOpacity(0.04)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const spacing = 80.0;
    final offsetX = (progress * spacing) % spacing;
    final offsetY = (progress * spacing * 0.5) % spacing;

    for (double x = -spacing + offsetX; x < size.width + spacing; x += spacing) {
      for (double y = -spacing + offsetY; y < size.height + spacing; y += spacing) {
        _drawGeometricStar(canvas, paint, Offset(x, y), 30);
      }
    }
  }

  void _drawGeometricStar(Canvas canvas, Paint paint, Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * 3.14159 / 180;
      final outerPoint = Offset(
        center.dx + radius * (i.isEven ? 1 : 0.5) * _cos(angle),
        center.dy + radius * (i.isEven ? 1 : 0.5) * _sin(angle),
      );
      if (i == 0) path.moveTo(outerPoint.dx, outerPoint.dy);
      else path.lineTo(outerPoint.dx, outerPoint.dy);
    }
    path.close();
    canvas.drawPath(path, paint);

    // Inner circle
    canvas.drawCircle(center, radius * 0.35, paint);
  }

  double _cos(double angle) => (angle == 0) ? 1 : (angle == 3.14159 / 2) ? 0 : (angle == 3.14159) ? -1 : (angle == 3 * 3.14159 / 2) ? 0 : (1.0 - (angle * angle) / 2);
  double _sin(double angle) {
    const pi = 3.14159265359;
    while (angle > 2 * pi) angle -= 2 * pi;
    if (angle < pi / 2) return angle - (angle * angle * angle) / 6;
    if (angle < pi) { final a = pi - angle; return a - (a * a * a) / 6; }
    if (angle < 3 * pi / 2) { final a = angle - pi; return -(a - (a * a * a) / 6); }
    final a = 2 * pi - angle;
    return -(a - (a * a * a) / 6);
  }

  @override
  bool shouldRepaint(_GeometricPatternPainter old) => old.progress != progress;
}
