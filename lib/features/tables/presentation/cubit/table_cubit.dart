import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/table_repository.dart';
import 'table_state.dart';
import '../../../../core/network/socket_client.dart';
import '../../data/models/table_model.dart';

class TableCubit extends Cubit<TableState> {
  final TableRepository repository;
  final SocketClient socketClient;

  TableCubit({required this.repository, required this.socketClient})
    : super(TableInitial());

  void initSocket() {
    socketClient.socket?.on('table_updated', (data) {
      try {
        if (data == null || data['table'] == null) return;
        final updatedTable = TableModel.fromJson(data['table']);

        if (state is TableLoaded) {
          final currentState = state as TableLoaded;
          final updatedTables = currentState.tables.map((t) {
            return t.id == updatedTable.id ? updatedTable : t;
          }).toList();

          emit(currentState.copyWith(tables: updatedTables));
        }
      } catch (e) {
        // Silently ignore parsing errors
      }
    });
  }

  Future<void> fetchTables({String? search, String? status, int limit = 25}) async {
    final currentState = state;
    if (currentState is! TableLoaded) {
      emit(TableLoading());
    } else {
      if (search != currentState.currentSearch || status != currentState.currentStatus) {
        // We will fetch new tables
      }
    }
    
    try {
      final (fetchedTables, total) = await repository.getAllTables(
        limit: limit, 
        offset: 0,
        search: search,
        status: status,
      );
      
      emit(TableLoaded(
        tables: fetchedTables,
        currentSearch: search,
        currentStatus: status,
        total: total,
        offset: 0,
        limit: limit,
        editedTables: currentState is TableLoaded ? currentState.editedTables : const {},
      ));
    } catch (e) {
      emit(TableError(message: e.toString()));
    }
  }

  Future<void> fetchMoreTables(int limit) async {
    if (state is! TableLoaded) return;
    final currentState = state as TableLoaded;
    
    final newOffset = currentState.tables.length;
    if (newOffset >= currentState.total) return;

    try {
      final (tables, total) = await repository.getAllTables(
        offset: newOffset,
        limit: limit,
        search: currentState.currentSearch,
        status: currentState.currentStatus,
      );
      
      emit(currentState.copyWith(
        tables: List.of(currentState.tables)..addAll(tables),
        total: total,
      ));
    } catch (e) {
      emit(currentState.copyWith(errorMessage: 'Failed to fetch more tables'));
    }
  }

  void changePage(int page, int limit) {
    if (state is! TableLoaded) return;
    final currentState = state as TableLoaded;
    final newOffset = (page - 1) * limit;
    
    repository.getAllTables(
      offset: newOffset,
      limit: limit,
      search: currentState.currentSearch,
      status: currentState.currentStatus,
    ).then((result) {
      final (tables, total) = result;
      if (isClosed) return;
      emit(currentState.copyWith(
        tables: tables,
        offset: newOffset,
        limit: limit,
        total: total,
      ));
    }).catchError((e) {
      if (isClosed) return;
      emit(currentState.copyWith(errorMessage: 'Failed to fetch page'));
    });
  }

  void toggleTableStatus(String id, String originalStatus) {
    if (state is! TableLoaded) return;
    final currentState = state as TableLoaded;
    
    // Toggle between available and unavailable for quick actions
    final newStatus = originalStatus == 'available' ? 'unavailable' : 'available';
    
    final Map<String, String> newEditedTables = Map.from(currentState.editedTables);
    
    // If it's already edited, check if the toggle reverts it to the original database state
    final tableInDb = currentState.tables.firstWhere((t) => t.id == id);
    if (tableInDb.status == newStatus) {
      newEditedTables.remove(id); // Reverted back to original
    } else {
      newEditedTables[id] = newStatus;
    }
    
    emit(currentState.copyWith(editedTables: newEditedTables));
  }

  void discardChanges() {
    if (state is! TableLoaded) return;
    final currentState = state as TableLoaded;
    emit(currentState.copyWith(editedTables: const {}));
  }

  Future<void> saveChanges() async {
    if (state is! TableLoaded) return;
    final currentState = state as TableLoaded;
    
    if (currentState.editedTables.isEmpty) return;
    
    emit(currentState.copyWith(isSaving: true));
    
    try {
      for (final entry in currentState.editedTables.entries) {
        await repository.updateTableStatus(entry.key, entry.value);
      }
      
      // Re-fetch tables to get latest state
      final (tables, total) = await repository.getAllTables(
        offset: currentState.offset,
        limit: currentState.limit,
        search: currentState.currentSearch,
        status: currentState.currentStatus,
      );
      
      emit(currentState.copyWith(
        tables: tables,
        total: total,
        editedTables: const {},
        isSaving: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save changes: ${e.toString()}',
      ));
    }
  }

  void clearError() {
    if (state is TableLoaded) {
      emit((state as TableLoaded).copyWith(clearErrorMessage: true));
    }
  }

  void updateTableDetailsOptimistic(String id, Map<String, dynamic> updates) {
    if (state is TableLoaded) {
      final currentState = state as TableLoaded;
      final updatedTables = currentState.tables.map((t) {
        if (t.id == id) {
          return t.copyWith(
            status: updates['status'] as String?,
            occupiedSeats: updates['occupied_seats'] as int?,
          );
        }
        return t;
      }).toList();
      emit(currentState.copyWith(tables: updatedTables));
    }
  }

  Future<void> updateSingleTableStatus(String id, String newStatus) async {
    try {
      await repository.updateTableStatus(id, newStatus);
      updateTableDetailsOptimistic(id, {'status': newStatus});
    } catch (e) {
      if (state is TableLoaded) {
        emit((state as TableLoaded).copyWith(errorMessage: 'Failed to update table status: $e'));
      }
    }
  }
}
