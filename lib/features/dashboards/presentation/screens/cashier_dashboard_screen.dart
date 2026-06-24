import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../shared/utils/table_formatter.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../../../payments/presentation/screens/checkout_screen.dart';
import '../../../orders/data/models/order_model.dart';

class CashierDashboardScreen extends StatefulWidget {
  final UserModel user;

  const CashierDashboardScreen({super.key, required this.user});

  @override
  State<CashierDashboardScreen> createState() => _CashierDashboardScreenState();
}

class _CashierDashboardScreenState extends State<CashierDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().fetchDashboard('cashier');
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
                onPressed: () => context.read<DashboardCubit>().fetchDashboard('cashier'),
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
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    final isDesktop = MediaQuery.of(context).size.width > 800;

    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().fetchDashboard('cashier'),
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
                label: "Pending Bills",
                value: (data['pendingBills'] ?? 0).toString(),
              ),
              StatCard(
                icon: Icons.payments,
                iconColor: Colors.green,
                label: "Today's Collection",
                value: currencyFormat.format(data['totalRevenue'] ?? 0),
              ),
              StatCard(
                icon: Icons.receipt_long,
                iconColor: Colors.blue,
                label: "Today's Sales",
                value: (data['salesCount'] ?? 0).toString(),
              ),
              StatCard(
                icon: Icons.discount,
                iconColor: Colors.purple,
                label: "Discounts Given",
                value: currencyFormat.format(data['totalDiscount'] ?? 0),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: "Orders Ready for Billing"),
          if ((data['recentOrders'] as List?)?.isEmpty ?? true)
            const EmptyState(
              icon: Icons.check_circle_outline,
              title: "All caught up",
              subtitle: "No pending bills at the moment.",
            )
          else
            ...(data['recentOrders'] as List<dynamic>).map((order) {
              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.attach_money, color: Colors.white),
                  ),
                  title: Text('Table ${TableFormatter.format(order['table_section'], order['table_number'], order['table_id']?.toString())}'),
                  subtitle: Text('${order['items']?.length ?? 0} items'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () {
                      final orderModel = OrderModel.fromJson(order as Map<String, dynamic>);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutScreen(order: orderModel),
                        ),
                      ).then((_) {
                        if (context.mounted) {
                          context.read<DashboardCubit>().fetchDashboard('cashier');
                        }
                      });
                    },
                    child: const Text('Bill Now'),
                  ),
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
