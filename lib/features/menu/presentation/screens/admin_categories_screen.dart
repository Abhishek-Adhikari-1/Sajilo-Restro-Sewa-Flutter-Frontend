import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sajilo_restro_sewa/core/errors/app_error_handler.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../cubit/menu_cubit.dart';
import '../widgets/animated_availability_toggle.dart';
import 'add_edit_category_screen.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool? _isAvailableFilter;

  @override
  void initState() {
    super.initState();
    context.read<MenuCubit>().fetchMenuData();
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
    context.read<MenuCubit>().discardChanges();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditCategoryScreen(id: id, initialData: initialData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
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
        child: BlocConsumer<MenuCubit, MenuState>(
          listener: (context, state) {
            if (state is MenuError) {
              AppErrorHandler.showError(context, state.message);
            }
          },
          builder: (context, state) {
            if (state is MenuLoading && state is! MenuLoaded) {
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
                      child: LoadingShimmer.list(count: 5),
                    ),
                  ),
                ],
              );
            } else if (state is MenuError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load categories',
                subtitle: state.message,
                action: ElevatedButton(
                  onPressed: () => context.read<MenuCubit>().fetchMenuData(),
                  child: const Text('Try Again'),
                ),
              );
            } else if (state is MenuLoaded) {
              if (state.categories.isEmpty &&
                  (_searchController.text.isEmpty)) {
                return EmptyState(
                  icon: Icons.category,
                  title: 'No Categories',
                  subtitle: 'Add categories to group your menu items.',
                  action: ElevatedButton.icon(
                    onPressed: () => _navigateToAddEditScreen(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                  ),
                );
              }

              final currentPage =
                  (state.categoryOffset / state.categoryLimit).floor() + 1;
              final totalPages = (state.categoryTotal / state.categoryLimit)
                  .ceil();

              final filteredCategories = state.categories.where((c) {
                final matchesStatus =
                    _isAvailableFilter == null ||
                    c.isActive == _isAvailableFilter;
                return matchesStatus;
              }).toList();

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
                              hintText: 'Search categories...',
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
                                              .read<MenuCubit>()
                                              .fetchCategoriesOnly(search: '');
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
                                  context.read<MenuCubit>().fetchCategoriesOnly(
                                    search: val.trim(),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        MediaQuery.of(context).size.width < 600
                            ? PopupMenuButton<bool?>(
                                padding: EdgeInsets.zero,
                                tooltip: 'Filter by Status',
                                initialValue: _isAvailableFilter,
                                onSelected: (val) {
                                  setState(() {
                                    _isAvailableFilter = val;
                                  });
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: null,
                                    child: Text('All Status'),
                                  ),
                                  const PopupMenuItem(
                                    value: true,
                                    child: Text('Available'),
                                  ),
                                  const PopupMenuItem(
                                    value: false,
                                    child: Text('Unavailable'),
                                  ),
                                ],
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.filter_list,
                                    color: _isAvailableFilter != null
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                              )
                            : SizedBox(
                                width: 150,
                                child: DropdownButtonFormField<bool?>(
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  initialValue: _isAvailableFilter,
                                  hint: const Text('Status'),
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem<bool?>(
                                      value: null,
                                      child: Text('All Status'),
                                    ),
                                    DropdownMenuItem<bool?>(
                                      value: true,
                                      child: Text('Available'),
                                    ),
                                    DropdownMenuItem<bool?>(
                                      value: false,
                                      child: Text('Unavailable'),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _isAvailableFilter = val;
                                    });
                                  },
                                ),
                              ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await context.read<MenuCubit>().fetchMenuData();
                      },
                      child: filteredCategories.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 100),
                                Center(
                                  child: Text(
                                    'No categories match your search.',
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: filteredCategories.length,
                              itemBuilder: (context, index) {
                                final category = filteredCategories[index];
                                final isEdited = state.editedCategories
                                    .containsKey(category.id);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  clipBehavior: Clip.antiAlias,
                                  shape: isEdited
                                      ? RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          side: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                            width: 2,
                                          ),
                                        )
                                      : null,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue.withValues(
                                        alpha: 0.1,
                                      ),
                                      backgroundImage:
                                          category.icon != null &&
                                              category.icon!.isNotEmpty
                                          ? NetworkImage(category.icon!)
                                          : null,
                                      child:
                                          category.icon == null ||
                                              category.icon!.isEmpty
                                          ? const Icon(
                                              Icons.restaurant,
                                              size: 20,
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      category.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    trailing: AnimatedAvailabilityToggle(
                                      isAvailable:
                                          state.editedCategories.containsKey(
                                            category.id,
                                          )
                                          ? state.editedCategories[category.id]!
                                          : category.isActive,
                                      onTap: () {
                                        context
                                            .read<MenuCubit>()
                                            .toggleCategoryAvailability(
                                              category.id,
                                            );
                                      },
                                    ),
                                    onTap: () {
                                      if (state.editedCategories.isNotEmpty) {
                                        context
                                            .read<MenuCubit>()
                                            .toggleCategoryAvailability(
                                              category.id,
                                            );
                                      } else {
                                        _navigateToAddEditScreen(
                                          id: category.id,
                                          initialData: {
                                            'name': category.name,
                                            'icon': category.icon,
                                            'icon_id': category.iconId,
                                            'is_active': category.isActive,
                                          },
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  if (state.editedCategories.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: MediaQuery.of(context).size.width < 600
                            ? 8
                            : 16,
                      ),
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You have ${state.editedCategories.length} unsaved change${state.editedCategories.length == 1 ? '' : 's'}.',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          if (state.isSaving)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else ...[
                            FilledButton.tonal(
                              onPressed: () =>
                                  context.read<MenuCubit>().discardChanges(),
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onSurface,
                                visualDensity:
                                    MediaQuery.of(context).size.width < 600
                                    ? VisualDensity.compact
                                    : null,
                                padding: MediaQuery.of(context).size.width < 600
                                    ? const EdgeInsets.symmetric(horizontal: 12)
                                    : null,
                                textStyle:
                                    MediaQuery.of(context).size.width < 600
                                    ? const TextStyle(fontSize: 12)
                                    : null,
                              ),
                              child: const Text('Discard'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () =>
                                  context.read<MenuCubit>().saveChanges(),
                              style: FilledButton.styleFrom(
                                visualDensity:
                                    MediaQuery.of(context).size.width < 600
                                    ? VisualDensity.compact
                                    : null,
                                padding: MediaQuery.of(context).size.width < 600
                                    ? const EdgeInsets.symmetric(horizontal: 12)
                                    : null,
                                textStyle:
                                    MediaQuery.of(context).size.width < 600
                                    ? const TextStyle(fontSize: 12)
                                    : null,
                              ),
                              child: const Text('Save'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                                value: state.categoryLimit,
                                items: [10, 25, 50].map((int val) {
                                  return DropdownMenuItem<int>(
                                    value: val,
                                    child: Text('$val'),
                                  );
                                }).toList(),
                                onChanged: (newLimit) {
                                  if (newLimit != null) {
                                    context
                                        .read<MenuCubit>()
                                        .fetchCategoriesOnly(
                                          search: state.categorySearch,
                                          offset: 0,
                                          limit: newLimit,
                                        );
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
                                        context
                                            .read<MenuCubit>()
                                            .fetchCategoriesOnly(
                                              search: state.categorySearch,
                                              offset:
                                                  state.categoryOffset -
                                                  state.categoryLimit,
                                              limit: state.categoryLimit,
                                            );
                                      }
                                    : null,
                              ),
                              Text(
                                'Page $currentPage of ${totalPages == 0 ? 1 : totalPages} (${state.categoryTotal} total)',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: currentPage < totalPages
                                    ? () {
                                        context
                                            .read<MenuCubit>()
                                            .fetchCategoriesOnly(
                                              search: state.categorySearch,
                                              offset:
                                                  state.categoryOffset +
                                                  state.categoryLimit,
                                              limit: state.categoryLimit,
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
      ),
    );
  }
}
