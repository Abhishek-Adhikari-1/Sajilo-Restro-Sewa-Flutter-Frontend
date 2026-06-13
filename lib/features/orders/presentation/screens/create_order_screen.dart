import 'package:sajilo_restro_sewa/core/errors/app_error_handler.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../tables/data/models/table_model.dart';
import '../../../menu/presentation/cubit/menu_cubit.dart';
import '../../../menu/data/models/menu_item_model.dart';
import '../../../menu/data/models/category_model.dart';
import '../cubit/order_cubit.dart';
import '../../data/models/order_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../../shared/widgets/custom_filter_chip.dart';
import '../../../tables/presentation/cubit/table_cubit.dart';
import '../../../tables/presentation/cubit/table_state.dart';

class CreateOrderScreen extends StatefulWidget {
  final TableModel table;
  final OrderModel? existingOrder;

  const CreateOrderScreen({super.key, required this.table, this.existingOrder});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  String? _selectedCategoryId;
  final ValueNotifier<List<OrderItemModel>> _cartNotifier = ValueNotifier([]);
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final currencyFormat = NumberFormat.currency(
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  final ScrollController _menusScrollController = ScrollController();
  final ScrollController _categoriesScrollController = ScrollController();
  Timer? _debounce;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    context.read<MenuCubit>().fetchMenuData();
    if (widget.existingOrder != null) {
      _cartNotifier.value = List.from(widget.existingOrder!.items);
      if (widget.existingOrder!.notes != null) {
        _notesController.text = widget.existingOrder!.notes!;
      }
    }
    _menusScrollController.addListener(_onMenusScroll);
    _categoriesScrollController.addListener(_onCategoriesScroll);
  }

  void _onMenusScroll() {
    if (_menusScrollController.position.pixels >= _menusScrollController.position.maxScrollExtent - 50) {
      context.read<MenuCubit>().fetchMoreMenus();
    }
  }

