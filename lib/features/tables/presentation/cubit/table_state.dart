import 'package:equatable/equatable.dart';
import '../../data/models/table_model.dart';

abstract class TableState extends Equatable {
  const TableState();

  @override
  List<Object?> get props => [];
}

class TableInitial extends TableState {}

class TableLoading extends TableState {}

class TableLoaded extends TableState {
  final List<TableModel> tables;
  final String? currentSearch;
  final String? currentStatus;
  final int total;
  final int offset;
  final int limit;
  final Map<String, String> editedTables; // Map table ID to status string
  final bool isSaving;
  final String? errorMessage;

  const TableLoaded({
    required this.tables,
    this.currentSearch,
    this.currentStatus,
    this.total = 0,
    this.offset = 0,
    this.limit = 25,
    this.editedTables = const {},
    this.isSaving = false,
    this.errorMessage,
  });

  TableLoaded copyWith({
    List<TableModel>? tables,
    String? currentSearch,
    String? currentStatus,
    int? total,
    int? offset,
    int? limit,
    Map<String, String>? editedTables,
    bool? isSaving,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return TableLoaded(
      tables: tables ?? this.tables,
      currentSearch: currentSearch ?? this.currentSearch,
      currentStatus: currentStatus ?? this.currentStatus,
      total: total ?? this.total,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      editedTables: editedTables ?? this.editedTables,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        tables,
        currentSearch,
        currentStatus,
        total,
        offset,
        limit,
        editedTables,
        isSaving,
        errorMessage,
      ];
}

class TableError extends TableState {
  final String message;

  const TableError({required this.message});

  @override
  List<Object?> get props => [message];
}
