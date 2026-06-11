import 'package:flutter/material.dart';
import '../../../../shared/widgets/responsive_shell.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../screens/cashier_dashboard_screen.dart';
import '../../../../features/settings/presentation/screens/settings_screen.dart';
import '../../../../features/orders/presentation/screens/active_orders_screen.dart';
import '../../../../features/payments/presentation/screens/billing_screen.dart';

class CashierShell extends StatelessWidget {
  final UserModel user;

  const CashierShell({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Billing'),
        NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
        NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      screens: [
        CashierDashboardScreen(user: user),
        const BillingScreen(),
        const ActiveOrdersScreen(),
        const SettingsScreen(),
      ],
    );
  }
}
