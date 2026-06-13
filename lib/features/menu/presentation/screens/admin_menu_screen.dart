import 'dart:async';
import 'package:sajilo_restro_sewa/core/errors/app_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/custom_filter_chip.dart';
import '../cubit/menu_cubit.dart';
import '../widgets/animated_availability_toggle.dart';
import 'add_edit_menu_screen.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  late final MenuCubit _menuCubit;

  @override
  void initState() {
    super.initState();
    _menuCubit = context.read<MenuCubit>();
    _menuCubit.fetchMenuData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _menuCubit.discardChanges();
    super.dispose();
  }

  void _navigateToAddEditScreen({String? id, Map<String, dynamic>? initialData}) {
    final state = _menuCubit.state;
    if (state is! MenuLoaded) return;

    final categories = state.categories;
    if (categories.isEmpty) {
      AppErrorHandler.show(context, 'Please create a category first before adding menu items.');
      return;
    }

    _menuCubit.discardChanges();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditMenuScreen(
          id: id,
          initialData: initialData,
          categories: categories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menus'),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: LoadingShimmer(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: isMobile ? 48 : 150,
                          height: 48,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: LoadingShimmer(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 5,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LoadingShimmer.list(count: 5),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: LoadingShimmer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(width: 80, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                          Container(width: 120, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else if (state is MenuError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Failed to load menu',
              subtitle: state.message,
              action: ElevatedButton(
                onPressed: () => context.read<MenuCubit>().fetchMenuData(),
                child: const Text('Try Again'),
              ),
            );
          } else if (state is MenuLoaded) {
            if (state.menus.isEmpty && state.categories.isEmpty) {
              return EmptyState(
                icon: Icons.restaurant_menu,
                title: 'No Menu Items',
                subtitle: 'Add categories and menu items to get started.',
                action: ElevatedButton.icon(
                  onPressed: () => _navigateToAddEditScreen(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Menu Item'),
                ),
              );
            }

            final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
            final currentPage = (state.menuOffset / state.limit).floor() + 1;
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
                            hintText: 'Search menus...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        context.read<MenuCubit>().fetchMenuData(
                                              search: '',
                                              categoryId: state.currentCategoryId,
                                              offset: 0,
                                              limit: state.limit,
                                              isAvailable: state.currentIsAvailable,
                                            );
                                      },
                                    ),
                                  )
                                : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onChanged: (val) {
                            if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
                            _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                              context.read<MenuCubit>().fetchMenuData(
                                    search: val.trim(),
                                    categoryId: state.currentCategoryId,
                                    offset: 0,
                                    limit: state.limit,
                                    isAvailable: state.currentIsAvailable,
                                  );
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      MediaQuery.of(context).size.width < 600
                          ? PopupMenuButton<bool?>(
                              padding: EdgeInsets.zero,
                              tooltip: 'Filter by Status',
                              initialValue: state.currentIsAvailable,
                              onSelected: (val) {
                                context.read<MenuCubit>().fetchMenuData(
                                      search: _searchController.text.trim(),
                                      categoryId: state.currentCategoryId,
                                      offset: 0,
                                      limit: state.limit,
                                      isAvailable: val,
                                    );
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
                                  color: state.currentIsAvailable != null
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
                                value: state.currentIsAvailable,
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
                                  context.read<MenuCubit>().fetchMenuData(
                                        search: _searchController.text.trim(),
                                        categoryId: state.currentCategoryId,
                                        offset: 0,
                                        limit: state.limit,
                                        isAvailable: val,
                                      );
                                },
                              ),
                            ),
                    ],
                  ),
                ),
                Container(
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.categories.length + 1,
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      final category = isAll ? null : state.categories[index - 1];
                      final isSelected = isAll 
                          ? state.currentCategoryId == null 
                          : state.currentCategoryId == category?.id;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CustomFilterChip(
                          label: isAll ? 'All Categories' : category!.name,
                          isSelected: isSelected,
                          onSelected: (selected) {
                            context.read<MenuCubit>().fetchMenuData(
                                  search: _searchController.text.trim(),
                                  categoryId: isAll ? null : category!.id,
                                  offset: 0,
                                  limit: state.limit,
                                  isAvailable: state.currentIsAvailable,
                                );
                          },
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: state.menus.isEmpty
                      ? const Center(
                          child: Text('No menu items match your search.'),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await context.read<MenuCubit>().fetchMenuData(
                                  search: state.currentSearch,
                                  categoryId: state.currentCategoryId,
                                  offset: state.menuOffset,
                                  limit: state.limit,
                                  isAvailable: state.currentIsAvailable,
                                );
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: state.menus.length,
                            itemBuilder: (context, index) {
                              final item = state.menus[index];
                              final category = state.categories.firstWhere(
                                (c) => c.id == item.categoryId,
                                orElse: () => state.categories.first,
                              );

                              final isEdited = state.editedMenus.containsKey(item.id);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                clipBehavior: Clip.antiAlias,
                                shape: isEdited
                                    ? RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Theme.of(context).colorScheme.secondary,
                                          width: 2,
                                        ),
                                      )
                                    : null,
                                child: Stack(
                                  children: [
                                    ListTile(
                                      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.grey.shade200,
                                        backgroundImage: item.image != null && item.image!.isNotEmpty ? NetworkImage(item.image!) : null,
                                        child: item.image == null || item.image!.isEmpty ? const Icon(Icons.fastfood, color: Colors.grey) : null,
                                      ),
                                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${category.name} • ${item.estimatedPreparationTime} mins'),
                                      trailing: AnimatedAvailabilityToggle(
                                        isAvailable: state.editedMenus.containsKey(item.id)
                                            ? state.editedMenus[item.id]!
                                            : item.isAvailable,
                                        onTap: () {
                                          context.read<MenuCubit>().toggleAvailability(item.id);
                                        },
                                      ),
                                      onTap: () {
                                        if (state.editedMenus.isNotEmpty) {
                                          context.read<MenuCubit>().toggleAvailability(item.id);
                                        } else {
                                          _navigateToAddEditScreen(
                                            id: item.id,
                                            initialData: {
                                              'name': item.name,
                                              'description': item.description,
                                              'price': item.price,
                                              'category_id': item.categoryId,
                                              'estimated_preparation_time': item.estimatedPreparationTime,
                                              'is_available': item.isAvailable,
                                              'image': item.image,
                                              'image_id': item.imageId,
                                            },
                                          );
                                        }
                                      },
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.secondaryContainer,
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          currencyFormat.format(item.price),
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
                if (state.editedMenus.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: MediaQuery.of(context).size.width < 600 ? 8 : 16,
                    ),
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onPrimaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You have ${state.editedMenus.length} unsaved change${state.editedMenus.length == 1 ? '' : 's'}.',
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
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
                            onPressed: () => context.read<MenuCubit>().discardChanges(),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              foregroundColor: Theme.of(context).colorScheme.onSurface,
                              visualDensity: MediaQuery.of(context).size.width < 600 ? VisualDensity.compact : null,
                              padding: MediaQuery.of(context).size.width < 600 ? const EdgeInsets.symmetric(horizontal: 12) : null,
                              textStyle: MediaQuery.of(context).size.width < 600 ? const TextStyle(fontSize: 12) : null,
                            ),
                            child: const Text('Discard'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => context.read<MenuCubit>().saveChanges(),
                            style: FilledButton.styleFrom(
                              visualDensity: MediaQuery.of(context).size.width < 600 ? VisualDensity.compact : null,
                              padding: MediaQuery.of(context).size.width < 600 ? const EdgeInsets.symmetric(horizontal: 12) : null,
                              textStyle: MediaQuery.of(context).size.width < 600 ? const TextStyle(fontSize: 12) : null,
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
                                  context.read<MenuCubit>().fetchMenuData(
                                        search: state.currentSearch,
                                        categoryId: state.currentCategoryId,
                                        offset: 0,
                                        limit: newLimit,
                                        isAvailable: state.currentIsAvailable,
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
                                      context.read<MenuCubit>().fetchMenuData(
                                            search: state.currentSearch,
                                            categoryId: state.currentCategoryId,
                                            offset: state.menuOffset - state.limit,
                                            limit: state.limit,
                                            isAvailable: state.currentIsAvailable,
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
                                      context.read<MenuCubit>().fetchMenuData(
                                            search: state.currentSearch,
                                            categoryId: state.currentCategoryId,
                                            offset: state.menuOffset + state.limit,
                                            limit: state.limit,
                                            isAvailable: state.currentIsAvailable,
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
