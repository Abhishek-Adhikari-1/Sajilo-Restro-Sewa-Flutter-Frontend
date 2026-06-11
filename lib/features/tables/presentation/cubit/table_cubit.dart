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

  Future<void> fetchTables({bool showLoading = false}) async {
    String currentFilter = 'all';
    bool wasLoaded = state is TableLoaded;
    if (wasLoaded) {
      currentFilter = (state as TableLoaded).filter;
      if (showLoading) {
        emit(TableLoading());
      }
    } else if (state is! TableLoading) {
      emit(TableLoading());
    }

    try {
      final tables = await repository.getAllTables(
        status: currentFilter,
        limit: 100,
        offset: 0,
      );
      emit(
        TableLoaded(
          tables,
          filter: currentFilter,
          hasReachedMax: tables.length < 100,
        ),
      );
    } catch (e) {
      emit(TableError(e.toString()));
    }
  }

  Future<void> fetchMoreTables() async {
    if (state is TableLoaded) {
      final currentState = state as TableLoaded;
      if (currentState.hasReachedMax || currentState.isFetchingMore) return;

      emit(currentState.copyWith(isFetchingMore: true));

      try {
        final tables = await repository.getAllTables(
          status: currentState.filter,
          limit: 100,
          offset: currentState.tables.length,
        );

        emit(
          currentState.copyWith(
            tables: List.of(currentState.tables)..addAll(tables),
            hasReachedMax: tables.length < 100,
            isFetchingMore: false,
          ),
        );
      } catch (e) {
        emit(currentState.copyWith(isFetchingMore: false));
        // Just fail silently or log in a real app, keeping existing state
      }
    }
  }

  void updateFilter(String filter) {
    if (state is TableLoaded) {
      final currentState = state as TableLoaded;
      emit(currentState.copyWith(filter: filter));
      fetchTables(showLoading: true);
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
}
