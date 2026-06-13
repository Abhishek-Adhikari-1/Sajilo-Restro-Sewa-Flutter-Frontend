import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sajilo_restro_sewa/core/errors/app_error_handler.dart';
import '../cubit/table_cubit.dart';

class AddEditTableScreen extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? initialData;

  const AddEditTableScreen({super.key, this.id, this.initialData});

  @override
  State<AddEditTableScreen> createState() => _AddEditTableScreenState();
}

class _AddEditTableScreenState extends State<AddEditTableScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tableNumberController = TextEditingController();
  final _sectionController = TextEditingController();
  final _capacityController = TextEditingController();
  String _status = 'available';
  bool _isLoading = false;

  final List<String> _statuses = ['available', 'occupied', 'reserved', 'cleaning', 'unavailable'];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _tableNumberController.text = widget.initialData!['tableNumber']?.toString() ?? '';
      _sectionController.text = widget.initialData!['section'] ?? '';
      _capacityController.text = widget.initialData!['capacity']?.toString() ?? '';
      _status = widget.initialData!['status'] ?? 'available';
    }
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    _sectionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = context.read<TableCubit>().repository;
      final data = {
        'tableNumber': int.parse(_tableNumberController.text),
        'section': _sectionController.text,
        'capacity': int.parse(_capacityController.text),
        'status': _status,
      };

      if (widget.id != null) {
        await repository.updateTable(widget.id!, data);
      } else {
        await repository.createTable(data);
      }

      if (mounted) {
        context.read<TableCubit>().fetchTables();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.id != null ? 'Table updated successfully' : 'Table created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id != null ? 'Edit Table' : 'Add Table'),
        scrolledUnderElevation: 0.0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _tableNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Table Number',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sectionController,
                      decoration: const InputDecoration(
                        labelText: 'Section (e.g., Indoor, Outdoor)',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.place),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(
                        labelText: 'Capacity (Number of seats)',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.chair),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      items: _statuses.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status[0].toUpperCase() + status.substring(1)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                      ),
                      child: Text(
                        widget.id != null ? 'Update Table' : 'Create Table',
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
    );
  }
}
