import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/expense_repository.dart';
import 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseRepository repository;

  ExpenseCubit(this.repository) : super(ExpenseInitial());

  Future<void> fetchExpenses({int? offset, int? limit, String? category, String? search}) async {
    final currentState = state;
    int currentOffset = offset ?? 0;
    int currentLimit = limit ?? 25;
    String? currentCategory = category;
    String? currentSearch = search;
    
    if (currentState is ExpenseLoaded) {
      if (offset == null) currentOffset = currentState.offset;
      if (limit == null) currentLimit = currentState.limit;
      if (category == null) currentCategory = currentState.category;
      if (search == null) currentSearch = currentState.search;
    }

    emit(ExpenseLoading());

    try {
      final (expenses, total) = await repository.getExpenses(limit: currentLimit, offset: currentOffset, category: currentCategory, search: currentSearch);
      emit(ExpenseLoaded(
        expenses: expenses,
        total: total,
        limit: currentLimit,
        offset: currentOffset,
        category: currentCategory,
        search: currentSearch,
      ));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> createExpense({
    required String description,
    required double amount,
    required String category,
    String? notes,
    required DateTime date,
  }) async {
    final currentState = state;
    emit(ExpenseLoading());

    try {
      final expense = await repository.createExpense(
        description: description,
        amount: amount,
        category: category,
        notes: notes,
        date: date,
      );
      emit(const ExpenseActionSuccess("Expense created successfully"));
      if (currentState is ExpenseLoaded) {
        emit(currentState.copyWith(
          expenses: [expense, ...currentState.expenses],
        ));
      } else {
        fetchExpenses();
      }
    } catch (e) {
      emit(ExpenseError(e.toString()));
      if (currentState is ExpenseLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> updateExpense({
    required String id,
    String? description,
    double? amount,
    String? category,
    String? notes,
    DateTime? date,
  }) async {
    final currentState = state;
    if (currentState is ExpenseLoaded) {
      emit(ExpenseLoading());
      try {
        final updatedExpense = await repository.updateExpense(
          id: id,
          description: description,
          amount: amount,
          category: category,
          notes: notes,
          date: date,
        );
        emit(const ExpenseActionSuccess("Expense updated successfully"));
        final updatedList = currentState.expenses.map((e) => e.id == id ? updatedExpense : e).toList();
        emit(currentState.copyWith(expenses: updatedList));
      } catch (e) {
        emit(ExpenseError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> deleteExpense(String id) async {
    final currentState = state;
    if (currentState is ExpenseLoaded) {
      emit(ExpenseLoading());
      try {
        await repository.deleteExpense(id);
        emit(const ExpenseActionSuccess("Expense deleted successfully"));
        final updatedList = currentState.expenses.where((e) => e.id != id).toList();
        emit(currentState.copyWith(expenses: updatedList));
      } catch (e) {
        emit(ExpenseError(e.toString()));
        emit(currentState);
      }
    }
  }
}
