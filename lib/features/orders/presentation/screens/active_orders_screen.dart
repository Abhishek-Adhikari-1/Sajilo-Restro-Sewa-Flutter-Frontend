import 'package:sajilo_restro_sewa/core/errors/app_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../tables/data/models/table_model.dart';
import '../cubit/order_cubit.dart';
import '../../data/models/order_model.dart';
import 'create_order_screen.dart';
import 'order_details_screen.dart';
import '../../../../shared/widgets/custom_filter_chip.dart';
import '../../../tables/presentation/screens/tables_screen.dart';
import '../../../../shared/utils/table_formatter.dart';

class ActiveOrdersScreen extends StatefulWidget {
  final TableModel? table;

  const ActiveOrdersScreen({super.key, this.table});

  @override
  State<ActiveOrdersScreen> createState() => _ActiveOrdersScreenState();
}

class _ActiveOrdersScreenState extends State<ActiveOrdersScreen> {
  final currencyFormat = NumberFormat.currency(
    symbol: 'Rs. ',
    decimalDigits: 0,
  );
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    context.read<OrderCubit>().fetchActiveOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Orders"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (widget.table == null)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New Order',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TablesScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading && state is! OrderLoaded) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: LoadingShimmer.list(count: 3),
            );
          } else if (state is OrderError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Failed to load orders',
              subtitle: state.message,
              action: ElevatedButton(
                onPressed: () => context.read<OrderCubit>().fetchActiveOrders(),
                child: const Text('Try Again'),
              ),
            );
          } else if (state is OrderLoaded) {
            // Filter orders for this specific table if table is provided
            var tableOrders = widget.table != null
                ? state.orders
                      .where((o) => o.tableId == widget.table!.id)
                      .toList()
                : state.orders;

            if (_selectedFilter != 'All') {
              tableOrders = tableOrders
                  .where(
                    (o) =>
                        o.status.toLowerCase() == _selectedFilter.toLowerCase(),
                  )
                  .toList();
            }

            return Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: tableOrders.isEmpty
                      ? EmptyState(
                          icon: Icons.receipt_long,
                          title: 'No Active Orders',
                          subtitle: widget.table != null
                              ? 'This table currently has no active orders.'
                              : 'There are no active orders.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: tableOrders.length,
                          itemBuilder: (context, index) {
                            final order = tableOrders[index];
                            return _buildOrderCard(order, context);
                          },
                        ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton:
          widget.table != null && widget.table!.capacity > widget.table!.occupiedSeats && widget.table!.status != 'reserved'
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateOrderScreen(table: widget.table!),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('New Order'),
            )
          : null,
    );
  }

  Widget _buildFilters() {
    final filters = ['All', 'Pending', 'Preparing', 'Ready', 'Served'];
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CustomFilterChip(
              label: filter,
              isSelected: _selectedFilter == filter,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter);
                }
              },
            ),
          );
        }).toList(),
      ),
    ));
  }

  Widget _buildOrderCard(OrderModel order, BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(128)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OrderDetailsScreen(order: order, table: widget.table),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 6).toUpperCase()}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        order.status,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.table == null) ...[
                    const Icon(
                      Icons.table_restaurant,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Table ${TableFormatter.format(order.tableSection, order.tableNumber, order.tableId)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                  ],
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${order.guestsCount} Guests',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const Divider(height: 24),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.quantity}x ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(child: Text(item.name)),
                      Text(currencyFormat.format(item.price * item.quantity)),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total:', style: theme.textTheme.titleMedium),
                  Text(
                    currencyFormat.format(order.totalAmount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (order.status == 'ready')
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.room_service),
                    label: const Text(
                      'Mark as Served',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      context.read<OrderCubit>().updateOrderStatus(
                        order.id,
                        'served',
                      );
                      AppErrorHandler.show(context, 'Order marked as served!');
                    },
                  ),
                ),
              if (order.status == 'served')
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check_circle),
                    label: const Text(
                      'Mark Complete (Send to Billing)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      context.read<OrderCubit>().updateOrderStatus(
                        order.id,
                        'billing',
                      );
                      AppErrorHandler.show(context, 'Order completed. Table seats are freed up!');
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'served':
        return Colors.purple;
      case 'paid':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
