import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/screens/active_devices_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('enable_notifications') ?? true;
      _soundEnabled = prefs.getBool('enable_sound') ?? true;
      _vibrationEnabled = prefs.getBool('enable_vibration') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        setState(() => _notificationsEnabled = true);
        await prefs.setBool('enable_notifications', true);
      } else if (status.isPermanentlyDenied) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                'Notifications are permanently denied. Please enable them in System Settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
      } else {
        // Denied but not permanently
        setState(() => _notificationsEnabled = false);
        await prefs.setBool('enable_notifications', false);
      }
    } else {
      setState(() => _notificationsEnabled = false);
      await prefs.setBool('enable_notifications', false);
    }
  }

  Future<void> _toggleSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _soundEnabled = value);
    await prefs.setBool('enable_sound', value);
  }

  Future<void> _toggleVibration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _vibrationEnabled = value);
    await prefs.setBool('enable_vibration', value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader(title: 'Appearance'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return ExpansionTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Theme'),
                  subtitle: Text(
                    themeMode == ThemeMode.system
                        ? 'System Default'
                        : themeMode == ThemeMode.light
                        ? 'Light Theme'
                        : 'Dark Theme',
                  ),
                  children: [
                    RadioGroup<ThemeMode>(
                      groupValue: themeMode,
                      onChanged: (mode) {
                        if (mode != null) {
                          context.read<ThemeCubit>().setTheme(mode);
                        }
                      },
                      child: Column(
                        children: [
                          RadioListTile<ThemeMode>(
                            title: const Text('System Default'),
                            subtitle: const Text('Match device system theme'),
                            value: ThemeMode.system,
                            activeColor: theme.colorScheme.primary,
                            secondary: const Icon(Icons.brightness_auto),
                          ),
                          const Divider(height: 1),
                          RadioListTile<ThemeMode>(
                            title: const Text('Light Theme'),
                            value: ThemeMode.light,
                            activeColor: theme.colorScheme.primary,
                            secondary: const Icon(Icons.light_mode),
                          ),
                          const Divider(height: 1),
                          RadioListTile<ThemeMode>(
                            title: const Text('Dark Theme'),
                            value: ThemeMode.dark,
                            activeColor: theme.colorScheme.primary,
                            secondary: const Icon(Icons.dark_mode),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          const _SectionHeader(title: 'Alerts & Notifications'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Order Alerts'),
              subtitle: const Text('Manage incoming order notifications'),
              children: [
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Show visual alerts on your screen'),
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  secondary: const Icon(Icons.mark_chat_unread_outlined),
                  activeTrackColor: theme.colorScheme.primary.withAlpha(128),
                  activeThumbColor: theme.colorScheme.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Sound'),
                  subtitle: const Text('Play a sound when a new order arrives'),
                  value: _soundEnabled,
                  onChanged: _toggleSound,
                  secondary: const Icon(Icons.volume_up_outlined),
                  activeTrackColor: theme.colorScheme.primary.withAlpha(128),
                  activeThumbColor: theme.colorScheme.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Vibration'),
                  subtitle: const Text(
                    'Vibrate device when a new order arrives',
                  ),
                  value: _vibrationEnabled,
                  onChanged: _toggleVibration,
                  secondary: const Icon(Icons.vibration_outlined),
                  activeTrackColor: theme.colorScheme.primary.withAlpha(128),
                  activeThumbColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const _SectionHeader(title: 'Security'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.devices),
                  title: const Text('Active Devices'),
                  subtitle: const Text('Manage your active sessions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ActiveDevicesScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Log Out'),
                        content: const Text(
                          'Are you sure you want to log out of this device?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.read<AuthCubit>().logout();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Log Out'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              'Sajilo Restro Sewa v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
