import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';

class DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;

  DashboardRepository(this._remoteDataSource);

  Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      return await _remoteDataSource.fetchAdminDashboard();
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<Map<String, dynamic>> getWaiterDashboard() async {
    try {
      return await _remoteDataSource.fetchWaiterDashboard();
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<Map<String, dynamic>> getKitchenDashboard() async {
    try {
      return await _remoteDataSource.fetchKitchenDashboard();
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<Map<String, dynamic>> getCashierDashboard() async {
    try {
      return await _remoteDataSource.fetchCashierDashboard();
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
