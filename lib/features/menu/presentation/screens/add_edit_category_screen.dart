import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/services/image_upload_service.dart';
import '../cubit/menu_cubit.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/app_error_handler.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? initialData;

  const AddEditCategoryScreen({
    super.key,
    this.id,
    this.initialData,
  });

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late bool _isActive;

  String? _uploadedImageId;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?['name']);
    _descController = TextEditingController(
      text: widget.initialData?['description'],
    );
    _isActive = widget.initialData?['is_active'] ?? true;
    _uploadedImageId = widget.initialData?['icon_id'];
    _uploadedImageUrl = widget.initialData?['icon'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final result = await ImageUploadService.pickAndUpload(
        source: ImageSource.gallery,
        folder: 'categories',
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
    final initialDesc = widget.initialData?['description'] ?? '';
    final initialActive = widget.initialData?['is_active'] ?? true;
    final initialImageId = widget.initialData?['icon_id'];

    return _nameController.text.trim() != initialName ||
        _descController.text.trim() != initialDesc ||
        _isActive != initialActive ||
        _uploadedImageId != initialImageId;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'name': _nameController.text.trim(),
        if (_descController.text.isNotEmpty)
          'description': _descController.text.trim(),
        'isActive': _isActive,
        if (_uploadedImageId != null) 'iconId': _uploadedImageId,
      };

      if (widget.id == null) {
        context.read<MenuCubit>().createCategory(data);
      } else {
        context.read<MenuCubit>().updateCategory(widget.id!, data);
      }
      Navigator.pop(context);
    } else {
      AppErrorHandler.show(
        context,
        'Please fix the validation errors in the form',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Add Category' : 'Edit Category'),
        actions: [
          if (widget.id != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Category?'),
                    content: const Text(
                      'Are you sure you want to delete this category?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<MenuCubit>().deleteCategory(widget.id!);
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
                                        Icons.add_photo_alternate,
                                        size: 48,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Upload Category Image (Optional)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.colorScheme.onSurfaceVariant,
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
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const Center(child: CircularProgressIndicator());
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(Icons.broken_image, size: 48),
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
                                          backgroundColor: theme.colorScheme.primary,
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
                            _isActive = !_isActive;
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Active',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Checkbox(
                              value: _isActive,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (val) {
                                setState(() {
                                  _isActive = val ?? false;
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
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: _isUploadingImage ? null : _submitForm,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                        ),
                        child: Text(
                          widget.id == null ? 'Add Category' : 'Save Changes',
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
