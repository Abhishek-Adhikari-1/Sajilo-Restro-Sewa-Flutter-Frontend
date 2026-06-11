import '../../data/models/table_model.dart';
import '../../data/datasources/table_remote_datasource.dart';

class TableRepository {
  final TableRemoteDataSource remoteDataSource;

  TableRepository({required this.remoteDataSource});

  Future<List<TableModel>> getAllTables({String? status, int limit = 20, int offset = 0}) async {
    return await remoteDataSource.getAllTables(status: status, limit: limit, offset: offset);
  }
}
