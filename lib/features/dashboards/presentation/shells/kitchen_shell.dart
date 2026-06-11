import 'package:flutter/material.dart';
import '../../../../shared/widgets/responsive_shell.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../screens/kitchen_dashboard_screen.dart';
import '../../../../features/settings/presentation/screens/settings_screen.dart';
import '../../../../features/orders/presentation/screens/kitchen_queue_screen.dart';

class KitchenShell extends StatelessWidget {
  final UserModel user;

  const KitchenShell({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
        NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      screens: [
        KitchenDashboardScreen(user: user),
        const KitchenQueueScreen(),
        const SettingsScreen(),
      ],
    );
  }
}
