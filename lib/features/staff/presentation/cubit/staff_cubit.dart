import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/staff_repository.dart';
import 'staff_state.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/data/models/user_model.dart';

class StaffCubit extends Cubit<StaffState> {
  final StaffRepository _repository;

  StaffCubit(this._repository) : super(StaffInitial());

  Future<void> fetchStaff() async {
    emit(StaffLoading());
    try {
      final staff = await _repository.getStaff();
      emit(StaffLoaded(
        staff: staff,
        editedStaff: const {},
      ));
    } on ServerFailure catch (e) {
      emit(StaffError(e.message));
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  void updateStaffFieldLocal(String userId, {String? role, String? status}) {
    final currentState = state;
    if (currentState is! StaffLoaded) return;

    final updatedEdits = Map<String, Map<String, dynamic>>.from(currentState.editedStaff);
    final userEdits = Map<String, dynamic>.from(updatedEdits[userId] ?? {});

    if (role != null) {
      userEdits['role'] = role;
    }
    if (status != null) {
      userEdits['status'] = status;
    }

    // Check if the edits actually match original values. If so, remove them to avoid redundant saves.
    final originalUser = currentState.staff.firstWhere((u) => u.id == userId);
    bool matchesOriginal = true;
    if (userEdits.containsKey('role') && userEdits['role'] != originalUser.role) {
      matchesOriginal = false;
    }
    if (userEdits.containsKey('status') && userEdits['status'] != originalUser.status) {
      matchesOriginal = false;
    }

    if (matchesOriginal) {
      updatedEdits.remove(userId);
    } else {
      updatedEdits[userId] = userEdits;
    }

    emit(currentState.copyWith(
      editedStaff: updatedEdits,
    ));
  }

  void discardChanges() {
    final currentState = state;
    if (currentState is! StaffLoaded) return;

    emit(currentState.copyWith(
      editedStaff: const {},
    ));
  }

  Future<void> saveChanges() async {
    final currentState = state;
    if (currentState is! StaffLoaded) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      final edits = currentState.editedStaff;
      for (final userId in edits.keys) {
        final patchData = edits[userId]!;
        await _repository.updateStaff(userId, patchData);
      }

      // Re-fetch staff from server to ensure accurate state
      final updatedStaff = await _repository.getStaff();
      emit(StaffLoaded(
        staff: updatedStaff,
        editedStaff: const {},
        isSaving: false,
      ));
    } on ServerFailure catch (e) {
      emit(currentState.copyWith(
        isSaving: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> createStaff(Map<String, dynamic> data) async {
    final currentState = state;
    if (currentState is! StaffLoaded) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      final result = await _repository.createStaff(data);
      final newUser = result['user'];

      final updatedStaffList = await _repository.getStaff();

      emit(currentState.copyWith(
        staff: updatedStaffList,
        isSaving: false,
        recentlyCreatedStaff: newUser,
      ));
    } on ServerFailure catch (e) {
      emit(currentState.copyWith(
        isSaving: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void clearRecentlyCreatedStaff() {
    final currentState = state;
    if (currentState is! StaffLoaded) return;
    emit(currentState.copyWith(clearRecentlyCreated: true));
  }

  void clearErrorMessage() {
    final currentState = state;
    if (currentState is! StaffLoaded) return;
    emit(currentState.copyWith(errorMessage: null));
  }
}
