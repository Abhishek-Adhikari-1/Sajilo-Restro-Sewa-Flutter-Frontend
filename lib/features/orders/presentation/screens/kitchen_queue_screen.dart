import 'package:sajilo_restro_sewa/core/errors/app_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../cubit/order_cubit.dart';
import '../../data/models/order_model.dart';
import '../../../tables/presentation/cubit/table_cubit.dart';
import '../../../../shared/utils/table_formatter.dart';

class KitchenQueueScreen extends StatefulWidget {
  const KitchenQueueScreen({super.key});

  @override
  State<KitchenQueueScreen> createState() => _KitchenQueueScreenState();
}

class _KitchenQueueScreenState extends State<KitchenQueueScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    context.read<TableCubit>().fetchTables();
    context.read<OrderCubit>().fetchActiveOrders();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      context.read<OrderCubit>().fetchActiveOrders();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<OrderCubit, OrderState>(
          builder: (context, state) {
            if (state is OrderLoaded) {
              final pending = state.orders.where((o) => o.status == 'pending').length;
              final preparing = state.orders.where((o) => o.status == 'preparing').length;
              final ready = state.orders.where((o) => o.status == 'ready').length;
              return Row(
                children: [
                  _buildStatBadge('Pending', pending, Colors.orange),
                  const SizedBox(width: 8),
                  _buildStatBadge('Preparing', preparing, Colors.blue),
                  const SizedBox(width: 8),
                  _buildStatBadge('Ready', ready, Colors.green),
                ],
              );
            }
            return const Text('Kitchen Orders');
          },
        ),
      ),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading && state is! OrderLoaded) {
            return Padding(
              padding: EdgeInsets.all(16.0),
              child: LoadingShimmer.card(height: double.infinity),
            );
          } else if (state is OrderError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Failed to load queue',
              subtitle: state.message,
              action: ElevatedButton(
                onPressed: () => context.read<OrderCubit>().fetchActiveOrders(),
                child: const Text('Try Again'),
              ),
            );
          } else if (state is OrderLoaded) {
            final pending = state.orders
                .where((o) => o.status == 'pending')
                .toList();
            final preparing = state.orders
                .where((o) => o.status == 'preparing')
                .toList();
            final ready = state.orders
                .where((o) => o.status == 'ready')
                .toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                // If it's a wide screen, show Kanban board. Otherwise, use horizontal PageView
                if (constraints.maxWidth > 800) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildColumn(
                          'Pending',
                          pending,
                          Colors.orange,
                          context,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: _buildColumn(
                          'Preparing',
                          preparing,
                          Colors.blue,
                          context,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: _buildColumn(
                          'Ready',
                          ready,
                          Colors.green,
                          context,
                        ),
                      ),
                    ],
                  );
                } else {
                  return PageView(
                    children: [
                      _buildColumn('Pending', pending, Colors.orange, context),
                      _buildColumn(
                        'Preparing',
                        preparing,
                        Colors.blue,
                        context,
                      ),
                      _buildColumn('Ready', ready, Colors.green, context),
                    ],
                  );
                }
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatBadge(String label, int count, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(
    String title,
    List<OrderModel> orders,
    MaterialColor color,
    BuildContext context,
  ) {
    return Container(
      color: color.withValues(alpha: 0.05),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(color: color.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.shade800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${orders.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Text(
                      'No orders',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(orders[index], context);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, BuildContext context) {
    final theme = Theme.of(context);
    final isPending = order.status == 'pending';
    final isPreparing = order.status == 'preparing';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Table ${TableFormatter.format(order.tableSection, order.tableNumber, order.tableId)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  timeago(order.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                ),
              ],
            ),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.notes!,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.quantity}x ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (item.specialInstructions != null &&
                              item.specialInstructions!.isNotEmpty)
                            Text(
                              item.specialInstructions!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            item.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getItemStatusColor(item.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.status == 'pending')
                      FilledButton.tonalIcon(
                        onPressed: () {
                          context.read<OrderCubit>().updateOrderItemStatus(
                            order.id,
                            item.id,
                            'preparing',
                          );
                        },
                        icon: const Icon(Icons.soup_kitchen, size: 16),
                        label: const Text(
                          'Prepare',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(0, 32),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                    else if (item.status == 'preparing')
                      FilledButton.icon(
                        onPressed: () {
                          context.read<OrderCubit>().updateOrderItemStatus(
                            order.id,
                            item.id,
                            'ready',
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text(
                          'Ready',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(0, 32),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                    else if (item.status == 'ready')
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (isPending || isPreparing)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: isPending
                          ? Colors.blue.shade600
                          : Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: Icon(
                      isPending ? Icons.local_fire_department : Icons.done_all,
                      size: 20,
                    ),
                    onPressed: () {
                      final nextStatus = isPending ? 'preparing' : 'ready';
                      context.read<OrderCubit>().updateOrderStatus(
                        order.id,
                        nextStatus,
                      );
                      AppErrorHandler.show(context, 'Order moved to $nextStatus');
                    },
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isPending ? 'START COOKING ALL' : 'MARK ALL READY',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String timeago(DateTime d) {
    Duration diff = DateTime.now().difference(d);
    if (diff.inHours > 0) {
      return "${diff.inHours}h ago";
    } else if (diff.inMinutes > 0) {
      return "${diff.inMinutes}m ago";
    } else {
      return "just now";
    }
  }

  Color _getItemStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'served':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
