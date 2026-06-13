import 'package:sajilo_restro_sewa/core/errors/app_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/screens/order_details_screen.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';

class WaiterDashboardScreen extends StatefulWidget {
  final UserModel user;

  const WaiterDashboardScreen({super.key, required this.user});

  @override
  State<WaiterDashboardScreen> createState() => _WaiterDashboardScreenState();
}

class _WaiterDashboardScreenState extends State<WaiterDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().fetchDashboard('waiter');
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
                onPressed: () => context.read<DashboardCubit>().fetchDashboard('waiter'),
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

  Widget _buildDashboard(BuildContext context, Map<String, dynamic> data) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().fetchDashboard('waiter'),
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
                icon: Icons.assignment,
                iconColor: Colors.blue,
                label: "My Orders Today",
                value: (data['myOrdersToday'] ?? 0).toString(),
              ),
              StatCard(
                icon: Icons.restaurant,
                iconColor: Colors.orange,
                label: "My Active Orders",
                value: (data['activeOrders'] ?? 0).toString(),
              ),
              StatCard(
                icon: Icons.table_restaurant,
                iconColor: Colors.green,
                label: "Tables Available",
                value: (data['tableStats']?['available'] ?? 0).toString(),
              ),
              StatCard(
                icon: Icons.people,
                iconColor: Colors.red,
                label: "Tables Occupied",
                value: (data['tableStats']?['occupied'] ?? 0).toString(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: "Recent Orders Activity"),
          if ((data['recentOrders'] as List?)?.isEmpty ?? true)
            const EmptyState(
              icon: Icons.receipt_long,
              title: "No orders yet",
              subtitle: "Start taking orders to see them here.",
            )
          else
            ...(data['recentOrders'] as List<dynamic>).map((order) {
              final theme = Theme.of(context);
              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 8),
                elevation: theme.brightness == Brightness.light ? 0 : 1,
                shape: RoundedRectangleBorder(
                  side: theme.brightness == Brightness.light 
                      ? BorderSide(color: theme.colorScheme.outlineVariant) 
                      : BorderSide.none,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.receipt, color: Colors.white),
                  ),
                  title: Text('Order #${(order['id']?.toString() ?? 'UNKNOWN').length > 6 ? (order['id']?.toString() ?? 'UNKNOWN').substring(0, 6) : (order['id']?.toString() ?? 'UNKNOWN')}'.toUpperCase()),
                  subtitle: Text(
                    '${(order['status']?.toString() ?? 'Unknown').toUpperCase()} • ${order['items']?.length ?? 0} items',
                  ),
                  trailing: Text(
                    DateFormat('h:mm a').format(DateTime.parse(order['createdAt']?.toString() ?? DateTime.now().toIso8601String())),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    try {
                      final orderModel = OrderModel.fromJson(order as Map<String, dynamic>);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailsScreen(order: orderModel),
                        ),
                      );
                    } catch (e) {
                      AppErrorHandler.showError(context, 'Could not load order details: $e');
                    }
                  },
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
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
}
