import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/expense_remote_datasource.dart';
import '../../data/models/expense_model.dart';

class ExpenseRepository {
  final ExpenseRemoteDataSource remoteDataSource;

  ExpenseRepository(this.remoteDataSource);

  Future<(List<ExpenseModel>, int)> getExpenses({int limit = 25, int offset = 0, String? category, String? search}) async {
    try {
      return await remoteDataSource.getExpenses(limit: limit, offset: offset, category: category, search: search);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<ExpenseModel> createExpense({
    required String description,
    required double amount,
    required String category,
    String? notes,
    required DateTime date,
  }) async {
    try {
      return await remoteDataSource.createExpense(
        description: description,
        amount: amount,
        category: category,
        notes: notes,
        date: date,
      );
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<ExpenseModel> updateExpense({
    required String id,
    String? description,
    double? amount,
    String? category,
    String? notes,
    DateTime? date,
  }) async {
    try {
      return await remoteDataSource.updateExpense(
        id: id,
        description: description,
        amount: amount,
        category: category,
        notes: notes,
        date: date,
      );
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      return await remoteDataSource.deleteExpense(id);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
