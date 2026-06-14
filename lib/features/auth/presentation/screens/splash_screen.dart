import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';

const restroName = String.fromEnvironment('RESTRO_NAME', defaultValue: 'Sajilo Restro Sewa');

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _orbController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _orbAnim;

  @override
  void initState() {
    super.initState();
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    
    _orbAnim = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _orbController, curve: Curves.linear));

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );

    _animController.forward();

    // Check session after animation finishes
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        context.read<AuthCubit>().checkSession();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1208) : const Color(0xFFFFF8F0),
      body: Stack(
        children: [
          // Animated Orb background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _orbAnim,
              builder: (_, child) => CustomPaint(
                painter: _OrbPainter(
                  angle: _orbAnim.value,
                  color: const Color(0xFFE65100),
                  isDark: isDark,
                ),
              ),
            ),
          ),
          
          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo with gradient background
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE65100), Color(0xFFBF360C)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE65100).withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.restaurant_menu_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // App Title
                    Text(
                      restroName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        color: isDark ? Colors.white : const Color(0xFF1A1208),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Subtitle
                    Text(
                      'Restaurant Management System',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white54 : const Color(0xFF6D4C1F),
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Loading indicator at bottom
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Orb painter ───────────────────────────────────────────────────────────────
class _OrbPainter extends CustomPainter {
  final double angle;
  final Color color;
  final bool isDark;

  const _OrbPainter({
    required this.angle,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = isDark ? 0.09 : 0.06;

    void drawOrb(double cx, double cy, double r) {
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
      );
    }

    drawOrb(
      size.width * 0.5 + math.cos(angle) * size.width * 0.28,
      size.height * 0.35 + math.sin(angle) * size.height * 0.12,
      size.width * 0.45,
    );
    drawOrb(
      size.width * 0.5 + math.cos(angle + math.pi) * size.width * 0.22,
      size.height * 0.65 + math.sin(angle + math.pi) * size.height * 0.10,
      size.width * 0.35,
    );
    drawOrb(0, 0, size.width * 0.3);
    drawOrb(size.width, size.height, size.width * 0.25);
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.angle != angle || old.isDark != isDark;
}

