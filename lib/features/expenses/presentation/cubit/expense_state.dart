import 'package:equatable/equatable.dart';
import '../../data/models/expense_model.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {}

class ExpenseLoading extends ExpenseState {}

class ExpenseLoaded extends ExpenseState {
  final List<ExpenseModel> expenses;
  final int total;
  final int limit;
  final int offset;
  final String? category;
  final String? search;

  const ExpenseLoaded({
    required this.expenses,
    required this.total,
    required this.limit,
    required this.offset,
    this.category,
    this.search,
  });

  @override
  List<Object?> get props => [expenses, total, limit, offset, category, search];

  ExpenseLoaded copyWith({
    List<ExpenseModel>? expenses,
    int? total,
    int? limit,
    int? offset,
    String? category,
    String? search,
  }) {
    return ExpenseLoaded(
      expenses: expenses ?? this.expenses,
      total: total ?? this.total,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      category: category ?? this.category,
      search: search ?? this.search,
    );
  }
}

class ExpenseError extends ExpenseState {
  final String message;

  const ExpenseError(this.message);

  @override
  List<Object?> get props => [message];
}

class ExpenseActionSuccess extends ExpenseState {
  final String message;

  const ExpenseActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
