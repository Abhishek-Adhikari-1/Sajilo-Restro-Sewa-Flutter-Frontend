import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubit/auth_cubit.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String token;
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.token,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  // States: loading, success, error
  bool _isLoading = true;
  bool _isSuccess = false;
  String? _errorMessage;

  late final AnimationController _bgOrbController;
  late final AnimationController _fadeController;
  late final AnimationController _successController;
  late final AnimationController _pulseController;

  late final Animation<double> _fadeAnim;
  late final Animation<double> _slideAnim;
  late final Animation<double> _bgOrbAnim;
  late final Animation<double> _successScale;
  late final Animation<double> _successOpacity;
  late final Animation<double> _pulseAnim;

  static const _accent = Color(0xFFE65100);
  static const _accentAmber = Color(0xFFD97706);
  static const String _appName = String.fromEnvironment(
    'RESTRO_NAME',
    defaultValue: 'Sajilo Restro Sewa',
  );

  @override
  void initState() {
    super.initState();

    _bgOrbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _bgOrbAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _bgOrbController, curve: Curves.linear),
    );
    _successScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    _successOpacity = CurvedAnimation(
      parent: _successController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _verify();
  }

  Future<void> _verify() async {
    try {
      await context.read<AuthCubit>().verifyEmail(widget.token, widget.email);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
        _successController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _bgOrbController.dispose();
    _fadeController.dispose();
    _successController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 700;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Animated background orbs
          AnimatedBuilder(
            animation: _bgOrbAnim,
            builder: (_, _) => CustomPaint(
              size: Size(size.width, size.height),
              painter: _OrbPainter(
                angle: _bgOrbAnim.value,
                isDark: isDark,
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 0 : 24,
                  vertical: 40,
                ),
                child: AnimatedBuilder(
                  animation: _fadeController,
                  builder: (_, child) => Opacity(
                    opacity: _fadeAnim.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnim.value),
                      child: child,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 480 : double.infinity,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(isDark),
                        const SizedBox(height: 40),
                        _buildCard(isDark),
                        const SizedBox(height: 28),
                        if (!_isLoading) _buildAction(isDark),
                        const SizedBox(height: 24),
                        _buildFooter(isDark),
                      ],
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

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        // Logo badge
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _accent.withValues(alpha: isDark ? 0.25 : 0.15),
                _accent.withValues(alpha: 0.0),
              ],
            ),
            border: Border.all(
              color: _accent.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              _appName.isNotEmpty ? _appName[0].toUpperCase() : 'S',
              style: GoogleFonts.inter(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: _accent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _appName,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: isDark
                ? Colors.white38
                : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(bool isDark) {
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.85);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE0E0E0);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: _buildCardContent(isDark),
    );
  }

  Widget _buildCardContent(bool isDark) {
    if (_isLoading) return _buildLoadingContent(isDark);
    if (_isSuccess) return _buildSuccessContent(isDark);
    return _buildErrorContent(isDark);
  }

  Widget _buildLoadingContent(bool isDark) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) => Transform.scale(
            scale: _pulseAnim.value,
            child: child,
          ),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentAmber.withValues(alpha: isDark ? 0.12 : 0.08),
              border: Border.all(
                color: _accentAmber.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _accentAmber,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Verifying Your Email',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Please wait while we confirm\n${widget.email}',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.6,
            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent(bool isDark) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _successController,
          builder: (_, child) => Opacity(
            opacity: _successOpacity.value,
            child: Transform.scale(
              scale: _successScale.value,
              child: child,
            ),
          ),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withValues(alpha: isDark ? 0.15 : 0.10),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 40,
              color: Colors.green.shade500,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Email Verified!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your email ${widget.email} has been successfully verified. You can now access the full features of $_appName.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.6,
            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 20),
        // Success detail row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: isDark ? 0.10 : 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_rounded,
                size: 16,
                color: Colors.green.shade500,
              ),
              const SizedBox(width: 8),
              Text(
                'Account is fully active',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(bool isDark) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withValues(alpha: isDark ? 0.12 : 0.08),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: Colors.red.shade400,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Verification Failed',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _errorMessage ?? 'Something went wrong. The link may be invalid or expired.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.6,
            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: isDark ? 0.10 : 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Colors.red.shade400,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Please request a new verification link',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAction(bool isDark) {
    if (_isLoading) return const SizedBox.shrink();

    if (_isSuccess) {
      return _PrimaryButton(
        label: 'Continue to App',
        icon: Icons.arrow_forward_rounded,
        onPressed: () => Navigator.of(context).pop(),
        isDark: isDark,
      );
    }

    return _PrimaryButton(
      label: 'Close',
      icon: Icons.close_rounded,
      onPressed: () => Navigator.of(context).pop(),
      isDark: isDark,
      isError: true,
    );
  }

  Widget _buildFooter(bool isDark) {
    return Text(
      'Powered by $_appName',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 12,
        color: isDark ? Colors.white24 : const Color(0xFF9CA3AF),
        letterSpacing: 0.3,
      ),
    );
  }
}

// ─── Primary Action Button ────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDark;
  final bool isError;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isDark,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE65100);
    final bg = isError
        ? (isDark ? Colors.white12 : const Color(0xFFF3F4F6))
        : accent;
    final fg = isError
        ? (isDark ? Colors.white54 : const Color(0xFF6B7280))
        : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, size: 18, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Background Orb Painter ───────────────────────────────────────────────────

class _OrbPainter extends CustomPainter {
  final double angle;
  final bool isDark;

  const _OrbPainter({required this.angle, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    const color = Color(0xFFE65100);
    final opacity = isDark ? 0.07 : 0.05;

    void drawOrb(double cx, double cy, double r) {
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70),
      );
    }

    drawOrb(
      size.width * 0.15,
      size.height * 0.12,
      size.width * 0.45,
    );
    drawOrb(
      size.width * 0.5 + math.cos(angle) * size.width * 0.25,
      size.height * 0.4 + math.sin(angle) * size.height * 0.1,
      size.width * 0.4,
    );
    drawOrb(
      size.width * 0.85,
      size.height * 0.88,
      size.width * 0.38,
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.angle != angle || old.isDark != isDark;
}
