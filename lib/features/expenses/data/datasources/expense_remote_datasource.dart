import 'package:dio/dio.dart';
import '../models/expense_model.dart';
import '../../../../core/errors/exceptions.dart';

class ExpenseRemoteDataSource {
  final Dio dio;

  ExpenseRemoteDataSource(this.dio);

  Future<(List<ExpenseModel>, int)> getExpenses({int limit = 25, int offset = 0, String? category, String? search}) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      final response = await dio.get('/expenses', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['expenses'];
        final total = response.data['total'] as int;
        final expenses = data.map((e) => ExpenseModel.fromJson(e)).toList();
        return (expenses, total);
      } else {
        throw ApiException(message: response.data['message'] ?? 'Failed to load expenses');
      }
    } on DioException catch (e) {
      throw ApiException(message: e.response?.data['message'] ?? e.message);
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
      final response = await dio.post('/expenses', data: {
        'description': description,
        'amount': amount.toString(),
        'category': category,
        'notes': notes,
        'date': date.toUtc().toIso8601String(),
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ExpenseModel.fromJson(response.data['data']);
      } else {
        throw ApiException(message: response.data['message'] ?? 'Failed to create expense');
      }
    } on DioException catch (e) {
      throw ApiException(message: e.response?.data['message'] ?? e.message);
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
      final data = <String, dynamic>{};
      if (description != null) data['description'] = description;
      if (amount != null) data['amount'] = amount.toString();
      if (category != null) data['category'] = category;
      if (notes != null) data['notes'] = notes;
      if (date != null) data['date'] = date.toUtc().toIso8601String();

      final response = await dio.patch('/expenses/$id', data: data);
      if (response.statusCode == 200) {
        return ExpenseModel.fromJson(response.data['data']);
      } else {
        throw ApiException(message: response.data['message'] ?? 'Failed to update expense');
      }
    } on DioException catch (e) {
      throw ApiException(message: e.response?.data['message'] ?? e.message);
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      final response = await dio.delete('/expenses/$id');
      if (response.statusCode != 200) {
        throw ApiException(message: response.data['message'] ?? 'Failed to delete expense');
      }
    } on DioException catch (e) {
      throw ApiException(message: e.response?.data['message'] ?? e.message);
    }
  }
}
