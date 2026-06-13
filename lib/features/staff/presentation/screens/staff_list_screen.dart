import 'package:sajilo_restro_sewa/core/errors/app_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../cubit/staff_cubit.dart';
import '../cubit/staff_state.dart';
import 'create_staff_screen.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StaffCubit>().fetchStaff();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
      ),
      body: BlocConsumer<StaffCubit, StaffState>(
        listener: (context, state) {
          if (state is StaffLoaded) {
            if (state.errorMessage != null) {
              AppErrorHandler.showError(context, state.errorMessage!);
              context.read<StaffCubit>().clearErrorMessage();
            }
          }
        },
        builder: (context, state) {
          if (state is StaffLoading) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: LoadingShimmer.list(count: 6),
            );
          }

          if (state is StaffError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Failed to load staff list',
              subtitle: state.message,
              action: ElevatedButton(
                onPressed: () => context.read<StaffCubit>().fetchStaff(),
                child: const Text('Try Again'),
              ),
            );
          }

          if (state is StaffLoaded) {
            final staffList = state.staff;
            final edits = state.editedStaff;

            if (staffList.isEmpty) {
              return EmptyState(
                icon: Icons.people_outline,
                title: 'No Staff Found',
                subtitle: 'Add a new staff member to manage your restaurant operations.',
                action: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateStaffScreen()),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Staff'),
                ),
              );
            }

            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () => context.read<StaffCubit>().fetchStaff(),
                  child: ListView.builder(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: edits.isNotEmpty ? 100 : 80,
                    ),
                    itemCount: staffList.length,
                    itemBuilder: (context, index) {
                      final user = staffList[index];
                      final hasEdits = edits.containsKey(user.id);
                      final currentRole = hasEdits ? (edits[user.id]!['role'] ?? user.role) : user.role;
                      final currentStatus = hasEdits ? (edits[user.id]!['status'] ?? user.status) : user.status;

                      Color statusColor;
                      switch (currentStatus.toLowerCase()) {
                        case 'active':
                          statusColor = Colors.green;
                          break;
                        case 'suspended':
                          statusColor = Colors.orange;
                          break;
                        case 'disabled':
                          statusColor = Colors.red;
                          break;
                        default:
                          statusColor = Colors.grey;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: hasEdits ? 3 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: hasEdits
                              ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                              : BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                                    ? NetworkImage(user.avatar!)
                                    : null,
                                child: user.avatar == null || user.avatar!.isEmpty
                                    ? Text(
                                        '${user.firstName[0].toUpperCase()}${user.lastName[0].toUpperCase()}',
                                        style: TextStyle(
                                          color: theme.colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${user.firstName} ${user.lastName}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        if (hasEdits) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primaryContainer,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Edited',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: theme.colorScheme.onPrimaryContainer,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email,
                                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            currentRole.toUpperCase(),
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          currentStatus,
                                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (action) {
                                  if (action == 'suspend') {
                                    context.read<StaffCubit>().updateStaffFieldLocal(user.id, status: 'suspended');
                                  } else if (action == 'disable') {
                                    context.read<StaffCubit>().updateStaffFieldLocal(user.id, status: 'disabled');
                                  } else if (action == 'activate') {
                                    context.read<StaffCubit>().updateStaffFieldLocal(user.id, status: 'active');
                                  } else if (action.startsWith('role_')) {
                                    final newRole = action.substring(5);
                                    context.read<StaffCubit>().updateStaffFieldLocal(user.id, role: newRole);
                                  }
                                },
                                itemBuilder: (context) {
                                  return [
                                    if (currentStatus != 'active')
                                      const PopupMenuItem(value: 'activate', child: Text('Activate Staff')),
                                    if (currentStatus != 'suspended')
                                      const PopupMenuItem(value: 'suspend', child: Text('Suspend Staff')),
                                    if (currentStatus != 'disabled')
                                      const PopupMenuItem(value: 'disable', child: Text('Disable Staff')),
                                    const PopupMenuDivider(),
                                    PopupMenuItem(
                                      child: const Text('Change Role'),
                                      onTap: () {}, // Handled by submenus or manual select
                                    ),
                                    PopupMenuItem(
                                      value: 'role_admin',
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 12.0),
                                        child: Text('→ Admin', style: TextStyle(fontWeight: currentRole == 'admin' ? FontWeight.bold : FontWeight.normal)),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'role_waiter',
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 12.0),
                                        child: Text('→ Waiter', style: TextStyle(fontWeight: currentRole == 'waiter' ? FontWeight.bold : FontWeight.normal)),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'role_cashier',
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 12.0),
                                        child: Text('→ Cashier', style: TextStyle(fontWeight: currentRole == 'cashier' ? FontWeight.bold : FontWeight.normal)),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'role_kitchen',
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 12.0),
                                        child: Text('→ Kitchen', style: TextStyle(fontWeight: currentRole == 'kitchen' ? FontWeight.bold : FontWeight.normal)),
                                      ),
                                    ),
                                  ];
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (edits.isNotEmpty)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Card(
                      color: theme.colorScheme.primaryContainer,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.primary, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Unsaved changes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimaryContainer,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    '${edits.length} user record(s) modified.',
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: state.isSaving
                                  ? null
                                  : () => context.read<StaffCubit>().discardChanges(),
                              child: Text(
                                'Discard',
                                style: TextStyle(color: theme.colorScheme.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: state.isSaving
                                  ? null
                                  : () => context.read<StaffCubit>().saveChanges(),
                              child: state.isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Save'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateStaffScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
