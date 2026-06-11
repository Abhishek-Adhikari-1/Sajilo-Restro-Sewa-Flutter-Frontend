import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../cubit/menu_cubit.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MenuCubit>().fetchMenuData();
  }

  void _showAddEditMenuDialog({String? id, Map<String, dynamic>? initialData}) {
    final state = context.read<MenuCubit>().state;
    if (state is! MenuLoaded) return;

    final categories = state.categories;
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a category first before adding menu items.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: initialData?['name']);
    final descController = TextEditingController(text: initialData?['description']);
    final priceController = TextEditingController(text: initialData?['price']?.toString());
    final prepController = TextEditingController(text: initialData?['estimated_preparation_time']?.toString() ?? '15');
    String? selectedCategoryId = initialData?['category_id'] ?? categories.first.id;
    bool isAvailable = initialData?['is_available'] ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(id == null ? 'Add Menu Item' : 'Edit Menu Item'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategoryId,
                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                        items: categories.map((c) {
                          return DropdownMenuItem(value: c.id, child: Text(c.name));
                        }).toList(),
                        onChanged: (val) => setStateDialog(() => selectedCategoryId = val),
                        validator: (val) => val == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: prepController,
                        decoration: const InputDecoration(labelText: 'Prep Time (mins)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Available'),
                        value: isAvailable,
                        onChanged: (val) => setStateDialog(() => isAvailable = val),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (id != null)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () {
                      context.read<MenuCubit>().deleteMenuItem(id);
                      Navigator.pop(context);
                    },
                    child: const Text('Delete'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final data = {
                        'name': nameController.text,
                        'price': double.parse(priceController.text),
                        'category_id': selectedCategoryId,
                        if (descController.text.isNotEmpty) 'description': descController.text,
                        'estimated_preparation_time': int.tryParse(prepController.text) ?? 15,
                        'is_available': isAvailable,
                      };

                      if (id == null) {
                        context.read<MenuCubit>().createMenuItem(data);
                      } else {
                        context.read<MenuCubit>().updateMenuItem(id, data);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(id == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MenuCubit>().fetchMenuData(),
          ),
        ],
      ),
      body: BlocConsumer<MenuCubit, MenuState>(
        listener: (context, state) {
          if (state is MenuError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is MenuLoading && state is! MenuLoaded) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: LoadingShimmer.card(height: 80),
              ),
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
                  onPressed: _showAddEditMenuDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Menu Item'),
                ),
              );
            }

            final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

            return RefreshIndicator(
              onRefresh: () async {
                await context.read<MenuCubit>().fetchMenuData();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.menus.length,
                itemBuilder: (context, index) {
                  final item = state.menus[index];
                  final category = state.categories.firstWhere(
                    (c) => c.id == item.categoryId,
                    orElse: () => state.categories.first,
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: item.image != null && item.image!.isNotEmpty ? NetworkImage(item.image!) : null,
                        child: item.image == null || item.image!.isEmpty ? const Icon(Icons.fastfood, color: Colors.grey) : null,
                      ),
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${category.name} • ${item.estimatedPreparationTime} mins'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currencyFormat.format(item.price),
                            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: item.isAvailable,
                            onChanged: (val) {
                              context.read<MenuCubit>().toggleAvailability(item.id);
                            },
                          ),
                        ],
                      ),
                      onTap: () => _showAddEditMenuDialog(
                        id: item.id,
                        initialData: {
                          'name': item.name,
                          'description': item.description,
                          'price': item.price,
                          'category_id': item.categoryId,
                          'estimated_preparation_time': item.estimatedPreparationTime,
                          'is_available': item.isAvailable,
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEditMenuDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
