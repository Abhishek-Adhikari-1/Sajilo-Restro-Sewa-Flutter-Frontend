import 'package:sajilo_restro_sewa/core/errors/app_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/table_cubit.dart';
import '../cubit/table_state.dart';
import '../../../../features/orders/presentation/screens/create_order_screen.dart';
import '../../../../features/orders/presentation/screens/active_orders_screen.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/widgets/custom_filter_chip.dart';
import '../../../../shared/widgets/table_card.dart';
import '../../../../shared/utils/table_formatter.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  final List<String> _filters = [
    'all',
    'available',
    'reserved',
    'occupied',
    'unavailable',
  ];
  String _currentFilter = 'all';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final state = context.read<TableCubit>().state;
    if (state is TableLoaded) {
      _currentFilter = state.currentStatus ?? 'all';
    }
    if (state is TableInitial) {
      context.read<TableCubit>().fetchTables();
    }
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      final state = context.read<TableCubit>().state;
      if (state is TableLoaded) {
        context.read<TableCubit>().fetchMoreTables(state.limit);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildEmptyState(BuildContext context, String filter) {
    IconData icon;
    String title;
    String subtitle;

    switch (filter) {
      case 'available':
        icon = Icons.event_seat_outlined;
        title = 'No Available Tables';
        subtitle = 'All tables are currently occupied or reserved.';
        break;
      case 'reserved':
        icon = Icons.calendar_month_outlined;
        title = 'No Reservations';
        subtitle = 'There are no tables reserved at the moment.';
        break;
      case 'occupied':
        icon = Icons.people_outline;
        title = 'No Occupied Tables';
        subtitle = 'The restaurant is currently empty.';
        break;
      case 'unavailable':
        icon = Icons.block_outlined;
        title = 'No Unavailable Tables';
        subtitle = 'All tables are in service.';
        break;
      default:
        icon = Icons.table_restaurant_outlined;
        title = 'No Tables Found';
        subtitle = 'There are no tables to display.';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 80,
          color: Theme.of(context).colorScheme.primary.withAlpha(76),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(127),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.primary.withAlpha(25),
      highlightColor: colorScheme.primary.withAlpha(75),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Tables'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: _filters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CustomFilterChip(
                    label: filter[0].toUpperCase() + filter.substring(1),
                    isSelected: _currentFilter == filter,
                    onSelected: (_) {
                      if (_currentFilter != filter) {
                        setState(() => _currentFilter = filter);
                        final state = context.read<TableCubit>().state;
                        context.read<TableCubit>().fetchTables(
                          status: filter == 'all' ? null : filter,
                          limit: state is TableLoaded ? state.limit : 25,
                        );
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: BlocBuilder<TableCubit, TableState>(
        builder: (context, state) {
          if (state is TableLoading || state is TableInitial) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      return _buildSkeletonCard(context);
                    },
                  ),
                ),
              ],
            );
          } else if (state is TableError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is TableLoaded) {
            final tables = state.tables;
            final isFetchingMore = state.tables.length < state.total;
            final currentFilter = state.currentStatus ?? 'all';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await context.read<TableCubit>().fetchTables();
                    },
                    child: tables.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                child: Center(
                                  child: _buildEmptyState(context, currentFilter),
                                ),
                              ),
                            ],
                          )
                        : GridView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16.0),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 200,
                                  childAspectRatio: 1.0,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount:
                                tables.length + (isFetchingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == tables.length) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final table = tables[index];
                              return TableCard(
                                table: table,
                                onTap: () async {
                                  if (table.activeOrders.isNotEmpty || table.occupiedSeats > 0 || table.status == 'occupied') {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ActiveOrdersScreen(table: table),
                                      ),
                                    );
                                  } else if (table.status != 'reserved' && (table.capacity > table.occupiedSeats || table.status == 'available')) {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CreateOrderScreen(table: table),
                                      ),
                                    );
                                  } else {
                                    AppErrorHandler.showError(context, '${TableFormatter.format(table.section, table.tableNumber, table.id)} is ${table.status}.');
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
          ),
        ],
      ),
    );
  }
}
