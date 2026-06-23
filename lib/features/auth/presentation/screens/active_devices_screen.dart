import 'package:flutter/material.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/models/active_session_model.dart';
import 'package:intl/intl.dart';

class ActiveDevicesScreen extends StatefulWidget {
  const ActiveDevicesScreen({super.key});

  @override
  State<ActiveDevicesScreen> createState() => _ActiveDevicesScreenState();
}

class _ActiveDevicesScreenState extends State<ActiveDevicesScreen> {
  final AuthRepository _repository = AuthRepository();
  bool _isLoading = true;
  List<ActiveSessionModel> _sessions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final sessions = await _repository.getSessions();
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _parseDeviceName(String? userAgent) {
    if (userAgent == null || userAgent.isEmpty) return 'Unknown Device';
    final ua = userAgent.toLowerCase();

    // Flutter/Dart HTTP client — try to extract info from our custom UA
    // e.g. "SajiloRestroSewa/1.0.0 (Android 13; samsung SM-G991B)"
    // or legacy: "Dart/3.12 (dart:io)"
    if (ua.startsWith('dart/') || ua.contains('dart:io')) {
      // Check if our new UA format embedded OS info in parentheses
      final parenMatch = RegExp(r'\(([^)]+)\)').firstMatch(userAgent);
      if (parenMatch != null) {
        final inside = parenMatch.group(1)!.trim(); // e.g. "Android 13; samsung SM-G991B"
        if (inside.isNotEmpty && !inside.contains('dart:io')) {
          return 'Flutter App ($inside)';
        }
      }
      return 'Flutter App';
    }

    // Custom UA we now send: "AppName/version (OS info; device)"
    // e.g. "SajiloRestroSewa/1.0.0 (Android 13; samsung SM-G991B)"
    if (ua.contains('sajilorestrosewa') || ua.contains('sajilo')) {
      final parenMatch = RegExp(r'\(([^)]+)\)').firstMatch(userAgent);
      if (parenMatch != null) {
        return 'App – ${parenMatch.group(1)!.trim()}';
      }
      return 'Sajilo App';
    }

    // Standard browser UA parsing
    String os = '';
    String client = '';

    // OS detection (order matters — Android before Linux)
    if (ua.contains('android')) {
      // Try to extract Android version
      final vMatch = RegExp(r'android (\d+[\d.]*)').firstMatch(ua);
      os = vMatch != null ? 'Android ${vMatch.group(1)}' : 'Android';
    } else if (ua.contains('iphone')) {
      final vMatch = RegExp(r'os ([\d_]+) like').firstMatch(ua);
      final v = vMatch?.group(1)?.replaceAll('_', '.') ?? '';
      os = v.isNotEmpty ? 'iPhone (iOS $v)' : 'iPhone';
    } else if (ua.contains('ipad')) {
      os = 'iPad';
    } else if (ua.contains('windows nt')) {
      final vMatch = RegExp(r'windows nt ([\d.]+)').firstMatch(ua);
      final v = vMatch?.group(1);
      final winName = const {
        '10.0': '10/11', '6.3': '8.1', '6.2': '8', '6.1': '7',
      }[v] ?? v ?? '';
      os = 'Windows${winName.isNotEmpty ? ' $winName' : ''}';
    } else if (ua.contains('mac os x') || ua.contains('macintosh')) {
      os = 'Mac';
    } else if (ua.contains('linux')) {
      os = 'Linux';
    } else {
      os = 'Unknown OS';
    }

    // Browser/client detection
    if (ua.contains('edg/') || ua.contains('edga/') || ua.contains('edgios/')) {
      client = 'Edge';
    } else if (ua.contains('opr/') || ua.contains('opera')) {
      client = 'Opera';
    } else if (ua.contains('chrome/') || ua.contains('crios/')) {
      client = 'Chrome';
    } else if (ua.contains('firefox/') || ua.contains('fxios/')) {
      client = 'Firefox';
    } else if (ua.contains('safari/') && !ua.contains('chrome')) {
      client = 'Safari';
    } else if (ua.contains('samsung')) {
      client = 'Samsung Browser';
    } else {
      client = 'Browser';
    }

    return '$client on $os';
  }

