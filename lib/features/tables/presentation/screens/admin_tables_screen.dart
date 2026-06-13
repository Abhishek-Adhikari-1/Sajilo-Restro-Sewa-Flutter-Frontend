import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sajilo_restro_sewa/core/errors/app_error_handler.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../cubit/table_cubit.dart';
import '../cubit/table_state.dart';
import 'add_edit_table_screen.dart';

class AdminTablesScreen extends StatefulWidget {
  const AdminTablesScreen({super.key});

  @override
  State<AdminTablesScreen> createState() => _AdminTablesScreenState();
}

class _AdminTablesScreenState extends State<AdminTablesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    context.read<TableCubit>().fetchTables();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _navigateToAddEditScreen({
    String? id,
    Map<String, dynamic>? initialData,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTableScreen(id: id, initialData: initialData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tables'),
        scrolledUnderElevation: 0.0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddEditScreen(),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: BlocConsumer<TableCubit, TableState>(
          listener: (context, state) {
            if (state is TableError) {
              AppErrorHandler.showError(context, state.message);
              context.read<TableCubit>().clearError();
            } else if (state is TableLoaded && state.errorMessage != null) {
              AppErrorHandler.showError(context, state.errorMessage!);
              context.read<TableCubit>().clearError();
            }
          },
          builder: (context, state) {
            if (state is TableLoading && state is! TableLoaded) {
              final isMobile = MediaQuery.of(context).size.width < 600;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: LoadingShimmer(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: isMobile ? 48 : 150,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListView.builder(
                        itemCount: 5,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: LoadingShimmer(
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            if (state is TableLoaded) {
              final tables = state.tables;
              final currentLimit = state.limit;
              final currentOffset = state.offset;
              final total = state.total;

              final currentPage = (currentOffset / currentLimit).floor() + 1;
              final totalPages = (total / currentLimit).ceil();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search tables...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          context
                                              .read<TableCubit>()
                                              .fetchTables(
                                                search: '',
                                                status: _statusFilter == 'all'
                                                    ? null
                                                    : _statusFilter,
                                              );
                                        },
                                      ),
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (val) {
                              if (_debounceTimer?.isActive ?? false) {
                                _debounceTimer?.cancel();
                              }
                              _debounceTimer = Timer(
                                const Duration(milliseconds: 500),
                                () {
                                  context.read<TableCubit>().fetchTables(
                                    search: val.trim(),
                                    status: _statusFilter == 'all'
                                        ? null
                                        : _statusFilter,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        MediaQuery.of(context).size.width < 600
                            ? PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                tooltip: 'Filter by Status',
                                initialValue: _statusFilter ?? 'all',
                                onSelected: (val) {
                                  setState(() {
                                    _statusFilter = val;
                                  });
                                  context.read<TableCubit>().fetchTables(
                                    search: _searchController.text,
                                    status: val == 'all' ? null : val,
                                  );
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'all',
                                    child: Text('All Status'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'available',
                                    child: Text('Available'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'occupied',
                                    child: Text('Occupied'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'reserved',
                                    child: Text('Reserved'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'cleaning',
                                    child: Text('Cleaning'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'unavailable',
                                    child: Text('Unavailable'),
                                  ),
                                ],
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.filter_list,
                                    color:
                                        (_statusFilter != null &&
                                            _statusFilter != 'all')
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                              )
                            : SizedBox(
                                width: 150,
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  initialValue: _statusFilter ?? 'all',
                                  hint: const Text('Status'),
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'all',
                                      child: Text('All Status'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'available',
                                      child: Text('Available'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'occupied',
                                      child: Text('Occupied'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'reserved',
                                      child: Text('Reserved'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'cleaning',
                                      child: Text('Cleaning'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'unavailable',
                                      child: Text('Unavailable'),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _statusFilter = val;
                                    });
                                    context.read<TableCubit>().fetchTables(
                                      search: _searchController.text,
                                      status: val == 'all' ? null : val,
                                    );
                                  },
                                ),
                              ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: tables.isEmpty
                        ? EmptyState(
                            icon: Icons.table_restaurant,
                            title: 'No tables found',
                            subtitle: 'Try adjusting your search filters.',
                            action: TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _statusFilter = 'all';
                                });
                                context.read<TableCubit>().fetchTables(
                                  search: '',
                                  status: null,
                                );
                              },
                              child: const Text('Clear Search & Filters'),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                context.read<TableCubit>().fetchTables(
                                  search: _searchController.text,
                                  status: _statusFilter == 'all'
                                      ? null
                                      : _statusFilter,
                                  limit: currentLimit,
                                ),
                            child: ListView.builder(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                bottom: 16,
                              ),
                              itemCount: tables.length,
                              itemBuilder: (context, index) {
                                final table = tables[index];

                                return Card(
                                  elevation: 0,
                                  clipBehavior: Clip.antiAlias,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withAlpha(128),
                                      width: 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      _navigateToAddEditScreen(
                                        id: table.id,
                                        initialData: {
                                          'tableNumber': table.tableNumber,
                                          'section': table.section,
                                          'capacity': table.capacity,
                                          'status': table.status,
                                        },
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.table_restaurant,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Table ${table.tableNumber}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${table.section} • Capacity: ${table.capacity}',
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                table.status,
                                              ).withAlpha(51),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              table.status[0].toUpperCase() +
                                                  table.status.substring(1),
                                              style: TextStyle(
                                                color: _getStatusColor(
                                                  table.status,
                                                ),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                  if (tables.isNotEmpty)
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant.withAlpha(128),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('Show:'),
                                const SizedBox(width: 8),
                                DropdownButton<int>(
                                  value: currentLimit,
                                  underline: const SizedBox(),
                                  items: [10, 25, 50].map((int value) {
                                    return DropdownMenuItem<int>(
                                      value: value,
                                      child: Text(value.toString()),
                                    );
                                  }).toList(),
                                  onChanged: (int? newValue) {
                                    if (newValue != null) {
                                      context.read<TableCubit>().fetchTables(
                                        search: _searchController.text,
                                        status: _statusFilter == 'all'
                                            ? null
                                            : _statusFilter,
                                        limit: newValue,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: currentPage > 1
                                      ? () => context
                                            .read<TableCubit>()
                                            .changePage(
                                              currentPage - 1,
                                              currentLimit,
                                            )
                                      : null,
                                ),
                                Text(
                                  'Page $currentPage of ${totalPages == 0 ? 1 : totalPages}',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: currentPage < totalPages
                                      ? () => context
                                            .read<TableCubit>()
                                            .changePage(
                                              currentPage + 1,
                                              currentLimit,
                                            )
                                      : null,
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'occupied':
        return Colors.orange;
      case 'reserved':
        return Colors.blue;
      case 'cleaning':
        return Colors.purple;
      case 'unavailable':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
