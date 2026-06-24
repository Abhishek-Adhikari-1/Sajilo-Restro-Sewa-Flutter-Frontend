import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/utils/table_formatter.dart';
import '../cubit/side_panel_cubit.dart';
import '../cubit/side_panel_state.dart';

class DetailsPanelWidget extends StatelessWidget {
  final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
  final dateFormat = DateFormat('MMM dd, yyyy h:mm a');

  DetailsPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 400,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: BlocBuilder<SidePanelCubit, SidePanelState>(
        builder: (context, state) {
          if (state is SidePanelLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SidePanelError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (state is SidePanelOrderLoaded) {
            final order = state.order;
            return _buildOrderDetails(context, order);
          } else if (state is SidePanelCustomerLoaded) {
            final customer = state.customer;
            return _buildCustomerDetails(context, customer);
          }
          return const Center(child: Text('Select an ID to view details.'));
        },
      ),
    );
  }

  Widget _buildOrderDetails(BuildContext context, dynamic order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: isDark 
                ? Theme.of(context).colorScheme.surfaceContainerHighest 
                : Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Order Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('#${order.id}'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status: ${order.status.toUpperCase()}'),
                  Text('Table: ${TableFormatter.format(order.tableSection, int.tryParse(order.tableNumber ?? ''), order.tableId ?? '')}'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.createdByName != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: order.createdByImage != null ? NetworkImage(order.createdByImage) : null,
                      child: order.createdByImage == null ? const Icon(Icons.person) : null,
                    ),
                    title: const Text('Served By'),
                    subtitle: Text(order.createdByName),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people, size: 20, color: Theme.of(context).colorScheme.onPrimaryContainer),
                          const SizedBox(width: 8),
                          Text('${order.guestsCount}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                        ],
                      ),
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people, size: 20, color: Theme.of(context).colorScheme.onPrimaryContainer),
                          const SizedBox(width: 8),
                          Text('${order.guestsCount}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Created:', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
                        Text(dateFormat.format(order.createdAt.toLocal()), style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Updated:', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
                        Text(dateFormat.format(order.updatedAt.toLocal()), style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ],
                ),
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes, size: 20, color: Theme.of(context).colorScheme.onTertiaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Notes to Kitchen: ${order.notes}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onTertiaryContainer,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 32),
                Text('Order Items', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...order.items.map<Widget>((item) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${item.quantity}x ${item.menuName}'),
                    subtitle: item.notes != null ? Text('Note: ${item.notes}') : null,
                    trailing: Text(currencyFormat.format(item.priceAtTime * item.quantity)),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDetails(BuildContext context, customer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: isDark 
                ? Theme.of(context).colorScheme.surfaceContainerHighest 
                : Theme.of(context).colorScheme.tertiaryContainer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Customer Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('#${customer.id}'),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Name'),
          subtitle: Text(customer.name),
        ),
        ListTile(
          leading: const Icon(Icons.phone),
          title: const Text('Phone'),
          subtitle: Text(customer.phone ?? 'No phone provided'),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Registered On'),
          subtitle: Text(dateFormat.format(customer.createdAt.toLocal())),
        ),
      ],
    );
  }
}
