import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/table_model.dart';

abstract class TableRemoteDataSource {
  Future<(List<TableModel>, int)> getAllTables({String? status, int limit = 20, int offset = 0, String? search});
  Future<TableModel> createTable(Map<String, dynamic> data);
  Future<TableModel> updateTable(String id, Map<String, dynamic> data);
  Future<TableModel> updateTableStatus(String id, String status);
  Future<void> deleteTable(String id);
}

class TableRemoteDataSourceImpl implements TableRemoteDataSource {
  final ApiClient apiClient;

  TableRemoteDataSourceImpl(this.apiClient);

  @override
  Future<(List<TableModel>, int)> getAllTables({String? status, int limit = 20, int offset = 0, String? search}) async {
    try {
      final queryParams = <String>[];
      if (status != null && status.toLowerCase() != 'all') {
        queryParams.add('status=$status');
      }
      queryParams.add('limit=$limit');
      queryParams.add('offset=$offset');
      if (search != null && search.isNotEmpty) {
        queryParams.add('search=$search');
      }
      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final response = await apiClient.get('/tables$queryString');
      
      final List<dynamic> data = response['tables'] ?? [];
      final int total = response['total'] ?? 0;
      
      return (data.map((e) => TableModel.fromJson(e)).toList(), total);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Error fetching tables: $e');
    }
  }

  @override
  Future<TableModel> createTable(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.post('/tables', body: data);
      return TableModel.fromJson(response['table']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Error creating table: $e');
    }
  }

  @override
  Future<TableModel> updateTable(String id, Map<String, dynamic> data) async {
    try {
      final response = await apiClient.put('/tables/$id', body: data);
      return TableModel.fromJson(response['table']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Error updating table: $e');
    }
  }

  @override
  Future<TableModel> updateTableStatus(String id, String status) async {
    try {
      final response = await apiClient.patch('/tables/$id/status', body: {'status': status});
      return TableModel.fromJson(response['table']);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Error updating table status: $e');
    }
  }

  @override
  Future<void> deleteTable(String id) async {
    try {
      await apiClient.delete('/tables/$id');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Error deleting table: $e');
    }
  }
}
