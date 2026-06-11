import 'package:equatable/equatable.dart';
import '../../data/models/table_model.dart';

abstract class TableState extends Equatable {
  const TableState();

  @override
  List<Object> get props => [];
}

class TableInitial extends TableState {}

class TableLoading extends TableState {}

class TableLoaded extends TableState {
  final List<TableModel> tables;
  final String filter; // "all", "available", "reserved", "occupied", "unavailable"
  final bool hasReachedMax;
  final bool isFetchingMore;

  const TableLoaded(
    this.tables, {
    this.filter = 'all',
    this.hasReachedMax = false,
    this.isFetchingMore = false,
  });

  List<TableModel> get filteredTables {
    if (filter == 'all') return tables;
    return tables.where((t) => t.status == filter).toList();
  }

  TableLoaded copyWith({
    List<TableModel>? tables,
    String? filter,
    bool? hasReachedMax,
    bool? isFetchingMore,
  }) {
    return TableLoaded(
      tables ?? this.tables,
      filter: filter ?? this.filter,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }

  @override
  List<Object> get props => [tables, filter, hasReachedMax, isFetchingMore];
}

class TableError extends TableState {
  final String message;

  const TableError(this.message);

  @override
  List<Object> get props => [message];
}
