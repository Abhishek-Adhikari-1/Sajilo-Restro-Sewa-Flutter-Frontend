import '../../data/models/table_model.dart';
import '../../data/datasources/table_remote_datasource.dart';

class TableRepository {
  final TableRemoteDataSource remoteDataSource;

  TableRepository({required this.remoteDataSource});

  Future<(List<TableModel>, int)> getAllTables({String? status, int limit = 20, int offset = 0, String? search}) async {
    return await remoteDataSource.getAllTables(status: status, limit: limit, offset: offset, search: search);
  }

  Future<TableModel> createTable(Map<String, dynamic> data) async {
    return await remoteDataSource.createTable(data);
  }

  Future<TableModel> updateTable(String id, Map<String, dynamic> data) async {
    return await remoteDataSource.updateTable(id, data);
  }

  Future<TableModel> updateTableStatus(String id, String status) async {
    return await remoteDataSource.updateTableStatus(id, status);
  }

  Future<void> deleteTable(String id) async {
    return await remoteDataSource.deleteTable(id);
  }
}
