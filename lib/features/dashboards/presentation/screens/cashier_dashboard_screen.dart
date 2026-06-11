import 'package:flutter/material.dart';
import '../../../../features/auth/data/models/user_model.dart';

class CashierDashboardScreen extends StatelessWidget {
  final UserModel user;

  const CashierDashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashier Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  child: const Icon(Icons.person),
                ),
                title: Text('${user.firstName} ${user.lastName}'),
                subtitle: Text(user.role.toUpperCase()),
              ),
            ),
            const SizedBox(height: 24),
            // Cashier specific content
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.point_of_sale, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Ready for billing', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