  IconData _getDeviceIcon(String? userAgent) {
    if (userAgent == null || userAgent.isEmpty) return Icons.device_unknown_outlined;
    final ua = userAgent.toLowerCase();

    if (ua.startsWith('dart/') || ua.contains('dart:io') ||
        ua.contains('sajilorestrosewa') || ua.contains('sajilo')) {
      // Our Flutter app
      if (ua.contains('android') || ua.contains('ios') || ua.contains('iphone')) {
        return Icons.phone_android;
      }
      return Icons.phone_android; // default to phone for app sessions
    }
    if (ua.contains('ipad') || ua.contains('tablet')) return Icons.tablet_android;
    if (ua.contains('mobile') || ua.contains('android') || ua.contains('iphone')) {
      return Icons.phone_android;
    }
    if (ua.contains('windows') || ua.contains('mac') || ua.contains('linux')) {
      return Icons.computer;
    }
    return Icons.devices_other;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Active Devices')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load devices',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _fetchSessions,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _sessions.length + 1,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == _sessions.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: FilledButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Log Out All Devices'),
                            content: const Text(
                              'This will log you out from all other devices except this one. Continue?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  try {
                                    setState(() => _isLoading = true);
                                    await _repository.logoutAll();
                                    await _fetchSessions();
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Logged out from all other devices',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text('Failed: $e')),
                                      );
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Log Out Others'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.phonelink_erase),
                      label: const Text('Log out from other devices'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                    ),
                  );
                }

                final session = _sessions[index];
                final deviceName = _parseDeviceName(session.userAgent);
                final icon = _getDeviceIcon(session.userAgent);

                return ListTile(
                  onTap: () => _showSessionDetails(context, session, deviceName, icon),
                  leading: CircleAvatar(
                    backgroundColor: session.isCurrent
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: session.isCurrent
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    child: Icon(icon),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          deviceName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (session.isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Current',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (session.ipAddress != null)
                        Text('IP: ${session.ipAddress}'),
                      Text(
                        'Started: ${DateFormat.yMMMd().add_jm().format(session.createdAt)}',
                      ),
                    ],
                  ),
                  isThreeLine: session.ipAddress != null,
                  trailing: const Icon(Icons.chevron_right, size: 20),
                );
              },
            ),
    );
  }

  void _showSessionDetails(
    BuildContext context,
    ActiveSessionModel session,
    String deviceName,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1208) : const Color(0xFFFFFBF7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: session.isCurrent
                                  ? accent.withValues(alpha: 0.15)
                                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08)),
                              border: Border.all(
                                color: session.isCurrent
                                    ? accent.withValues(alpha: 0.4)
                                    : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.12)),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              icon,
                              size: 26,
                              color: session.isCurrent
                                  ? accent
                                  : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deviceName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (session.isCurrent)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Current Session',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: accent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Divider(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
                        height: 1,
                      ),
                      const SizedBox(height: 20),

                      // Detail rows
                      _DetailRow(
                        icon: Icons.fingerprint_rounded,
                        label: 'Session ID',
                        value: session.id,
                        isDark: isDark,
                        monospace: true,
                      ),
                      if (session.ipAddress != null)
                        _DetailRow(
                          icon: Icons.language_rounded,
                          label: 'IP Address',
                          value: session.ipAddress!,
                          isDark: isDark,
                        ),
                      _DetailRow(
                        icon: Icons.login_rounded,
                        label: 'Logged In',
                        value: DateFormat('MMM d, yyyy • h:mm a').format(
                          session.createdAt.toLocal(),
                        ),
                        isDark: isDark,
                      ),
                      _DetailRow(
                        icon: Icons.timer_outlined,
                        label: 'Expires',
                        value: DateFormat('MMM d, yyyy • h:mm a').format(
                          session.expiresAt.toLocal(),
                        ),
                        isDark: isDark,
                      ),
                      _DetailRow(
                        icon: Icons.info_outline_rounded,
                        label: 'User Agent',
                        value: session.userAgent ?? 'Not available',
                        isDark: isDark,
                        monospace: true,
                        small: true,
                      ),

                      const SizedBox(height: 28),

                      // Sign out button (only for non-current sessions)
                      if (!session.isCurrent)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                setState(() => _isLoading = true);
                                await _repository.logoutAll();
                                await _fetchSessions();
                                if (mounted) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Device signed out'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Failed: $e')),
                                  );
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Sign Out This Device'),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                              foregroundColor: theme.colorScheme.onError,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                      if (session.isCurrent)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: accent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'This is your current session',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Detail Row Widget ────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool monospace;
  final bool small;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.monospace = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: small ? 12 : 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: monospace ? 'monospace' : null,
                    color: isDark ? Colors.white.withValues(alpha: 0.87) : const Color(0xFF111827),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

