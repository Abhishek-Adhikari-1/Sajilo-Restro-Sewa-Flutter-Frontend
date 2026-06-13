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
    String os = '';
    String browser = '';

    if (ua.contains('windows')) {
      os = 'Windows';
    } else if (ua.contains('mac os x') || ua.contains('macintosh')) {
      os = 'Mac';
    } else if (ua.contains('android')) {
      os = 'Android';
    } else if (ua.contains('iphone') || ua.contains('ipad')) {
      os = 'iOS';
    } else if (ua.contains('linux')) {
      os = 'Linux';
    } else {
      os = 'Unknown OS';
    }

    if (ua.contains('chrome') && !ua.contains('edg') && !ua.contains('opr')) {
      browser = 'Chrome';
    } else if (ua.contains('safari') && !ua.contains('chrome')) {
      browser = 'Safari';
    } else if (ua.contains('firefox')) {
      browser = 'Firefox';
    } else if (ua.contains('edg')) {
      browser = 'Edge';
    } else if (ua.contains('opr') || ua.contains('opera')) {
      browser = 'Opera';
    } else {
      browser = 'Browser/App';
    }

    return '$browser on $os';
  }

  IconData _getDeviceIcon(String? userAgent) {
    if (userAgent == null) return Icons.device_unknown;
    final ua = userAgent.toLowerCase();
    if (ua.contains('mobile') ||
        ua.contains('android') ||
        ua.contains('iphone')) {
      return Icons.smartphone;
    }
    return Icons.computer;
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
                );
              },
            ),
    );
  }
}
