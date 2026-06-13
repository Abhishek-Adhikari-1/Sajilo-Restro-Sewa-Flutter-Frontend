import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/screens/active_devices_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
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
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Log Out'),
                        content: const Text('Are you sure you want to log out of this device?'),
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
