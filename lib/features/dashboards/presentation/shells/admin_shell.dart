import 'package:flutter/material.dart';
import '../../../../shared/widgets/responsive_shell.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../screens/admin_dashboard_screen.dart';
import '../../../../features/settings/presentation/screens/settings_screen.dart';
import '../screens/manage_screen.dart';
import '../../../../features/payments/presentation/screens/billing_history_screen.dart';
import '../../../../features/payments/presentation/screens/details_panel_widget.dart';

class AdminShell extends StatelessWidget {
  final UserModel user;

  const AdminShell({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      endDrawer: DetailsPanelWidget(),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Manage'),
        NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Billing'),
        NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      screens: [
        AdminDashboardScreen(user: user),
        const ManageScreen(),
        const BillingHistoryScreen(),
        const SettingsScreen(),
      ],
    );
  }
}
