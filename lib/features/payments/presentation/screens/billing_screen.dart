import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/utils/table_formatter.dart';
import '../../../dashboards/presentation/cubit/dashboard_cubit.dart';
import '../../../dashboards/presentation/cubit/dashboard_state.dart';
import 'checkout_screen.dart';
import 'billing_history_screen.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_shimmer.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().fetchDashboard('cashier');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Bills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Billing History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BillingHistoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                LoadingShimmer.list(count: 5),
              ],
            );
          } else if (state is DashboardError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Failed to load bills',
              subtitle: state.message,
              action: ElevatedButton(
                onPressed: () => context.read<DashboardCubit>().fetchDashboard('cashier'),
                child: const Text('Try Again'),
              ),
            );
          } else if (state is DashboardLoaded) {
            return _buildBillsList(context, state.data);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBillsList(BuildContext context, Map<String, dynamic> data) {
    final servedOrders = (data['recentOrders'] as List<dynamic>?)?.toList() ?? [];

    if (servedOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<DashboardCubit>().fetchDashboard('cashier'),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            EmptyState(
              icon: Icons.check_circle_outline,
              title: 'No pending bills',
              subtitle: 'All served orders have been paid for.',
            ),
          ],
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().fetchDashboard('cashier'),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: servedOrders.length,
        itemBuilder: (context, index) {
          final order = servedOrders[index];

          // Calculate subtotal
          double subtotal = 0;
          final items = order['items'] as List<dynamic>? ?? [];
          for (var item in items) {
            if (item['status'] != 'cancelled') {
              subtotal += (item['price'] as num) * (item['quantity'] as num);
            }
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.receipt_long, color: Colors.white),
              ),
              title: Text('Table ${TableFormatter.format(order['table_section'], order['table_number'], order['table_id']?.toString())}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${items.length} items • ${currencyFormat.format(subtotal)}',
              ),
              trailing: FilledButton(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
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
                child: const Text('Checkout'),
              ),
            ),
          );
        },
      ),
    );
  }
}
