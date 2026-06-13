import 'package:equatable/equatable.dart';
import '../../../auth/data/models/user_model.dart';

abstract class StaffState extends Equatable {
  const StaffState();

  @override
  List<Object?> get props => [];
}

class StaffInitial extends StaffState {}

class StaffLoading extends StaffState {}

class StaffLoaded extends StaffState {
  final List<UserModel> staff;
  final Map<String, Map<String, dynamic>> editedStaff; // userId -> { 'role': ..., 'status': ... }
  final bool isSaving;
  final String? errorMessage;
  final String? newStaffPassword; // Temp password for recently created staff
  final UserModel? recentlyCreatedStaff;

  const StaffLoaded({
    required this.staff,
    required this.editedStaff,
    this.isSaving = false,
    this.errorMessage,
    this.newStaffPassword,
    this.recentlyCreatedStaff,
  });

  StaffLoaded copyWith({
    List<UserModel>? staff,
    Map<String, Map<String, dynamic>>? editedStaff,
    bool? isSaving,
    String? errorMessage,
    String? newStaffPassword,
    UserModel? recentlyCreatedStaff,
    bool clearPassword = false,
  }) {
    return StaffLoaded(
      staff: staff ?? this.staff,
      editedStaff: editedStaff ?? this.editedStaff,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
      newStaffPassword: clearPassword ? null : (newStaffPassword ?? this.newStaffPassword),
      recentlyCreatedStaff: clearPassword ? null : (recentlyCreatedStaff ?? this.recentlyCreatedStaff),
    );
  }

  @override
  List<Object?> get props => [
        staff,
        editedStaff,
        isSaving,
        errorMessage,
        newStaffPassword,
        recentlyCreatedStaff,
      ];
}

class StaffError extends StaffState {
  final String message;

  const StaffError(this.message);

  @override
  List<Object?> get props => [message];
}
