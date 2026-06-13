import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/services/image_upload_service.dart';
import '../cubit/menu_cubit.dart';
import '../../data/models/category_model.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/repositories/menu_repository.dart';
import '../../../../core/errors/app_error_handler.dart';

class AddEditMenuScreen extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? initialData;
  final List<CategoryModel> categories;

  const AddEditMenuScreen({
    super.key,
    this.id,
    this.initialData,
    required this.categories,
  });

  @override
  State<AddEditMenuScreen> createState() => _AddEditMenuScreenState();
}

class _AddEditMenuScreenState extends State<AddEditMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descController;
  late final TextEditingController _prepController;
  late CategoryModel _selectedCategory;
  late bool _isAvailable;

  String? _uploadedImageId;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?['name']);
    _priceController = TextEditingController(
      text: widget.initialData?['price']?.toString(),
    );
    _descController = TextEditingController(
      text: widget.initialData?['description'],
    );
    _prepController = TextEditingController(
      text:
          widget.initialData?['estimated_preparation_time']?.toString() ?? '15',
    );

    final categoryId = widget.initialData?['category_id'];
    _selectedCategory = widget.categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => widget.categories.first,
    );
    _isAvailable = widget.initialData?['is_available'] ?? true;
    _uploadedImageId = widget.initialData?['image_id'];
    _uploadedImageUrl = widget.initialData?['image'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _prepController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final result = await ImageUploadService.pickAndUpload(
        source: ImageSource.gallery,
        folder: 'menu_items',
      );

      if (result != null) {
        setState(() {
          _uploadedImageId = result['id'] as String?;
          _uploadedImageUrl = result['url'] as String?;
        });
        if (mounted) {
          AppErrorHandler.showSuccess(context, 'Image uploaded successfully');
        }
      } else {
        if (mounted) {
          AppErrorHandler.show(
            context,
            'Failed to upload image. Please try again.',
          );
        }
      }
    } catch (e) {
      String errMsg = 'Upload failed: $e';
      if (e is ApiException) {
        if (e.errors != null && e.errors!.isNotEmpty) {
          errMsg = e.errors!.map((ve) => ve.message).join('\n');
        } else {
          errMsg = e.message;
        }
      }
      if (mounted) {
        AppErrorHandler.show(context, errMsg);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  bool _hasChanges() {
    final initialName = widget.initialData?['name'] ?? '';
    final initialPrice = widget.initialData?['price']?.toString() ?? '';
    final initialDesc = widget.initialData?['description'] ?? '';
    final initialPrep = widget.initialData?['estimated_preparation_time']?.toString() ?? '15';
    
    final categoryId = widget.initialData?['category_id'];
    final initialCategory = widget.categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => widget.categories.first,
    );
    
    final initialAvailable = widget.initialData?['is_available'] ?? true;
    final initialImageId = widget.initialData?['image_id'];

    return _nameController.text.trim() != initialName ||
        _priceController.text.trim() != initialPrice ||
        _descController.text.trim() != initialDesc ||
        _prepController.text.trim() != initialPrep ||
        _selectedCategory.id != initialCategory.id ||
        _isAvailable != initialAvailable ||
        _uploadedImageId != initialImageId;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Sending all payload fields in Camel Case!
      final data = {
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'categoryId': _selectedCategory.id,
        if (_descController.text.isNotEmpty)
          'description': _descController.text.trim(),
        'estimatedPreparationTime':
            int.tryParse(_prepController.text.trim()) ?? 15,
        'isAvailable': _isAvailable,
        if (_uploadedImageId != null) 'imageId': _uploadedImageId,
      };

      if (widget.id == null) {
        context.read<MenuCubit>().createMenuItem(data);
      } else {
        context.read<MenuCubit>().updateMenuItem(widget.id!, data);
      }
      Navigator.pop(context);
    } else {
      AppErrorHandler.show(
        context,
        'Please fix the validation errors in the form',
      );
    }
  }

  void _showSearchCategoryDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _CategorySearchDialog(
          initialCategories: widget.categories,
          selectedCategory: _selectedCategory,
          menuRepository: context.read<MenuCubit>().repository,
          onCategorySelected: (category) {
            setState(() {
              _selectedCategory = category;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Add Menu Item' : 'Edit Menu Item'),
        actions: [
          if (widget.id != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Menu Item?'),
                    content: const Text(
                      'Are you sure you want to delete this menu item?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<MenuCubit>().deleteMenuItem(widget.id!);
                          Navigator.pop(context); // close dialog
                          Navigator.pop(context); // close screen
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (!_hasChanges()) {
            Navigator.pop(context);
            return;
          }
          final navigator = Navigator.of(context);
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Discard Changes?'),
              content: const Text(
                'You have unsaved changes. Are you sure you want to discard them?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Discard'),
                ),
              ],
            ),
          );
          if (shouldPop == true && mounted) {
            navigator.pop();
          }
        },
        child: BlocListener<MenuCubit, MenuState>(
          listener: (context, state) {
            if (state is MenuError) {
              AppErrorHandler.show(context, state.message);
            }
          },
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image upload is FIRST (Shows as Cover, not cropped)
                    GestureDetector(
                      onTap: _isUploadingImage ? null : _pickAndUploadImage,
                      child: Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: _uploadedImageUrl == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isUploadingImage)
                                    const CircularProgressIndicator()
                                  else ...[
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 48,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Upload Food Image (Optional)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            : Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.network(
                                        _uploadedImageUrl!,
                                        fit: BoxFit.contain,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 48,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                  if (_isUploadingImage)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black26,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundColor:
                                            theme.colorScheme.primary,
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isAvailable = !_isAvailable;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Available',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Checkbox(
                            value: _isAvailable,
                            activeColor: theme.colorScheme.primary,
                            onChanged: (val) {
                              setState(() {
                                _isAvailable = val ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.drive_file_rename_outline),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Name cannot be empty';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Price cannot be empty';
                        }
                        final price = double.tryParse(val.trim());
                        if (price == null) {
                          return 'Enter a valid decimal number for price';
                        }
                        if (price <= 0) {
                          return 'Price must be greater than zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Searchable Combo Box selector for Categories
                    InkWell(
                      onTap: _showSearchCategoryDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.restaurant_menu),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        child: Row(
                          children: [
                            if (_selectedCategory.icon != null &&
                                _selectedCategory.icon!.isNotEmpty)
                              CircleAvatar(
                                radius: 12,
                                backgroundImage: NetworkImage(
                                  _selectedCategory.icon!,
                                ),
                              )
                            else
                              const Icon(Icons.restaurant, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              _selectedCategory.name,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descController,
                      minLines: 3,
                      maxLines: 3,
                      autocorrect: true,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 45),
                          child: Icon(Icons.description),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _prepController,
                      decoration: const InputDecoration(
                        labelText: 'Prep Time (mins)',
                        prefixIcon: Icon(Icons.timer),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Preparation time cannot be empty';
                        }
                        final prep = int.tryParse(val.trim());
                        if (prep == null) {
                          return 'Enter a valid whole number for prep time';
                        }
                        if (prep <= 0) {
                          return 'Prep time must be greater than zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _isUploadingImage ? null : _submitForm,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                      ),
                      child: Text(
                        widget.id == null ? 'Add Menu Item' : 'Save Changes',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _CategorySearchDialog extends StatefulWidget {
  final List<CategoryModel> initialCategories;
  final CategoryModel selectedCategory;
  final MenuRepository menuRepository;
  final Function(CategoryModel) onCategorySelected;

  const _CategorySearchDialog({
    required this.initialCategories,
    required this.selectedCategory,
    required this.menuRepository,
    required this.onCategorySelected,
  });

  @override
  State<_CategorySearchDialog> createState() => _CategorySearchDialogState();
}

class _CategorySearchDialogState extends State<_CategorySearchDialog> {
  late List<CategoryModel> _categories;
  bool _isLoading = false;
  Timer? _debounceTimer;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _categories = widget.initialCategories;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });
      try {
        final (results, _) = await widget.menuRepository.getCategories(
          search: query.trim().isEmpty ? null : query.trim(),
          limit: 50,
        );
        if (mounted) {
          setState(() {
            _categories = results;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Category'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search categories...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _categories.isEmpty
                    ? const Center(child: Text('No categories found'))
                    : ListView.builder(
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected =
                              category.id == widget.selectedCategory.id;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.15)
                                  : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.15),
                              backgroundImage:
                                  category.icon != null &&
                                      category.icon!.isNotEmpty
                                  ? NetworkImage(category.icon!)
                                  : null,
                              child:
                                  category.icon == null ||
                                      category.icon!.isEmpty
                                  ? const Icon(Icons.restaurant, size: 18)
                                  : null,
                            ),
                            title: Text(
                              category.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : null,
                            onTap: () {
                              widget.onCategorySelected(category);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
