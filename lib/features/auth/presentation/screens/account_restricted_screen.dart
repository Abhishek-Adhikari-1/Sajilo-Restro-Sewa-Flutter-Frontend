import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../../data/models/user_model.dart';

class AccountRestrictedScreen extends StatefulWidget {
  final UserModel user;
  final String reason;

  /// Driven by [AccountRestricted.isRechecking] from the cubit —
  /// no local state needed; the cubit owns the loading flag.
  final bool isRechecking;

  const AccountRestrictedScreen({
    super.key,
    required this.user,
    required this.reason,
    this.isRechecking = false,
  });

  @override
  State<AccountRestrictedScreen> createState() =>
      _AccountRestrictedScreenState();
}

class _AccountRestrictedScreenState extends State<AccountRestrictedScreen>
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

  bool get _isDisabled =>
      widget.reason.toLowerCase().contains('disabled');
      
  IconData get _statusIcon {
    final lowerReason = widget.reason.toLowerCase();
    if (lowerReason.contains('disabled')) return Icons.block_rounded;
    if (lowerReason.contains('suspend')) return Icons.pause_circle_outline_rounded;
    return Icons.person_off_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 700;

    final accentColor = _isDisabled
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);
    final bgDark = _isDisabled
        ? const Color(0xFF0F0505)
        : const Color(0xFF0C0800);
    final bgLight = _isDisabled
        ? const Color(0xFFFFF5F5)
        : const Color(0xFFFFFBF0);

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 0 : 28,
          vertical: 40,
        ),
        child: Stack(
          children: [
            // ── Ambient orb background ────────────────────────────────────
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

            // ── Content ───────────────────────────────────────────────────
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
                        // ── Pulsing icon ──────────────────────────────
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
                              child: Icon(
                                _statusIcon,
                                size: 46,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Headline ──────────────────────────────────
                        Text(
                          _isDisabled
                              ? 'Account Disabled'
                              : 'Account Deactivated',
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
                          _isDisabled
                              ? 'Your account has been disabled by an administrator.\nYou no longer have access to this system.'
                              : 'Your account has been temporarily deactivated.\nPlease contact your manager to restore access.',
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

                        // ── Info card ─────────────────────────────────
                        _InfoCard(
                          user: widget.user,
                          accentColor: accentColor,
                          isDark: isDark,
                          isDisabled: _isDisabled,
                        ),

                        const SizedBox(height: 28),

                        // ── Bullet list ───────────────────────────────
                        _BulletSection(
                          isDark: isDark,
                          accentColor: accentColor,
                          isDisabled: _isDisabled,
                        ),

                        const SizedBox(height: 40),

                        // ── "Check again" — deactivated only ──────────
                        // Spinner is driven by widget.isRechecking (from
                        // cubit state), NOT local setState — so the
                        // screen never flickers and no snackbar fires.
                        if (!_isDisabled) ...[
                          _RecheckButton(
                            isRechecking: widget.isRechecking,
                            accentColor: accentColor,
                            isDark: isDark,
                            onPressed: () =>
                                context.read<AuthCubit>().recheckStatus(),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ── Sign out ──────────────────────────────────
                        Center(
                          child: TextButton(
                            onPressed: widget.isRechecking
                                ? null
                                : () => context.read<AuthCubit>().logout(),
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

                        Text(
                          'If you believe this is a mistake, contact your\nsystem administrator.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.6,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ),
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

// ── Info card ─────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final UserModel user;
  final Color accentColor;
  final bool isDark;
  final bool isDisabled;

  const _InfoCard({
    required this.user,
    required this.accentColor,
    required this.isDark,
    required this.isDisabled,
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
              // Status badge
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
                  isDisabled ? 'Disabled' : 'Inactive',
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
                label: 'Email verified',
                value: user.emailVerified ? 'Yes' : 'No',
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

// ── Bullet section ────────────────────────────────────────────────────────────
class _BulletSection extends StatelessWidget {
  final bool isDark;
  final Color accentColor;
  final bool isDisabled;

  const _BulletSection({
    required this.isDark,
    required this.accentColor,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    final bullets = isDisabled
        ? [
            'All API requests will be rejected by the server',
            'You cannot access any dashboards or data',
            'Your session tokens may still refresh but are functionally useless',
            'Contact your system administrator to appeal',
          ]
        : [
            'Your API access has been temporarily suspended',
            'Dashboards and data are inaccessible until reactivated',
            'Your account and all data are preserved',
            'A manager can reactivate your account at any time',
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

// ── Recheck button ────────────────────────────────────────────────────────────
class _RecheckButton extends StatelessWidget {
  final bool isRechecking;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onPressed;

  const _RecheckButton({
    required this.isRechecking,
    required this.accentColor,
    required this.isDark,
    required this.onPressed,
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
          border: Border.all(
            color: accentColor.withValues(alpha: isRechecking ? 0.3 : 0.6),
            width: 1.5,
          ),
          color: accentColor.withValues(
            alpha: isRechecking
                ? (isDark ? 0.05 : 0.03)
                : (isDark ? 0.12 : 0.08),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: isRechecking ? null : onPressed,
            child: Center(
              child: isRechecking
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accentColor,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: accentColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Check again',
                          style: TextStyle(
                            color: accentColor,
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
