import '../../../../core/network/api_client.dart';
import '../models/table_model.dart';

abstract class TableRemoteDataSource {
  Future<List<TableModel>> getAllTables({String? status, int limit = 20, int offset = 0});
}

class TableRemoteDataSourceImpl implements TableRemoteDataSource {
  final ApiClient apiClient;

  TableRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<TableModel>> getAllTables({String? status, int limit = 20, int offset = 0}) async {
    try {
      final queryParams = <String>[];
      if (status != null && status.toLowerCase() != 'all') {
        queryParams.add('status=$status');
      }
      queryParams.add('limit=$limit');
      queryParams.add('offset=$offset');
      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final response = await apiClient.get('/tables$queryString');
      final List<dynamic> data = response['tables'];
      return data.map((e) => TableModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error fetching tables: $e');
    }
  }
}
