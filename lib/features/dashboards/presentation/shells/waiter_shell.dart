import 'package:flutter/material.dart';
import '../../../../shared/widgets/responsive_shell.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../screens/waiter_dashboard_screen.dart';
import '../../../../features/settings/presentation/screens/settings_screen.dart';
import '../../../../features/orders/presentation/screens/active_orders_screen.dart';
import '../../../../features/tables/presentation/screens/tables_screen.dart';

class WaiterShell extends StatelessWidget {
  final UserModel user;

  const WaiterShell({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.table_restaurant), label: 'Tables'),
        NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
        NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      screens: [
        WaiterDashboardScreen(user: user),
        const TablesScreen(),
        const ActiveOrdersScreen(),
        const SettingsScreen(),
      ],
    );
  }
}
