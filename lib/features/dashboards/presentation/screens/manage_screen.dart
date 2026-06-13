import 'package:flutter/material.dart';
import '../../../../features/menu/presentation/screens/admin_categories_screen.dart';
import '../../../../features/menu/presentation/screens/admin_menu_screen.dart';
import '../../../../features/orders/presentation/screens/active_orders_screen.dart';
import '../../../../features/staff/presentation/screens/staff_list_screen.dart';
import '../../../../features/tables/presentation/screens/admin_tables_screen.dart';

class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage'),
        scrolledUnderElevation: 0.0,
      ),
      body: GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildManageCard(
            context,
            title: 'Categories',
            icon: Icons.category,
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()),
            ),
          ),
          _buildManageCard(
            context,
            title: 'Menu',
            icon: Icons.restaurant_menu,
            color: Colors.red,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminMenuScreen()),
            ),
          ),
          _buildManageCard(
            context,
            title: 'Orders',
            icon: Icons.receipt_long,
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ActiveOrdersScreen()),
            ),
          ),
          _buildManageCard(
            context,
            title: 'Staff',
            icon: Icons.people,
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StaffListScreen()),
            ),
          ),
          _buildManageCard(
            context,
            title: 'Tables',
            icon: Icons.table_restaurant,
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminTablesScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
