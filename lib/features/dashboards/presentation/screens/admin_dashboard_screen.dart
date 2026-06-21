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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
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
        actions: [
          BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
              String currentPeriod = 'today';
              if (state is DashboardLoaded) {
                currentPeriod = state.data['period'] ?? 'today';
              }
              return DropdownButton<String>(
                value: currentPeriod,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'today', child: Text('Today')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                ],
                onChanged: (val) {
                  if (val != null && val != currentPeriod) {
                    context.read<DashboardCubit>().fetchDashboard('admin', period: val);
                  }
                },
              );
            },
          ),
          const SizedBox(width: 16),
        ],
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
    final period = data['period'] ?? 'today';
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().fetchDashboard('admin', period: period),
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
                icon: Icons.payments,
                iconColor: Colors.green,
                label: "Revenue",
                value: currencyFormat.format(data['totalRevenue'] ?? 0),
              ),
              StatCard(
                icon: Icons.receipt_long,
                iconColor: Colors.red,
                label: "Expenses",
                value: currencyFormat.format(data['totalExpenses'] ?? 0),
              ),
              StatCard(
                icon: Icons.restaurant,
                iconColor: Colors.orange,
                label: "Active Orders",
                value: (data['activeOrdersCount'] ?? 0).toString(),
              ),
              StatCard(
                icon: Icons.table_restaurant,
                iconColor: Colors.purple,
                label: "Tables (Occ/Avail)",
                value: "${data['tableStats']?['occupied'] ?? 0}/${data['tableStats']?['available'] ?? 0}",
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: "Income vs Expenses"),
          SizedBox(
            height: 250,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Builder(
                  builder: (context) {
                    final revenueTrend = data['revenueTrend'] as List<dynamic>? ?? [];
                    final expenseTrend = data['expenseTrend'] as List<dynamic>? ?? [];
                    
                    if (revenueTrend.isEmpty && expenseTrend.isEmpty) {
                      return const Center(child: Text("No financial data for this period."));
                    }

                    // Combine labels from both revenue and expenses to ensure all points are covered
                    Set<String> labelsSet = {};
                    for (var r in revenueTrend) { labelsSet.add(r['label']); }
                    for (var e in expenseTrend) { labelsSet.add(e['label']); }
                    List<String> sortedLabels = labelsSet.toList()..sort();

                    List<BarChartGroupData> barGroups = [];
                    double maxY = 0;

                    for (int i = 0; i < sortedLabels.length; i++) {
                      final label = sortedLabels[i];
                      
                      final revItem = revenueTrend.firstWhere((r) => r['label'] == label, orElse: () => null);
                      final revVal = (revItem?['value'] ?? 0).toDouble();
                      
                      final expItem = expenseTrend.firstWhere((e) => e['label'] == label, orElse: () => null);
                      final expVal = (expItem?['value'] ?? 0).toDouble();

                      if (revVal > maxY) maxY = revVal;
                      if (expVal > maxY) maxY = expVal;
                      
                      barGroups.add(
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: revVal,
                              color: Colors.green.shade400,
                              width: 12,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: expVal,
                              color: Colors.red.shade400,
                              width: 12,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 12, height: 12, color: Colors.green.shade400),
                            const SizedBox(width: 4),
                            const Text("Income", style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 16),
                            Container(width: 12, height: 12, color: Colors.red.shade400),
                            const SizedBox(width: 4),
                            const Text("Expenses", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: BarChart(
                            BarChartData(
                              maxY: maxY * 1.2,
                              barGroups: barGroups,
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= 0 && value.toInt() < sortedLabels.length) {
                                        final labelRaw = sortedLabels[value.toInt()];
                                        String label = labelRaw;
                                        if (labelRaw.length > 10) {
                                          if (period == 'today') {
                                            label = labelRaw.substring(11, 16); // HH:MM
                                          } else {
                                            label = labelRaw.substring(5, 10); // MM-DD
                                          }
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(label, style: const TextStyle(fontSize: 10)),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: "Order Status Distribution"),
          SizedBox(
            height: 250,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Builder(
                builder: (context) {
                  final statusDist = data['orderStatusDistribution'] as List<dynamic>? ?? [];
                  if (statusDist.isEmpty) {
                    return const Center(child: Text("No orders found for this period."));
                  }

                  List<PieChartSectionData> pieSections = [];
                  final List<Color> colors = [Colors.blue, Colors.orange, Colors.green, Colors.red, Colors.purple, Colors.teal, Colors.brown];
                  
                  for (int i = 0; i < statusDist.length; i++) {
                    final item = statusDist[i];
                    final val = (item['count'] ?? 0).toDouble();
                    final status = item['status']?.toString().toUpperCase() ?? 'UNKNOWN';
                    
                    pieSections.add(
                      PieChartSectionData(
                        color: colors[i % colors.length],
                        value: val,
                        title: '$status\n(${val.toInt()})',
                        radius: 80,
                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    );
                  }

                  return PieChart(
                    PieChartData(
                      sections: pieSections,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  );
                }
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: "Recent Active Orders"),
          ...(data['recentOrders'] as List<dynamic>? ?? []).map((item) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  '#${item['orderNumber'] ?? item['id']?.toString().substring(0, 3) ?? '?'}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 12),
                ),
              ),
              title: Text('Table ${item['table_number'] ?? item['table_id'] ?? 'Unknown'}'),
              trailing: Text(
                item['status']?.toString().toUpperCase() ?? 'PENDING',
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
