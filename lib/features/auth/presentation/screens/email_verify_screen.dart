import 'package:sajilo_restro_sewa/core/errors/app_error_handler.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../data/models/user_model.dart';

class EmailVerifyScreen extends StatefulWidget {
  final UserModel user;

  const EmailVerifyScreen({super.key, required this.user});

  @override
  State<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends State<EmailVerifyScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _fadeController;
  late final AnimationController _orbController;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _slideAnim;
  late final Animation<double> _orbAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _orbAnim = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _orbController, curve: Curves.linear));

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _slideAnim = Tween<double>(begin: 32, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 700;

    const accentColor = Color(0xFFD97706);
    final bgDark = const Color(0xFF0C0800);
    final bgLight = const Color(0xFFFFFBF0);

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 0 : 28,
          vertical: 40,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _orbAnim,
                builder: (_, child) => CustomPaint(
                  painter: _OrbPainter(
                    angle: _orbAnim.value,
                    color: accentColor,
                    isDark: isDark,
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _fadeController,
                  builder: (context, child) => Opacity(
                    opacity: _fadeAnim.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnim.value),
                      child: child,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 520 : double.infinity,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (_, child) => Transform.scale(
                              scale: _pulseAnim.value,
                              child: child,
                            ),
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accentColor.withValues(
                                  alpha: isDark ? 0.15 : 0.10,
                                ),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.25),
                                    blurRadius: 32,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.mark_email_unread_rounded,
                                size: 46,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        Text(
                          'Verify Email Address',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            height: 1.2,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'We sent a verification link to:\n${widget.user.email}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF6B7280),
                          ),
                        ),

                        const SizedBox(height: 32),

                        _InfoCard(
                          user: widget.user,
                          accentColor: accentColor,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 28),

                        _BulletSection(
                          isDark: isDark,
                          accentColor: accentColor,
                        ),

                        const SizedBox(height: 40),

                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            final isResending = state is EmailUnverified && state.isResending;
                            return Column(
                              children: [
                                _ActionButton(
                                  isLoading: isResending,
                                  accentColor: accentColor,
                                  isDark: isDark,
                                  label: 'I have verified my email',
                                  icon: Icons.check_circle_outline_rounded,
                                  onPressed: () => context.read<AuthCubit>().recheckEmailVerification(),
                                ),
                                const SizedBox(height: 12),
                                _ActionButton(
                                  isLoading: isResending,
                                  accentColor: accentColor,
                                  isDark: isDark,
                                  isOutlined: true,
                                  label: 'Resend verification email',
                                  icon: Icons.send_rounded,
                                  onPressed: () {
                                    context.read<AuthCubit>().resendVerification();
                                    AppErrorHandler.showSuccess(context, 'Verification email requested');
                                  },
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        Center(
                          child: TextButton(
                            onPressed: () => context.read<AuthCubit>().logout(),
                            style: TextButton.styleFrom(
                              foregroundColor: isDark
                                  ? Colors.white54
                                  : const Color(0xFF6B7280),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Sign out',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final UserModel user;
  final Color accentColor;
  final bool isDark;

  const _InfoCard({
    required this.user,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: accentColor.withValues(alpha: 0.15),
                backgroundImage: user.avatar != null
                    ? NetworkImage(user.avatar!)
                    : null,
                child: user.avatar == null
                    ? Icon(Icons.person_rounded, color: accentColor, size: 22)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.firstName} ${user.lastName}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Unverified',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CardDetail(
                label: 'Role',
                value: user.role.isNotEmpty
                    ? user.role[0].toUpperCase() + user.role.substring(1)
                    : '—',
                isDark: isDark,
              ),
              _CardDetail(
                label: 'Status',
                value: user.status.toUpperCase(),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardDetail extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _CardDetail({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black38,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _BulletSection extends StatelessWidget {
  final bool isDark;
  final Color accentColor;

  const _BulletSection({
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final bullets = [
      'You cannot access the application until your email is verified.',
      'Check your spam or junk folder if you don\'t see the email.',
      'Click the button below if you need a new verification link.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What this means',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        ...bullets.map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
               crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    b,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.white60 : const Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool isLoading;
  final Color accentColor;
  final bool isDark;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isOutlined;

  const _ActionButton({
    required this.isLoading,
    required this.accentColor,
    required this.isDark,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: isOutlined ? Border.all(
            color: accentColor.withValues(alpha: isLoading ? 0.2 : 0.4),
            width: 1.5,
          ) : null,
          color: isOutlined ? Colors.transparent : accentColor.withValues(
            alpha: isLoading
                ? (isDark ? 0.3 : 0.5)
                : 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isOutlined ? accentColor : Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: isOutlined ? accentColor : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: TextStyle(
                            color: isOutlined ? accentColor : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

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
    final opacity = isDark ? 0.07 : 0.05;

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
