import 'package:sajilo_restro_sewa/core/errors/app_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../cubit/staff_cubit.dart';
import '../cubit/staff_state.dart';
import 'create_staff_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Result object passed back from the sheet to the parent after a send succeeds.
// ─────────────────────────────────────────────────────────────────────────────

class _EmailSendResult {
  final String message;
  const _EmailSendResult(this.message);
}

// ─────────────────────────────────────────────────────────────────────────────
// StaffListScreen
// ─────────────────────────────────────────────────────────────────────────────

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

  // ─── Send Email Dialog ──────────────────────────────────────────────────────
  // The cubit is captured BEFORE the sheet opens so we never call
  // context.read<>() across an async boundary.
  // Success is shown only AFTER the sheet closes and this widget is mounted.

  Future<void> _showSendEmailDialog({
    String? to,
    String? recipientName,
  }) async {
    final cubit = context.read<StaffCubit>();

    final result = await showModalBottomSheet<_EmailSendResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SendEmailSheet(
        to: to,
        recipientName: recipientName,
        cubit: cubit,
      ),
    );

    if (result != null && mounted) {
      AppErrorHandler.showSuccess(context, result.message);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read_rounded),
            tooltip: 'Send Email to All Staff',
            onPressed: () => _showSendEmailDialog(),
          ),
        ],
      ),
      body: BlocConsumer<StaffCubit, StaffState>(
        listener: (context, state) {
          if (state is StaffLoaded && state.errorMessage != null) {
            AppErrorHandler.showError(context, state.errorMessage!);
            context.read<StaffCubit>().clearErrorMessage();
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
                      final currentRole =
                          hasEdits ? (edits[user.id]!['role'] ?? user.role) : user.role;
                      final currentStatus =
                          hasEdits ? (edits[user.id]!['status'] ?? user.status) : user.status;

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
                              : BorderSide(
                                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                backgroundImage:
                                    user.avatar != null && user.avatar!.isNotEmpty
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
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        if (hasEdits) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
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
                                      style: TextStyle(
                                          color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            currentRole.toUpperCase(),
                                            style: const TextStyle(
                                                fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                              color: statusColor, shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          currentStatus,
                                          style: TextStyle(
                                              color: statusColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500),
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
                                    context
                                        .read<StaffCubit>()
                                        .updateStaffFieldLocal(user.id, status: 'suspended');
                                  } else if (action == 'disable') {
                                    context
                                        .read<StaffCubit>()
                                        .updateStaffFieldLocal(user.id, status: 'disabled');
                                  } else if (action == 'activate') {
                                    context
                                        .read<StaffCubit>()
                                        .updateStaffFieldLocal(user.id, status: 'active');
                                  } else if (action.startsWith('role_')) {
                                    context.read<StaffCubit>().updateStaffFieldLocal(
                                          user.id,
                                          role: action.substring(5),
                                        );
                                  } else if (action == 'send_email') {
                                    _showSendEmailDialog(
                                      to: user.email,
                                      recipientName: '${user.firstName} ${user.lastName}',
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'send_email',
                                    child: Row(
                                      children: [
                                        Icon(Icons.email_outlined, size: 18),
                                        SizedBox(width: 10),
                                        Text('Send Email'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  if (currentStatus != 'active')
                                    const PopupMenuItem(
                                        value: 'activate', child: Text('Activate Staff')),
                                  if (currentStatus != 'suspended')
                                    const PopupMenuItem(
                                        value: 'suspend', child: Text('Suspend Staff')),
                                  if (currentStatus != 'disabled')
                                    const PopupMenuItem(
                                        value: 'disable', child: Text('Disable Staff')),
                                  const PopupMenuDivider(),
                                  PopupMenuItem(child: const Text('Change Role'), onTap: () {}),
                                  PopupMenuItem(
                                    value: 'role_admin',
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 12.0),
                                      child: Text('→ Admin',
                                          style: TextStyle(
                                              fontWeight: currentRole == 'admin'
                                                  ? FontWeight.bold
                                                  : FontWeight.normal)),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'role_waiter',
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 12.0),
                                      child: Text('→ Waiter',
                                          style: TextStyle(
                                              fontWeight: currentRole == 'waiter'
                                                  ? FontWeight.bold
                                                  : FontWeight.normal)),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'role_cashier',
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 12.0),
                                      child: Text('→ Cashier',
                                          style: TextStyle(
                                              fontWeight: currentRole == 'cashier'
                                                  ? FontWeight.bold
                                                  : FontWeight.normal)),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'role_kitchen',
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 12.0),
                                      child: Text('→ Kitchen',
                                          style: TextStyle(
                                              fontWeight: currentRole == 'kitchen'
                                                  ? FontWeight.bold
                                                  : FontWeight.normal)),
                                    ),
                                  ),
                                ],
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
                                      color: theme.colorScheme.onPrimaryContainer
                                          .withValues(alpha: 0.8),
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
                              child: Text('Discard',
                                  style: TextStyle(color: theme.colorScheme.primary)),
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
                                          strokeWidth: 2, color: Colors.white),
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
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateStaffScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SendEmailSheet
//
// A standalone StatefulWidget for the compose-email bottom sheet.
//
// WHY a separate widget (not StatefulBuilder)?
//   StatefulBuilder's builder function runs on every rebuild, which means
//   any local variable declared inside it (like `bool isSending = false`)
//   is reset to its initial value on each rebuild — causing the send button
//   to re-enable mid-flight.
//
//   As a real StatefulWidget, `_isSending` lives in State and survives
//   rebuilds. The cubit is passed as a constructor argument so we never
//   call context.read<>() after an async gap.
// ─────────────────────────────────────────────────────────────────────────────

class _SendEmailSheet extends StatefulWidget {
  final String? to;
  final String? recipientName;
  final StaffCubit cubit;

  const _SendEmailSheet({
    required this.cubit,
    this.to,
    this.recipientName,
  });

  @override
  State<_SendEmailSheet> createState() => _SendEmailSheetState();
}

class _SendEmailSheetState extends State<_SendEmailSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  // Proper widget state — won't reset on rebuild.
  bool _isSending = false;

  bool get _isBulk => widget.to == null;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      if (_isBulk) {
        final result = await widget.cubit.sendBulkEmail(
          subject: _subjectCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
        );
        // Check mounted before using context after await.
        if (mounted) {
          final count = result['recipientCount'] ?? 'all';
          Navigator.pop(context, _EmailSendResult('Email queued for $count staff member(s).'));
        }
      } else {
        await widget.cubit.sendCustomEmail(
          to: widget.to!,
          subject: _subjectCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
        );
        if (mounted) {
          Navigator.pop(
            context,
            _EmailSendResult('Email queued for ${widget.recipientName ?? widget.to}.'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isBulk ? Icons.mark_email_read_rounded : Icons.email_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isBulk
                              ? 'Send Email to All Staff'
                              : 'Send Email to ${widget.recipientName ?? widget.to}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        Text(
                          _isBulk ? 'All staff will receive this email' : widget.to!,
                          style:
                              TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isSending ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Placeholder hint ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: theme.colorScheme.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Use {{name}} and {{email}} — replaced with each recipient's actual details.",
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSecondaryContainer,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Subject ──────────────────────────────────────────────────────
              TextFormField(
                controller: _subjectCtrl,
                enabled: !_isSending,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subject),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Subject is required' : null,
              ),
              const SizedBox(height: 16),

              // ── Body ─────────────────────────────────────────────────────────
              TextFormField(
                controller: _bodyCtrl,
                enabled: !_isSending,
                decoration: const InputDecoration(
                  labelText: 'Message Body',
                  hintText:
                      'Dear {{name}},\n\nYour {{email}} account is now active.\n\nBest regards,\nManagement',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 7,
                minLines: 4,
                textInputAction: TextInputAction.newline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Message body is required' : null,
              ),
              const SizedBox(height: 20),

              // ── Send button ──────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSending ? null : _submit,
                  style:
                      FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isSending
                        ? 'Queuing...'
                        : _isBulk
                            ? 'Send to All Staff'
                            : 'Send Email',
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
