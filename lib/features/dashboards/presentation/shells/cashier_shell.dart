import 'package:flutter/material.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../screens/cashier_dashboard_screen.dart';
import '../../../../features/settings/presentation/screens/settings_screen.dart';

class CashierShell extends StatefulWidget {
  final UserModel user;

  const CashierShell({super.key, required this.user});

  @override
  State<CashierShell> createState() => _CashierShellState();
}

class _CashierShellState extends State<CashierShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      CashierDashboardScreen(user: widget.user),
      const Center(child: Text('Billing Screen Placeholder')),
      const Center(child: Text('Orders Screen Placeholder')),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Billing'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
