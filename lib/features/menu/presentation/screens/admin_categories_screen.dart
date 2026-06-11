import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../cubit/menu_cubit.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MenuCubit>().fetchMenuData();
  }

  void _showAddEditCategoryDialog({String? id, Map<String, dynamic>? initialData}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: initialData?['name']);
    final iconController = TextEditingController(text: initialData?['icon'] ?? '🍽️');
    bool isActive = initialData?['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(id == null ? 'Add Category' : 'Edit Category'),
              content: Form(
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
                      controller: iconController,
                      decoration: const InputDecoration(labelText: 'Icon (Emoji)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: isActive,
                      onChanged: (val) => setStateDialog(() => isActive = val),
                    ),
                  ],
                ),
              ),
              actions: [
                if (id != null)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () {
                      context.read<MenuCubit>().deleteCategory(id);
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
                        'icon': iconController.text.isEmpty ? null : iconController.text,
                        'is_active': isActive,
                      };

                      if (id == null) {
                        context.read<MenuCubit>().createCategory(data);
                      } else {
                        context.read<MenuCubit>().updateCategory(id, data);
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
        title: const Text('Manage Categories'),
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
                child: LoadingShimmer.card(height: 60),
              ),
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
            if (state.categories.isEmpty) {
              return EmptyState(
                icon: Icons.category,
                title: 'No Categories',
                subtitle: 'Add categories to group your menu items.',
                action: ElevatedButton.icon(
                  onPressed: _showAddEditCategoryDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await context.read<MenuCubit>().fetchMenuData();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.categories.length,
                itemBuilder: (context, index) {
                  final category = state.categories[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        child: Text(category.icon ?? '🍽️', style: const TextStyle(fontSize: 20)),
                      ),
                      title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Icon(
                        category.isActive ? Icons.check_circle : Icons.cancel,
                        color: category.isActive ? Colors.green : Colors.grey,
                      ),
                      onTap: () => _showAddEditCategoryDialog(
                        id: category.id,
                        initialData: {
                          'name': category.name,
                          'icon': category.icon,
                          'is_active': category.isActive,
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
        onPressed: _showAddEditCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
