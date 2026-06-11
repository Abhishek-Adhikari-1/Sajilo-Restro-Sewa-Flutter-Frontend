// // lib/features/dashboards/presentation/admin_dashboard.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../auth/presentation/../cubit/auth_cubit.dart';
// import '../../../auth/presentation/screens/login_screen.dart';

// class AdminDashboardScreen extends StatelessWidget {
//   const AdminDashboardScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Console'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () {
//               context.read<AuthCubit>().logout();
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (_) => const LoginScreen()),
//               );
//             },
//           ),
//         ],
//       ),
//       body: const Center(
//         child: Text('Welcome, Admin! Accessing system structures.'),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/data/models/user_model.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserModel user;

  const AdminDashboardScreen({super.key, required this.user});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().fetchDashboard('admin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard'),
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
                LoadingShimmer.grid(count: 4),
                const SizedBox(height: 24),
                LoadingShimmer.card(height: 200),
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
                onPressed: () => context.read<DashboardCubit>().fetchDashboard('admin'),
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
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().fetchDashboard('admin'),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            children: [
              StatCard(
                icon: Icons.payments,
                iconColor: Colors.green,
                label: "Today's Revenue",
                value: currencyFormat.format(data['totalRevenue'] ?? 0),
                trend: '+12%',
              ),
              StatCard(
                icon: Icons.receipt_long,
                iconColor: Colors.blue,
                label: "Total Orders",
                value: (data['totalOrders'] ?? 0).toString(),
              ),
              StatCard(
                icon: Icons.restaurant,
                iconColor: Colors.orange,
                label: "Active Orders",
                value: (data['activeOrders'] ?? 0).toString(),
              ),
              StatCard(
                icon: Icons.people,
                iconColor: Colors.purple,
                label: "Active Staff",
                value: "${data['staffCount']?['active'] ?? 0}/${data['staffCount']?['total'] ?? 0}",
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: "Revenue Overview"),
          SizedBox(
            height: 200,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 3000),
                          FlSpot(1, 4500),
                          FlSpot(2, 3200),
                          FlSpot(3, 8000),
                          FlSpot(4, 5500),
                          FlSpot(5, 7500),
                          FlSpot(6, 12000),
                        ],
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: "Top Menu Items"),
          ...(data['topMenuItems'] as List<dynamic>? ?? []).map((item) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  (item['name']?.toString() ?? '?').isNotEmpty ? (item['name']?.toString() ?? '?').substring(0, 1) : '?',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
              title: Text(item['name']?.toString() ?? 'Unknown Item'),
              trailing: Text(
                '${item['count'] ?? 0} sold',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
