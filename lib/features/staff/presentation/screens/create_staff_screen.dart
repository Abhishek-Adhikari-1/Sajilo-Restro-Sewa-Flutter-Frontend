import 'package:sajilo_restro_sewa/core/errors/app_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/services/image_upload_service.dart';
import '../../../../core/errors/exceptions.dart';
import '../cubit/staff_cubit.dart';
import '../cubit/staff_state.dart';

class CreateStaffScreen extends StatefulWidget {
  const CreateStaffScreen({super.key});

  @override
  State<CreateStaffScreen> createState() => _CreateStaffScreenState();
}

class _CreateStaffScreenState extends State<CreateStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedRole = 'waiter';

  bool _isUploadingImage = false;
  String? _uploadedImageId;
  String? _uploadedImageUrl;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final result = await ImageUploadService.pickAndUpload(
        source: ImageSource.gallery,
        folder: 'avatars',
      );

      if (result != null) {
        setState(() {
          _uploadedImageId = result['id'] as String?;
          _uploadedImageUrl = result['url'] as String?;
        });
        if (mounted) {
          AppErrorHandler.showSuccess(context, 'Avatar uploaded successfully');
        }
      } else {
        if (mounted) {
          AppErrorHandler.show(context, 'Failed to upload avatar');
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        if (_uploadedImageId != null) 'imageId': _uploadedImageId,
      };

      context.read<StaffCubit>().createStaff(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Staff Member'),
      ),
      body: BlocConsumer<StaffCubit, StaffState>(
        listener: (context, state) {
          if (state is StaffLoaded && state.newStaffPassword != null) {
            // Success! Pop back to list screen, the list screen listener will show the password dialog
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          final isSaving = state is StaffLoaded ? state.isSaving : false;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: _uploadedImageUrl != null ? NetworkImage(_uploadedImageUrl!) : null,
                        child: _uploadedImageUrl == null
                            ? _isUploadingImage
                                ? const CircularProgressIndicator()
                                : Icon(Icons.person, size: 54, color: theme.colorScheme.onPrimaryContainer)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: theme.colorScheme.primary,
                          elevation: 4,
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            onPressed: _isUploadingImage || isSaving ? null : _pickAndUploadImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Upload Avatar (Optional)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'First name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Last name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email is required';
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (!emailRegex.hasMatch(val.trim())) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'waiter', child: Text('Waiter')),
                    DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                    DropdownMenuItem(value: 'kitchen', child: Text('Kitchen')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: isSaving
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() {
                              _selectedRole = val;
                            });
                          }
                        },
                ),
                const SizedBox(height: 12),
                Text(
                  'Note: A secure password will be generated automatically by the server.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 40),
                FilledButton(
                  onPressed: isSaving || _isUploadingImage ? null : _submitForm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Staff',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
