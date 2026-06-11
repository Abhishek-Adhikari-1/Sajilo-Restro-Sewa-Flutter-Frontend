import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/data/models/user_model.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';

class KitchenDashboardScreen extends StatefulWidget {
  final UserModel user;

  const KitchenDashboardScreen({super.key, required this.user});

  @override
  State<KitchenDashboardScreen> createState() => _KitchenDashboardScreenState();
}

class _KitchenDashboardScreenState extends State<KitchenDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().fetchDashboard('kitchen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getGreeting(), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'Welcome back, ${widget.user.firstName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                LoadingShimmer.grid(count: 2),
                const SizedBox(height: 24),
                LoadingShimmer.list(count: 3),
              ],
            );
          } else if (state is DashboardError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Failed to load dashboard',
              subtitle: state.message,
              action: ElevatedButton(
                onPressed: () => context.read<DashboardCubit>().fetchDashboard('kitchen'),
                child: const Text('Try Again'),
              ),
            );
          } else if (state is DashboardLoaded) {
            return _buildDashboard(context, state.data);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    if (hour < 20) return 'Good Evening 🌙';
    return 'Good Night 😴';
  }

  Widget _buildDashboard(BuildContext context, Map<String, dynamic> data) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().fetchDashboard('kitchen'),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: isDesktop ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: isDesktop ? 2.5 : 1.1,
            children: [
              StatCard(
                icon: Icons.pending_actions,
                iconColor: Colors.orange,
                label: "Pending Orders",
                value: (data['pendingOrders'] ?? 0).toString(),
              ),
              StatCard(
                icon: Icons.outdoor_grill,
                iconColor: Colors.blue,
                label: "Preparing Now",
                value: (data['preparingOrders'] ?? 0).toString(),
              ),
              StatCard(
                icon: Icons.room_service,
                iconColor: Colors.green,
                label: "Ready to Serve",
                value: (data['readyOrders'] ?? 0).toString(),
              ),
              StatCard(
                icon: Icons.check_circle_outline,
                iconColor: Colors.purple,
                label: "Completed Today",
                value: (data['completedToday'] ?? 0).toString(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: "Active Order Queue"),
          if ((data['recentOrders'] as List?)?.isEmpty ?? true)
            const EmptyState(
              icon: Icons.restaurant_menu,
              title: "Kitchen is clear",
              subtitle: "No active orders in the queue right now.",
            )
          else
            ...(data['recentOrders'] as List<dynamic>).map((order) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: order['status'] == 'pending' 
                        ? Colors.orange.withValues(alpha: 0.2)
                        : Colors.blue.withValues(alpha: 0.2),
                    child: Icon(
                      order['status'] == 'pending' ? Icons.timer : Icons.outdoor_grill,
                      color: order['status'] == 'pending' ? Colors.orange : Colors.blue,
                    ),
                  ),
                  title: Text('Table ${order['table_number'] ?? (order['table_id']?.toString() ?? 'UKWN').substring(0, 4)}'),
                  subtitle: Text('Status: ${order['status']?.toString() ?? 'Unknown'}'),
                  children: [
                    for (var item in (order['items'] as List<dynamic>? ?? []))
                      ListTile(
                        title: Text(item['name']?.toString() ?? 'Unknown Item'),
                        subtitle: item['special_instructions'] != null
                            ? Text('Note: ${item['special_instructions']}', 
                                style: const TextStyle(color: Colors.red))
                            : null,
                        trailing: Text('x${item['quantity']}', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      )
                  ],
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
