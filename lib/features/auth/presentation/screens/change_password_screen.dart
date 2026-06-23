import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/repositories/auth_repository.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  final _repo = AuthRepository();

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _repo.changePassword(
        currentPassword: _currentCtrl.text.trim(),
        newPassword: _newCtrl.text.trim(),
        confirmPassword: _confirmCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Change Password'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              accent.withValues(alpha: 0.15),
                              accent.withValues(alpha: 0.05),
                            ]
                          : [
                              accent.withValues(alpha: 0.10),
                              accent.withValues(alpha: 0.02),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.lock_outline_rounded,
                          color: accent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update Password',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Use a strong password with letters, numbers, and special characters.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                height: 1.5,
                                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Section label
                _SectionLabel(label: 'Current Password', isDark: isDark),
                const SizedBox(height: 10),

                _PasswordField(
                  controller: _currentCtrl,
                  hint: 'Enter your current password',
                  visible: _showCurrent,
                  onToggle: () => setState(() => _showCurrent = !_showCurrent),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Current password is required';
                    return null;
                  },
                ),

                const SizedBox(height: 24),
                _SectionLabel(label: 'New Password', isDark: isDark),
                const SizedBox(height: 10),

                _PasswordField(
                  controller: _newCtrl,
                  hint: 'Enter your new password',
                  visible: _showNew,
                  onToggle: () => setState(() => _showNew = !_showNew),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'New password is required';
                    if (v.length < 8) return 'Must be at least 8 characters';
                    if (!RegExp(r'(?=.*[a-z])').hasMatch(v)) {
                      return 'Must contain at least one lowercase letter';
                    }
                    if (!RegExp(r'(?=.*[A-Z])').hasMatch(v)) {
                      return 'Must contain at least one uppercase letter';
                    }
                    if (!RegExp(r'(?=.*\d)').hasMatch(v)) {
                      return 'Must contain at least one number';
                    }
                    if (v == _currentCtrl.text) {
                      return 'New password must differ from current password';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Password strength indicator
                _PasswordStrengthBar(password: _newCtrl.text),

                const SizedBox(height: 24),
                _SectionLabel(label: 'Confirm New Password', isDark: isDark),
                const SizedBox(height: 10),

                _PasswordField(
                  controller: _confirmCtrl,
                  hint: 'Re-enter your new password',
                  visible: _showConfirm,
                  onToggle: () => setState(() => _showConfirm = !_showConfirm),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your new password';
                    if (v != _newCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),

                const SizedBox(height: 36),

                // Requirements hint
                _PasswordRequirements(isDark: isDark, password: _newCtrl.text),

                const SizedBox(height: 28),

                // Submit button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: _isLoading
                        ? null
                        : const LinearGradient(
                            colors: [
                              Color(0xFFE65100),
                              Color(0xFFBF360C),
                            ],
                          ),
                    color: _isLoading
                        ? (isDark ? Colors.white12 : Colors.black12)
                        : null,
                    boxShadow: _isLoading
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
                      onTap: _isLoading ? null : _submit,
                      child: Center(
                        child: _isLoading
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                              )
                            : Text(
                                'Change Password',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
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
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: isDark ? Colors.white70 : const Color(0xFF374151),
      ),
    );
  }
}

// ─── Password Field ───────────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool visible;
  final VoidCallback onToggle;
  final String? Function(String?) validator;
  final void Function(String)? onChanged;

  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.visible,
    required this.onToggle,
    required this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      validator: validator,
      onChanged: onChanged,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: GoogleFonts.inter(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 14),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// ─── Password Strength Bar ────────────────────────────────────────────────────

class _PasswordStrengthBar extends StatelessWidget {
  final String password;
  const _PasswordStrengthBar({required this.password});

  int _score() {
    int s = 0;
    if (password.length >= 8) s++;
    if (RegExp(r'[a-z]').hasMatch(password)) s++;
    if (RegExp(r'[A-Z]').hasMatch(password)) s++;
    if (RegExp(r'\d').hasMatch(password)) s++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final score = _score();
    final color = score <= 2
        ? Colors.red.shade400
        : score <= 3
            ? Colors.orange.shade400
            : Colors.green.shade500;
    final label = score <= 2 ? 'Weak' : score <= 3 ? 'Fair' : 'Strong';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i < score ? color : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          'Strength: $label',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─── Password Requirements ────────────────────────────────────────────────────

class _PasswordRequirements extends StatelessWidget {
  final bool isDark;
  final String password;
  const _PasswordRequirements({required this.isDark, required this.password});

  @override
  Widget build(BuildContext context) {
    final checks = [
      (label: 'At least 8 characters', met: password.length >= 8),
      (label: 'One lowercase letter', met: RegExp(r'[a-z]').hasMatch(password)),
      (label: 'One uppercase letter', met: RegExp(r'[A-Z]').hasMatch(password)),
      (label: 'One number', met: RegExp(r'\d').hasMatch(password)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password must include:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black45,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          ...checks.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    c.met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: c.met ? Colors.green.shade500 : (isDark ? Colors.white30 : Colors.black26),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    c.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: c.met
                          ? Colors.green.shade600
                          : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
                      fontWeight: c.met ? FontWeight.w600 : FontWeight.normal,
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
