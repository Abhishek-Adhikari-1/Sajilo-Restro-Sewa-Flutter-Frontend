import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';
import 'create_expense_screen.dart';
import '../../data/models/expense_model.dart';
import '../../../../core/errors/app_error_handler.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';

class AdminExpensesScreen extends StatefulWidget {
  const AdminExpensesScreen({super.key});

  @override
  State<AdminExpensesScreen> createState() => _AdminExpensesScreenState();
}

class _AdminExpensesScreenState extends State<AdminExpensesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  @override
  void initState() {
    super.initState();
    context.read<ExpenseCubit>().fetchExpenses(offset: 0, limit: 25, category: '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _navToCreateExpense({ExpenseModel? expense}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateExpenseScreen(expense: expense)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navToCreateExpense,
            tooltip: 'Add Expense',
          ),
        ],
      ),
      body: BlocConsumer<ExpenseCubit, ExpenseState>(
        listenWhen: (previous, current) => current is ExpenseError || current is ExpenseActionSuccess,
        listener: (context, state) {
          if (state is ExpenseError) {
            AppErrorHandler.show(context, state.message);
          } else if (state is ExpenseActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        buildWhen: (previous, current) => current is ExpenseLoaded || current is ExpenseLoading && previous is! ExpenseLoaded,
        builder: (context, state) {
          if (state is ExpenseLoading && state is! ExpenseLoaded) {
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
                          width: isMobile ? 48 : 180,
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
                    child: LoadingShimmer.list(count: 5),
                  ),
                ),
              ],
            );
          } else if (state is ExpenseError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Failed to load expenses',
              subtitle: state.message,
              action: ElevatedButton(
                onPressed: () => context.read<ExpenseCubit>().fetchExpenses(offset: 0, limit: 25),
                child: const Text('Try Again'),
              ),
            );
          } else if (state is ExpenseLoaded) {
            if (state.expenses.isEmpty && _searchController.text.isEmpty && (state.category == null || state.category!.isEmpty)) {
              return EmptyState(
                icon: Icons.receipt_long,
                title: 'No Expenses',
                subtitle: 'Tap + to add your first expense.',
                action: ElevatedButton.icon(
                  onPressed: () => _navToCreateExpense(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Expense'),
                ),
              );
            }

            final currentPage = (state.offset / state.limit).floor() + 1;
            final totalPages = (state.total / state.limit).ceil();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search expenses...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        context.read<ExpenseCubit>().fetchExpenses(offset: 0, search: '');
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
                            _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                              context.read<ExpenseCubit>().fetchExpenses(offset: 0, search: val.trim());
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      MediaQuery.of(context).size.width < 600
                          ? PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              tooltip: 'Filter by Category',
                              initialValue: state.category == null || state.category!.isEmpty ? 'all' : state.category,
                              onSelected: (val) {
                                context.read<ExpenseCubit>().fetchExpenses(offset: 0, category: val == 'all' ? '' : val);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'all', child: Text('All Categories')),
                                const PopupMenuItem(value: 'Ingredients', child: Text('Ingredients')),
                                const PopupMenuItem(value: 'Salary & Wages', child: Text('Salary & Wages')),
                                const PopupMenuItem(value: 'Rent & Lease', child: Text('Rent & Lease')),
                                const PopupMenuItem(value: 'Utilities (Water, Electricity)', child: Text('Utilities')),
                                const PopupMenuItem(value: 'Maintenance & Repairs', child: Text('Maintenance')),
                                const PopupMenuItem(value: 'Equipment', child: Text('Equipment')),
                                const PopupMenuItem(value: 'Marketing & Ads', child: Text('Marketing & Ads')),
                                const PopupMenuItem(value: 'Packaging Supplies', child: Text('Packaging Supplies')),
                                const PopupMenuItem(value: 'Taxes & Licenses', child: Text('Taxes & Licenses')),
                                const PopupMenuItem(value: 'Miscellaneous', child: Text('Miscellaneous')),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.filter_list,
                                  color: state.category != null && state.category!.isNotEmpty ? Theme.of(context).colorScheme.primary : null,
                                ),
                              ),
                            )
                          : SizedBox(
                              width: 180,
                              child: DropdownButtonFormField<String>(
                                initialValue: state.category == null || state.category!.isEmpty ? 'all' : state.category,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                hint: const Text('All Categories'),
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem<String>(value: 'all', child: Text('All Categories')),
                                  DropdownMenuItem<String>(value: 'Ingredients', child: Text('Ingredients')),
                                  DropdownMenuItem<String>(value: 'Salary & Wages', child: Text('Salary & Wages')),
                                  DropdownMenuItem<String>(value: 'Rent & Lease', child: Text('Rent & Lease')),
                                  DropdownMenuItem<String>(value: 'Utilities (Water, Electricity)', child: Text('Utilities')),
                                  DropdownMenuItem<String>(value: 'Maintenance & Repairs', child: Text('Maintenance')),
                                  DropdownMenuItem<String>(value: 'Equipment', child: Text('Equipment')),
                                  DropdownMenuItem<String>(value: 'Marketing & Ads', child: Text('Marketing & Ads')),
                                  DropdownMenuItem<String>(value: 'Packaging Supplies', child: Text('Packaging Supplies')),
                                  DropdownMenuItem<String>(value: 'Taxes & Licenses', child: Text('Taxes & Licenses')),
                                  DropdownMenuItem<String>(value: 'Miscellaneous', child: Text('Miscellaneous')),
                                ],
                                onChanged: (val) {
                                  context.read<ExpenseCubit>().fetchExpenses(offset: 0, category: val == 'all' ? '' : val);
                                },
                              ),
                            ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await context.read<ExpenseCubit>().fetchExpenses();
                    },
                    child: state.expenses.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Text('No expenses match your search.'),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.expenses.length,
                            itemBuilder: (context, index) {
                              final expense = state.expenses[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => _navToCreateExpense(expense: expense),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                      child: Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.primary),
                                    ),
                                    title: Text(expense.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text('Category: ${expense.category}'),
                                        Text('Date: ${DateFormat('MMM dd, yyyy').format(expense.date)}'),
                                        if (expense.notes != null && expense.notes!.isNotEmpty)
                                          Text('Notes: ${expense.notes}'),
                                      ],
                                    ),
                                    trailing: Text(
                                      'Rs. ${expense.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Show: ',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            DropdownButton<int>(
                              value: state.limit,
                              items: [10, 25, 50].map((int val) {
                                return DropdownMenuItem<int>(
                                  value: val,
                                  child: Text('$val'),
                                );
                              }).toList(),
                              onChanged: (newLimit) {
                                if (newLimit != null) {
                                  context.read<ExpenseCubit>().fetchExpenses(offset: 0, limit: newLimit);
                                }
                              },
                              underline: const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: currentPage > 1
                                  ? () {
                                      context.read<ExpenseCubit>().fetchExpenses(
                                            offset: state.offset - state.limit,
                                            limit: state.limit,
                                          );
                                    }
                                  : null,
                            ),
                            Text(
                              'Page $currentPage of ${totalPages == 0 ? 1 : totalPages} (${state.total} total)',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: currentPage < totalPages
                                  ? () {
                                      context.read<ExpenseCubit>().fetchExpenses(
                                            offset: state.offset + state.limit,
                                            limit: state.limit,
                                          );
                                    }
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
    );
  }
}
