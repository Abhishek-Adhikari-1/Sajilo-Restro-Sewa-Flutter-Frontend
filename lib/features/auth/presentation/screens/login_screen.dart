import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/app_error_handler.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthCubit>().login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 900;
    final isTablet = size.width >= 600 && size.width < 900;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            current is Unauthenticated &&
            current.errorMessage != null &&
            previous is LoginLoading,
        listener: (context, state) {
          if (state is Unauthenticated && state.errorMessage != null) {
            AppErrorHandler.showError(context, state.errorMessage!);
          }
        },
        child: isWide
            ? _WideLayout(
                formKey: _formKey,
                emailController: _emailController,
                passwordController: _passwordController,
                obscurePassword: _obscurePassword,
                fadeAnim: _fadeAnim,
                slideAnim: _slideAnim,
                isDark: isDark,
                onTogglePassword: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onSubmit: _submit,
              )
            : _NarrowLayout(
                formKey: _formKey,
                emailController: _emailController,
                passwordController: _passwordController,
                obscurePassword: _obscurePassword,
                fadeAnim: _fadeAnim,
                slideAnim: _slideAnim,
                isDark: isDark,
                isTablet: isTablet,
                onTogglePassword: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onSubmit: _submit,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Wide layout (desktop): left brand panel + right form panel
// ─────────────────────────────────────────────────────────────
class _WideLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final bool isDark;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  const _WideLayout({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.fadeAnim,
    required this.slideAnim,
    required this.isDark,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left brand panel
        Expanded(
          child: _BrandPanel(isDark: isDark),
        ),

        // Divider line
        Container(
          width: 1,
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),

        // Right form panel
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: FadeTransition(
                  opacity: fadeAnim,
                  child: SlideTransition(
                    position: slideAnim,
                    child: _FormCard(
                      formKey: formKey,
                      emailController: emailController,
                      passwordController: passwordController,
                      obscurePassword: obscurePassword,
                      isDark: isDark,
                      onTogglePassword: onTogglePassword,
                      onSubmit: onSubmit,
                      isCompact: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Narrow layout (mobile / tablet): stacked
// ─────────────────────────────────────────────────────────────
class _NarrowLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final bool isDark;
  final bool isTablet;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  const _NarrowLayout({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.fadeAnim,
    required this.slideAnim,
    required this.isDark,
    required this.isTablet,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hPad = isTablet ? 64.0 : 24.0;

    return CustomScrollView(
      slivers: [
        // Top hero section
        SliverToBoxAdapter(
          child: Container(
            height: isTablet ? 260 : 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1A1208),
                        const Color(0xFF2D1F0A),
                      ]
                    : [
                        const Color(0xFFFFF3E0),
                        const Color(0xFFFFE0B2),
                      ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE65100).withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sajilo Restro Sewa',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1A1208),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Restaurant Management System',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF6D4C1F),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Form section
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 32),
            child: FadeTransition(
              opacity: fadeAnim,
              child: SlideTransition(
                position: slideAnim,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: _FormCard(
                      formKey: formKey,
                      emailController: emailController,
                      passwordController: passwordController,
                      obscurePassword: obscurePassword,
                      isDark: isDark,
                      onTogglePassword: onTogglePassword,
                      onSubmit: onSubmit,
                      isCompact: !isTablet,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared brand panel (desktop left side)
// ─────────────────────────────────────────────────────────────
class _BrandPanel extends StatelessWidget {
  final bool isDark;

  const _BrandPanel({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1208),
                  const Color(0xFF2D1F0A),
                  const Color(0xFF1A1208),
                ]
              : [
                  const Color(0xFFFFF8F0),
                  const Color(0xFFFFEDD8),
                  const Color(0xFFFFF3E0),
                ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE65100).withValues(alpha: isDark ? 0.08 : 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE65100).withValues(alpha: isDark ? 0.05 : 0.04),
              ),
            ),
          ),

          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo mark
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE65100).withValues(alpha: 0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Sajilo\nRestro Sewa',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -1.5,
                      color: isDark ? Colors.white : const Color(0xFF1A1208),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Restaurant Management\nSystem',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: isDark
                          ? Colors.white38
                          : const Color(0xFF6D4C1F),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Feature pills
                  ...[
                    ('Orders & Billing', Icons.receipt_long_rounded),
                    ('Kitchen Display', Icons.soup_kitchen_rounded),
                    ('Role-Based Access', Icons.shield_rounded),
                  ].map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE65100).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item.$2,
                              size: 16,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.$1,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF3E2723),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared form card
// ─────────────────────────────────────────────────────────────
class _FormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isDark;
  final bool isCompact;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  const _FormCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isDark,
    required this.isCompact,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isCompact) ...[
          Text(
            'Welcome back',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: isDark ? Colors.white : const Color(0xFF1A1208),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to your workspace',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white54 : const Color(0xFF6D4C1F),
            ),
          ),
          const SizedBox(height: 36),
        ] else ...[
          Text(
            'Welcome back',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF1A1208),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to your workspace',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white54 : const Color(0xFF6D4C1F),
            ),
          ),
          const SizedBox(height: 28),
        ],

        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Email field
              _StyledField(
                controller: emailController,
                label: 'Email address',
                hint: 'abhishek@example.com',
                icon: Icons.email_outlined,
                isDark: isDark,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password field
              _StyledField(
                controller: passwordController,
                label: 'Password',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                isDark: isDark,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onSubmit(),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  onPressed: onTogglePassword,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Submit button
              BlocBuilder<AuthCubit, AuthState>(
                buildWhen: (previous, current) =>
                    current is LoginLoading || previous is LoginLoading,
                builder: (context, state) {
                  final isLoading = state is LoginLoading;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: isLoading
                          ? null
                          : const LinearGradient(
                              colors: [
                                Color(0xFFE65100),
                                Color(0xFFBF360C),
                              ],
                            ),
                      color: isLoading
                          ? (isDark
                              ? Colors.white12
                              : Colors.black12)
                          : null,
                      boxShadow: isLoading
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(0xFFE65100).withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: isLoading ? null : onSubmit,
                        child: Center(
                          child: isLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Footer note
        Text(
          'Access is restricted to authorized staff only.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white24 : Colors.black26,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Reusable styled text field
// ─────────────────────────────────────────────────────────────
class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.10);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF1A1208),
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20,
            color: isDark ? Colors.white38 : Colors.black38),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        labelStyle: TextStyle(
          color: isDark ? Colors.white54 : const Color(0xFF6D4C1F),
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white24 : Colors.black26,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE65100), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