  void _onCategoriesScroll() {
    if (_categoriesScrollController.position.pixels >= _categoriesScrollController.position.maxScrollExtent - 50) {
      context.read<MenuCubit>().fetchMoreCategories();
    }
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val.trim();
    });
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<MenuCubit>().fetchMenuData(search: _searchQuery, categoryId: _selectedCategoryId);
    });
  }

  void _onCategorySelected(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    setState(() => _selectedCategoryId = categoryId);
    context.read<MenuCubit>().fetchMenuData(search: _searchQuery, categoryId: _selectedCategoryId);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _notesController.dispose();
    _searchController.dispose();
    _menusScrollController.dispose();
    _categoriesScrollController.dispose();
    _cartNotifier.dispose();
    super.dispose();
  }

  void _addToCart(MenuItemModel item) {
    final currentList = List<OrderItemModel>.from(_cartNotifier.value);
    final existingIndex = currentList.indexWhere(
      (element) => element.id == item.id && element.status == 'pending',
    );
    if (existingIndex >= 0) {
      final existing = currentList[existingIndex];
      currentList[existingIndex] = OrderItemModel(
        id: existing.id,
        name: existing.name,
        price: existing.price,
        quantity: existing.quantity + 1,
        specialInstructions: existing.specialInstructions,
        status: 'pending',
      );
    } else {
      currentList.add(
        OrderItemModel(
          id: item.id,
          name: item.name,
          price: item.price,
          quantity: 1,
        ),
      );
    }
    _cartNotifier.value = currentList;
  }

  void _updateQuantity(int index, int delta) {
    final currentList = List<OrderItemModel>.from(_cartNotifier.value);
    final item = currentList[index];
    final newQty = item.quantity + delta;
    if (newQty <= 0) {
      currentList.removeAt(index);
    } else {
      currentList[index] = OrderItemModel(
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: newQty,
        specialInstructions: item.specialInstructions,
        status: item.status,
      );
    }
    _cartNotifier.value = currentList;
  }

  void _updateInstructions(int index, String? instructions) {
    final currentList = List<OrderItemModel>.from(_cartNotifier.value);
    final item = currentList[index];
    currentList[index] = OrderItemModel(
      id: item.id,
      name: item.name,
      price: item.price,
      quantity: item.quantity,
      specialInstructions: instructions,
      status: item.status,
    );
    _cartNotifier.value = currentList;
  }

  double get _totalAmount {
    return _cartNotifier.value.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  Future<void> _showNotesDialog({
    required BuildContext context,
    required String initialNote,
    required String title,
    required String hintText,
    required Function(String) onSave,
  }) async {
    final controller = TextEditingController(text: initialNote);
    final focusNode = FocusNode();
    final allSuggestions = [
      'Less Spicy',
      'Extra Spicy',
      'No Onion',
      'Extra Cheese',
      'To Go',
      'More Toppings',
    ];

    // Auto focus
    Future.delayed(
      const Duration(milliseconds: 100),
      () => focusNode.requestFocus(),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentTextLower = controller.text.toLowerCase();
            final availableSuggestions = allSuggestions
                .where((s) => !currentTextLower.contains(s.toLowerCase()))
                .toList();

            return AlertDialog(
              title: Text(title),
              content: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (availableSuggestions.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: availableSuggestions
                              .map(
                                (s) => ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(
                                    s,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () {
                                    final currentText = controller.text;
                                    controller.text = currentText.isEmpty
                                        ? s
                                        : '$currentText, $s';
                                    controller.selection =
                                        TextSelection.collapsed(
                                          offset: controller.text.length,
                                        );
                                    setDialogState(() {});
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      if (availableSuggestions.isNotEmpty)
                        const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        focusNode: focusNode,
                        maxLines: 3,
                        onChanged: (val) => setDialogState(() {}),
                        decoration: InputDecoration(
                          hintText: hintText,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () {
                    onSave(controller.text.trim());
                    Navigator.pop(context);
                  },
                  child: const Text('Okay'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showItemDetailsDialog(
    BuildContext context,
    MenuItemModel item,
    List<CategoryModel> categories,
    ThemeData theme,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final category = categories.firstWhere(
          (c) => c.id == item.categoryId,
          orElse: () => CategoryModel(
            id: '',
            name: 'Unknown',
            description: null,
            icon: null,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        return AlertDialog(
          title: Text(item.name),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.image != null && item.image!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.image!,
                      height: 150,
                      width: double.maxFinite,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                if (item.image != null && item.image!.isNotEmpty)
                  const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price: ${currencyFormat.format(item.price)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.category,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category.name,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (category.description != null &&
                    category.description!.isNotEmpty) ...[
                  Text(
                    'Category Info: ${category.description!}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (item.description != null && item.description!.isNotEmpty)
                  Text(item.description!, style: theme.textTheme.bodyMedium),
                if (item.description != null && item.description!.isNotEmpty)
                  const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text('Prep Time: ${item.estimatedPreparationTime} mins'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      item.isAvailable ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: item.isAvailable ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.isAvailable ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        color: item.isAvailable ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: item.isAvailable
                  ? () {
                      Navigator.pop(context);
                      _addToCart(item);
                    }
                  : null,
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('Add to Order'),
            ),
          ],
        );
      },
    );
  }

  void _submitOrder() async {
    if (_cartNotifier.value.isEmpty) {
      AppErrorHandler.show(context, 'Add at least one item to the order.');
      return;
    }

    if (widget.existingOrder != null) {
      setState(() => _isSubmitting = true);
      context.read<OrderCubit>().updateOrderItems(
        widget.existingOrder!.id,
        _cartNotifier.value,
        _notesController.text.trim(),
      );
      return;
    }

    int availableSeats = widget.table.capacity - widget.table.occupiedSeats;
    if (availableSeats < 1) availableSeats = 1; // Fallback

    int guestsCount = 1;
    final int? result = await showDialog<int>(
      context: context,
      builder: (context) {
        int tempCount = 1;
        return AlertDialog(
          title: const Text('Number of Guests'),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          content: StatefulBuilder(
            builder: (context, setState) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: tempCount > 1
                        ? () => setState(() => tempCount--)
                        : null,
                  ),
                  Text(
                    '$tempCount',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: tempCount < availableSeats
                        ? () => setState(() => tempCount++)
                        : null,
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: () => Navigator.pop(context, tempCount),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (result == null) return; // Cancelled
    guestsCount = result;

    final authState = context.read<AuthCubit>().state;
    String userId = 'unknown';
    if (authState is Authenticated) {
      userId = authState.user.id;
    }

    final newOrder = OrderModel(
      id: '', // Generated by backend
      tableId: widget.table.id,
      status: 'pending',
      items: _cartNotifier.value,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdBy: userId,
      guestsCount: guestsCount,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Optimistic UI Update for Table
    final newOccupiedSeats = widget.table.occupiedSeats + guestsCount;
    context.read<TableCubit>().updateTableDetailsOptimistic(widget.table.id, {
      'status': "occupied",
      'occupied_seats': newOccupiedSeats,
    });

    setState(() => _isSubmitting = true);
    context.read<OrderCubit>().createOrder(newOrder);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isEditing = widget.existingOrder != null;

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<TableCubit, TableState>(
          builder: (context, state) {
            TableModel currentTable = widget.table;
            if (state is TableLoaded) {
              try {
                currentTable = state.tables.firstWhere((t) => t.id == widget.table.id);
              } catch (_) {}
            }
            final availableSeats = currentTable.capacity - currentTable.occupiedSeats;
            return Text(
              isEditing
                  ? 'Edit Order Items'
                  : 'New Order - Table ${currentTable.tableNumber} ($availableSeats Seats Available)',
            );
          },
        ),
        actions: [
          if (isEditing && widget.table.status != 'reserved')
            TextButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await context.read<TableCubit>().updateSingleTableStatus(widget.table.id, 'reserved');
                  if (context.mounted) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Table marked as reserved!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.lock_outline, color: Colors.orange),
              label: const Text('Mark Reserved', style: TextStyle(color: Colors.orange)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: isMobile ? _buildMobileBottomBar(theme) : null,
      body: BlocListener<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderError) {
            if (_isSubmitting) {
              AppErrorHandler.showError(context, state.message);
              setState(() => _isSubmitting = false);
            }
          } else if (state is OrderLoaded) {
            if (_isSubmitting) {
              AppErrorHandler.showSuccess(context, isEditing
                        ? 'Items added successfully!'
                        : 'Order submitted successfully!',);
              Navigator.pop(context);
            }
          }
        },
        child: isMobile
            ? _buildMenuBrowser(theme)
            : Row(
                children: [
                  Expanded(flex: 2, child: _buildMenuBrowser(theme)),
                  const VerticalDivider(width: 1),
                  Expanded(flex: 1, child: _buildCart(theme)),
                ],
              ),
      ),
    );
  }

  Widget _buildMobileBottomBar(ThemeData theme) {
    return ValueListenableBuilder<List<OrderItemModel>>(
      valueListenable: _cartNotifier,
      builder: (context, cartItems, child) {
        if (cartItems.isEmpty) return const SizedBox.shrink();
        
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cartItems.length} Item${cartItems.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currencyFormat.format(_totalAmount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _showMobileCartSheet(theme),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text('View Order'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _showMobileCartSheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: _buildCart(theme),
          ),
        );
      },
    );
  }

  Widget _buildMenuBrowser(ThemeData theme) {
    return BlocBuilder<MenuCubit, MenuState>(
      builder: (context, state) {
        if (state is MenuLoading) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: LoadingShimmer.grid(count: 6),
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
          final categories = state.categories;
          final items = state.menus;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search menu, category, price...',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 12.0, right: 8.0),
                      child: Icon(Icons.search),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Categories
              SizedBox(
                height: 60,
                child: ListView(
                  controller: _categoriesScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    CustomFilterChip(
                      label: 'All',
                      isSelected: _selectedCategoryId == null,
                      onSelected: (_) => _onCategorySelected(null),
                    ),
                    const SizedBox(width: 8),
                    ...categories.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CustomFilterChip(
                          label: c.name,
                          isSelected: _selectedCategoryId == c.id,
                          onSelected: (_) => _onCategorySelected(c.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // Menu Items Grid
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<MenuCubit>().fetchMenuData(),
                  child: items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            EmptyState(
                              icon: Icons.restaurant_menu,
                              title: 'No items found',
                            ),
                          ],
                        )
                      : GridView.builder(
                          controller: _menusScrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    MediaQuery.of(context).size.width < 600
                                    ? 2
                                    : 3,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              elevation: theme.brightness == Brightness.light
                                  ? 0
                                  : 1,
                              shape: RoundedRectangleBorder(
                                side: theme.brightness == Brightness.light
                                    ? BorderSide(
                                        color: theme.colorScheme.outlineVariant,
                                      )
                                    : BorderSide.none,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: item.isAvailable ? () => _addToCart(item) : null,
                                onLongPress: () => _showItemDetailsDialog(
                                  context,
                                  item,
                                  categories,
                                  theme,
                                ),
                                child: Stack(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            color: theme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            child:
                                                item.image != null &&
                                                    item.image!.isNotEmpty
                                                ? Image.network(
                                                    item.image!,
                                                    fit: BoxFit.cover,
                                                    color: item.isAvailable ? null : Colors.white.withValues(alpha: 0.5),
                                                    colorBlendMode: item.isAvailable ? null : BlendMode.lighten,
                                                  )
                                                : Icon(
                                                    Icons.fastfood,
                                                    size: 48,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant
                                                        .withValues(alpha: item.isAvailable ? 1.0 : 0.5),
                                                  ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: theme.textTheme.titleSmall
                                                    ?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: item.isAvailable ? null : Colors.grey,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                currencyFormat.format(item.price),
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: item.isAvailable 
                                                          ? theme.colorScheme.primary
                                                          : Colors.grey,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: item.isAvailable ? Colors.green.withValues(alpha: 0.8) : Colors.red.withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.isAvailable ? 'Available' : 'Unavailable',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
    );
  }

  Widget _buildCart(ThemeData theme) {
    return ValueListenableBuilder<List<OrderItemModel>>(
      valueListenable: _cartNotifier,
      builder: (context, cartItems, child) {
        return Container(
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order Summary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${cartItems.length} items',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: cartItems.isEmpty
                ? Center(
                    child: Text(
                      'Cart is empty',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final canEdit = item.status == 'pending';
                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${currencyFormat.format(item.price * item.quantity)} • ${item.status.toUpperCase()}',
                            ),
                            trailing: canEdit
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                        onPressed: () =>
                                            _updateQuantity(index, -1),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                        onPressed: () =>
                                            _updateQuantity(index, 1),
                                      ),
                                    ],
                                  )
                                : Padding(
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: Text(
                                      '${item.quantity}x',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                          ),
                          if (canEdit)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  _showNotesDialog(
                                    context: context,
                                    initialNote: item.specialInstructions ?? '',
                                    title: 'Item Notes (${item.name})',
                                    hintText:
                                        'e.g., less spicy, extra cheese...',
                                    onSave: (val) {
                                      _updateInstructions(
                                        index,
                                        val.isEmpty ? null : val,
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_note,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          (item.specialInstructions?.isEmpty ??
                                                  true)
                                              ? 'Add note (e.g. less spicy)'
                                              : item.specialInstructions!,
                                          style: TextStyle(
                                            color:
                                                (item
                                                        .specialInstructions
                                                        ?.isEmpty ??
                                                    true)
                                                ? theme
                                                      .colorScheme
                                                      .onSurfaceVariant
                                                      .withValues(alpha: 0.6)
                                                : theme.colorScheme.onSurface,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else if (item.specialInstructions != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Note: ${item.specialInstructions}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ),
                          const Divider(),
                        ],
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _notesController,
              readOnly: true,
              onTap: () {
                _showNotesDialog(
                  context: context,
                  initialNote: _notesController.text,
                  title: 'General Order Notes',
                  hintText: 'e.g., make it fast, allergies...',
                  onSave: (val) {
                    setState(() {
                      _notesController.text = val;
                    });
                  },
                );
              },
              decoration: InputDecoration(
                hintText: 'Add general notes for the kitchen...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.speaker_notes,
                  color: theme.colorScheme.primary,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 2,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total Amount', style: theme.textTheme.bodySmall),
                        Text(
                          currencyFormat.format(_totalAmount),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BlocBuilder<OrderCubit, OrderState>(
                    builder: (context, state) {
                      final isLoading = state is OrderLoading;
                      return FilledButton(
                        onPressed: isLoading ? null : _submitOrder,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.existingOrder != null
                                    ? 'Update Order'
                                    : 'Place Order',
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}
