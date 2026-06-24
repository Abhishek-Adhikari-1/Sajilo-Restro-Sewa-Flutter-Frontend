import 'package:sajilo_restro_sewa/core/errors/app_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';
import '../../../tables/presentation/cubit/table_cubit.dart';
import '../../../tables/presentation/cubit/table_state.dart';
import '../../../tables/data/models/table_model.dart';
import '../../../../shared/utils/table_formatter.dart';
import '../cubit/order_cubit.dart';
import 'create_order_screen.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel initialOrder;
  final TableModel? table; // Optionally pass the table if already known

  const OrderDetailsScreen({super.key, required OrderModel order, this.table}) : initialOrder = order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return BlocBuilder<OrderCubit, OrderState>(
      builder: (context, orderState) {
        OrderModel order = initialOrder;
        if (orderState is OrderLoaded) {
          try {
            order = orderState.orders.firstWhere((o) => o.id == initialOrder.id);
          } catch (e) {
            // keep initial
          }
        }

        return BlocBuilder<TableCubit, TableState>(
          builder: (context, tableState) {
        TableModel? currentTable = table;
        if (currentTable == null && tableState is TableLoaded) {
          try {
            currentTable = tableState.tables.firstWhere((t) => t.id == order.tableId);
          } catch (e) {
            // Table not found in state
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Order #${order.id.substring(0, 6).toUpperCase()}'),
            actions: [
              if (currentTable != null && ['pending', 'preparing', 'ready'].contains(order.status))
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Order Items',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateOrderScreen(
                          table: currentTable!,
                          existingOrder: order,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(theme, currentTable, order),
                const SizedBox(height: 16),
                _buildItemsList(context, theme, currencyFormat, order),
                const SizedBox(height: 16),
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  _buildNotesCard(theme, order),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        );
      },
    );
  });
  }

  Widget _buildInfoCard(ThemeData theme, TableModel? currentTable, OrderModel order) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(128)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow('Status', order.status.toUpperCase(), theme),
            const Divider(),
            _buildInfoRow('Table', currentTable != null ? TableFormatter.format(currentTable.section, currentTable.tableNumber) : TableFormatter.format(order.tableSection, order.tableNumber, order.tableId), theme),
            const Divider(),
            _buildInfoRow('Guests', '${order.guestsCount} People', theme),
            const Divider(),
            _buildInfoRow('Created', DateFormat('MMM d, h:mm a').format(order.createdAt), theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, ThemeData theme, NumberFormat format, OrderModel order) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(128)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order Items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (order.items.any((i) => i.status == 'ready'))
                  FilledButton.icon(
                    icon: const Icon(Icons.room_service, size: 16),
                    label: const Text('Serve All Ready'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.purple,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      for (var item in order.items) {
                        if (item.status == 'ready') {
                          context.read<OrderCubit>().updateOrderItemStatus(order.id, item.id, 'served');
                        }
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (item.specialInstructions != null)
                              Text('Note: ${item.specialInstructions}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(format.format(item.price * item.quantity), style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (item.status == 'ready') ...[
                            const SizedBox(height: 4),
                            OutlinedButton(
                              onPressed: () {
                                context.read<OrderCubit>().updateOrderItemStatus(order.id, item.id, 'served');
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(0, 24),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Serve', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount', style: theme.textTheme.titleMedium),
                Text(
                  format.format(order.totalAmount),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (order.status == 'served') ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'Mark Complete (Send to Billing)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: () {
                    context.read<OrderCubit>().updateOrderStatus(
                      order.id,
                      'billing',
                    );
                    Navigator.pop(context); // Go back after completing
                    AppErrorHandler.show(context, 'Order completed. Table seats are freed up!');
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(ThemeData theme, OrderModel order) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(128)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note_alt_outlined, size: 20),
                const SizedBox(width: 8),
                Text('Order Notes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(order.notes!),
          ],
        ),
      ),
    );
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
