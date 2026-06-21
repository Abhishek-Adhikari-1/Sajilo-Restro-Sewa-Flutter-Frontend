import 'package:sajilo_restro_sewa/core/errors/app_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../cubit/billing_history_cubit.dart';
import '../cubit/billing_history_state.dart';
import '../cubit/side_panel_cubit.dart';

class BillingHistoryScreen extends StatefulWidget {
  const BillingHistoryScreen({super.key});

  @override
  State<BillingHistoryScreen> createState() => _BillingHistoryScreenState();
}

class _BillingHistoryScreenState extends State<BillingHistoryScreen> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
  final dateFormat = DateFormat('MMM dd, yyyy h:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      context.read<BillingHistoryCubit>().fetchHistory(
        startDate: startOfDay,
        endDate: endOfDay,
        isRefresh: true,
      );
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final state = context.read<BillingHistoryCubit>().state;
    DateTime? initialStart = DateTime.now();
    DateTime? initialEnd = DateTime.now();

    if (state is BillingHistoryLoaded) {
      initialStart = state.startDate ?? initialStart;
      initialEnd = state.endDate ?? initialEnd;
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        final baseTextTheme = Theme.of(context).textTheme;
        return Theme(
          data: Theme.of(context).copyWith(
            platform: isMobile ? TargetPlatform.windows : Theme.of(context).platform,
            visualDensity: VisualDensity.compact,
            colorScheme: Theme.of(context).colorScheme,
            textTheme: isMobile ? baseTextTheme.copyWith(
              headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontSize: 16),
              headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontSize: 16),
              titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 16),
              titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: 14),
              titleSmall: baseTextTheme.titleSmall?.copyWith(fontSize: 12),
            ) : baseTextTheme,
          ),
          child: Builder(
            builder: (context) {
              return Align(
                alignment: isMobile ? Alignment.center : Alignment.topRight,
                child: Padding(
                  padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.only(top: 64, right: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? MediaQuery.of(context).size.width - 32 : 600,
                      maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.75 : 500,
                    ),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      return Flex(
                        direction: isMobile ? Axis.vertical : Axis.horizontal,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: isMobile ? double.infinity : 150,
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 16),
                            child: isMobile
                                ? SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text('Quick Picks:', style: Theme.of(context).textTheme.titleSmall),
                                        ),
                                        TextButton(
                                          child: const Text('Today'),
                                          onPressed: () {
                                            final now = DateTime.now();
                                            Navigator.pop(context, DateTimeRange(start: DateTime(now.year, now.month, now.day), end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999)));
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('Yesterday'),
                                          onPressed: () {
                                            final now = DateTime.now();
                                            final yesterday = now.subtract(const Duration(days: 1));
                                            Navigator.pop(context, DateTimeRange(start: DateTime(yesterday.year, yesterday.month, yesterday.day), end: DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, 999)));
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('Last Week'),
                                          onPressed: () {
                                            final now = DateTime.now();
                                            final lastWeek = now.subtract(const Duration(days: 7));
                                            Navigator.pop(context, DateTimeRange(start: DateTime(lastWeek.year, lastWeek.month, lastWeek.day), end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999)));
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('Last Month'),
                                          onPressed: () {
                                            final now = DateTime.now();
                                            final lastMonth = DateTime(now.year, now.month - 1, now.day);
                                            Navigator.pop(context, DateTimeRange(start: DateTime(lastMonth.year, lastMonth.month, lastMonth.day), end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999)));
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('Last Year'),
                                          onPressed: () {
                                            final now = DateTime.now();
                                            final lastYear = DateTime(now.year - 1, now.month, now.day);
                                            Navigator.pop(context, DateTimeRange(start: DateTime(lastYear.year, lastYear.month, lastYear.day), end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999)));
                                          },
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Text('Quick Picks', style: Theme.of(context).textTheme.titleSmall),
                                      ),
                                      const Divider(),
                                      TextButton(
                                        child: const Align(alignment: Alignment.centerLeft, child: Text('Today')),
                                        onPressed: () {
                                          final now = DateTime.now();
                                          Navigator.pop(context, DateTimeRange(start: DateTime(now.year, now.month, now.day), end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999)));
                                        },
                                      ),
                                      TextButton(
                                        child: const Align(alignment: Alignment.centerLeft, child: Text('Yesterday')),
                                        onPressed: () {
                                          final now = DateTime.now();
                                          final yesterday = now.subtract(const Duration(days: 1));
                                          Navigator.pop(context, DateTimeRange(start: DateTime(yesterday.year, yesterday.month, yesterday.day), end: DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, 999)));
                                        },
                                      ),
                                      TextButton(
                                        child: const Align(alignment: Alignment.centerLeft, child: Text('Last Week')),
                                        onPressed: () {
                                          final now = DateTime.now();
                                          final lastWeek = now.subtract(const Duration(days: 7));
                                          Navigator.pop(context, DateTimeRange(start: DateTime(lastWeek.year, lastWeek.month, lastWeek.day), end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999)));
                                        },
                                      ),
                                      TextButton(
                                        child: const Align(alignment: Alignment.centerLeft, child: Text('Last Month')),
                                        onPressed: () {
                                          final now = DateTime.now();
                                          final lastMonth = DateTime(now.year, now.month - 1, now.day);
                                          Navigator.pop(context, DateTimeRange(start: DateTime(lastMonth.year, lastMonth.month, lastMonth.day), end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999)));
                                        },
                                      ),
                                      TextButton(
                                        child: const Align(alignment: Alignment.centerLeft, child: Text('Last Year')),
                                        onPressed: () {
                                          final now = DateTime.now();
                                          final lastYear = DateTime(now.year - 1, now.month, now.day);
                                          Navigator.pop(context, DateTimeRange(start: DateTime(lastYear.year, lastYear.month, lastYear.day), end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999)));
                                        },
                                      ),
                                    ],
                                  ),
                          ),
                          if (isMobile) const Divider(height: 1, thickness: 1),
                          Flexible(
                            child: child!,
                          ),
                        ],
                      );
                    },
                  ), // LayoutBuilder
                ), // Material
              ), // ConstrainedBox
            ), // Padding
          ); // return Align
        },
      ), // Builder
    ); // Theme
  }, // builder
); // showDateRangePicker

    if (picked != null && context.mounted) {
      final startDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
      final endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999);
      context.read<BillingHistoryCubit>().fetchHistory(
        startDate: startDate,
        endDate: endDate,
        isRefresh: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Billing History'),
            actions: [
              IconButton(
                icon: const Icon(Icons.date_range),
                onPressed: () => _selectDateRange(context),
                tooltip: 'Filter by Date',
              ),
              const SizedBox(width: 8),
            ],
          ),
      body: BlocBuilder<BillingHistoryCubit, BillingHistoryState>(
        builder: (context, state) {
          if (state is BillingHistoryLoading && state is! BillingHistoryLoaded) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BillingHistoryError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Failed to load history',
              subtitle: state.message,
              action: ElevatedButton(
                onPressed: () {
                  context.read<BillingHistoryCubit>().fetchHistory(isRefresh: true);
                },
                child: const Text('Try Again'),
              ),
            );
          } else if (state is BillingHistoryLoaded) {
            return Column(
              children: [
                _buildDateFilterHeader(context, state),
                Expanded(
                  child: state.items.isEmpty
                      ? const EmptyState(
                          icon: Icons.history,
                          title: 'No Billing History',
                          subtitle: 'No records found for the selected date range.',
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return Scrollbar(
                              controller: _horizontalScrollController,
                              child: SingleChildScrollView(
                                controller: _horizontalScrollController,
                                scrollDirection: Axis.horizontal,
                                child: Scrollbar(
                                  controller: _verticalScrollController,
                                  child: SingleChildScrollView(
                                    controller: _verticalScrollController,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: constraints.maxWidth,
                                        minHeight: constraints.maxHeight,
                                      ),
                                      child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                        Theme.of(context).colorScheme.surfaceContainerHighest),
                                    columns: const [
                                      DataColumn(label: Text('Payment ID')),
                                      DataColumn(label: Text('Order ID')),
                                      DataColumn(label: Text('Customer ID')),
                                      DataColumn(label: Text('Method')),
                                      DataColumn(label: Text('Status')),
                                      DataColumn(label: Text('Amount')),
                                      DataColumn(label: Text('Subtotal')),
                                      DataColumn(label: Text('Discount Type')),
                                      DataColumn(label: Text('Discount')),
                                      DataColumn(label: Text('Tax Type')),
                                      DataColumn(label: Text('Tax')),
                                      DataColumn(label: Text('Notes')),
                                      DataColumn(label: Text('Created At')),
                                      DataColumn(label: Text('Updated At')),
                                      DataColumn(label: Text('Created By')),
                                    ],
                                    rows: state.items.map((item) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Tooltip(
                                              message: 'Click to see full Payment details',
                                              child: InkWell(
                                                onTap: () {
                                                  // In future, you might fetch payment details.
                                                  // For now, let's just copy to clipboard or ignore.
                                                },
                                                onLongPress: () {
                                                  Clipboard.setData(ClipboardData(text: item.id));
                                                  AppErrorHandler.show(context, 'Payment ID copied to clipboard');
                                                },
                                                child: Text(
                                                  '#${item.id.length > 10 ? '${item.id.substring(0, 10)}...' : item.id}',
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.primary,
                                                    decoration: TextDecoration.underline,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Tooltip(
                                              message: 'Click to see full Order details',
                                              child: InkWell(
                                                onTap: () {
                                                  context.read<SidePanelCubit>().fetchOrderDetails(item.orderId);
                                                  context.findRootAncestorStateOfType<ScaffoldState>()?.openEndDrawer();
                                                },
                                                onLongPress: () {
                                                  Clipboard.setData(ClipboardData(text: item.orderId));
                                                  AppErrorHandler.show(context, 'Order ID copied to clipboard');
                                                },
                                                child: Text(
                                                  '#${item.orderId.length > 10 ? '${item.orderId.substring(0, 10)}...' : item.orderId}',
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.primary,
                                                    decoration: TextDecoration.underline,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            item.customerId != null
                                                ? Tooltip(
                                                    message: 'Click to see full Customer details',
                                                    child: InkWell(
                                                      onTap: () {
                                                        context.read<SidePanelCubit>().fetchCustomerDetails(item.customerId!);
                                                        context.findRootAncestorStateOfType<ScaffoldState>()?.openEndDrawer();
                                                      },
                                                      onLongPress: () {
                                                        Clipboard.setData(ClipboardData(text: item.customerId!));
                                                        AppErrorHandler.show(context, 'Customer ID copied to clipboard');
                                                      },
                                                      child: Text(
                                                        '#${item.customerId!.length > 10 ? '${item.customerId!.substring(0, 10)}...' : item.customerId}',
                                                        style: TextStyle(
                                                          color: Theme.of(context).colorScheme.primary,
                                                          decoration: TextDecoration.underline,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : const Text('-'),
                                          ),
                                          DataCell(Text(item.method.toUpperCase())),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: item.status == 'paid' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                item.status.toUpperCase(),
                                                style: TextStyle(
                                                  color: item.status == 'paid' ? Colors.green : Colors.orange,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(currencyFormat.format(item.totalAmount))),
                                          DataCell(Text(currencyFormat.format(item.subtotal))),
                                          DataCell(Text(item.discountType?.toUpperCase() ?? '-')),
                                          DataCell(Text(item.discountValue != null ? (item.discountType == 'fixed' ? currencyFormat.format(item.discountValue) : '${item.discountValue}%') : '-')),
                                          DataCell(Text(item.taxType?.toUpperCase() ?? '-')),
                                          DataCell(Text(item.taxValue != null ? (item.taxType == 'fixed' ? currencyFormat.format(item.taxValue) : '${item.taxValue}%') : '-')),
                                          DataCell(
                                            SizedBox(
                                              width: 150,
                                              child: Text(
                                                item.notes ?? '-',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(dateFormat.format(item.createdAt.toLocal()))),
                                          DataCell(Text(dateFormat.format(item.updatedAt.toLocal()))),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (item.createdByImage != null) ...[
                                                  CircleAvatar(
                                                    radius: 12,
                                                    backgroundImage: NetworkImage(item.createdByImage!),
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                                Text(item.createdByName ?? 'Unknown'),
                                              ],
                                            ),
                                          ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ),
                if (state.items.isNotEmpty) _buildPaginationControls(context, state),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
      },
    );
  }

  Widget _buildDateFilterHeader(BuildContext context, BillingHistoryLoaded state) {
    if (state.startDate == null || state.endDate == null) return const SizedBox.shrink();

    final dateDisplay = state.startDate!.day == state.endDate!.day &&
            state.startDate!.month == state.endDate!.month &&
            state.startDate!.year == state.endDate!.year
        ? DateFormat('MMMM d, yyyy').format(state.startDate!)
        : '${DateFormat('MMM d').format(state.startDate!)} - ${DateFormat('MMM d, yyyy').format(state.endDate!)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 8),
              Text(dateDisplay, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          Text(
            'Total Records: ${state.total}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(BuildContext context, BillingHistoryLoaded state) {
    final cubit = context.read<BillingHistoryCubit>();
    final currentOffset = state.currentOffset;
    final limit = cubit.limit;
    final currentPage = (currentOffset / limit).floor() + 1;
    final totalPages = (state.total / limit).ceil();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(MediaQuery.of(context).size.width < 600 ? 'Page:' : 'Rows per page:'),
            const SizedBox(width: 8),
          DropdownButton<int>(
            value: limit,
            underline: const SizedBox.shrink(),
            items: [10, 25, 50].map((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text(value.toString()),
              );
            }).toList(),
            onChanged: (int? newValue) {
              if (newValue != null) {
                cubit.fetchHistory(limit: newValue, isRefresh: true);
              }
            },
          ),
          SizedBox(width: MediaQuery.of(context).size.width < 600 ? 12 : 24),
          Text(
              'Page $currentPage of ${totalPages == 0 ? 1 : totalPages} (${state.total} total)'),
          SizedBox(width: MediaQuery.of(context).size.width < 600 ? 8 : 24),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentOffset == 0
                ? null
                : () {
                    cubit.fetchHistory(newOffset: currentOffset - limit);
                  },
            tooltip: 'Previous Page',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.hasReachedMax
                ? null
                : () {
                    cubit.fetchHistory(newOffset: currentOffset + limit);
                  },
            tooltip: 'Next Page',
          ),
        ],
      ),
      ),
    );
  }
}
