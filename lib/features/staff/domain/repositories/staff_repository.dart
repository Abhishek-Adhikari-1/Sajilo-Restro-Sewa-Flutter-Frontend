import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/staff_remote_datasource.dart';
import '../../../auth/data/models/user_model.dart';

class StaffRepository {
  final StaffRemoteDataSource _remoteDataSource;

  StaffRepository(this._remoteDataSource);

  Future<List<UserModel>> getStaff() async {
    try {
      return await _remoteDataSource.getStaff();
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<Map<String, dynamic>> createStaff(Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.createStaff(data);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<UserModel> updateStaff(String id, Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.updateStaff(id, data);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> sendCustomEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    try {
      await _remoteDataSource.sendCustomEmail(to: to, subject: subject, body: body);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<Map<String, dynamic>> sendBulkEmail({
    required String subject,
    required String body,
  }) async {
    try {
      return await _remoteDataSource.sendBulkEmail(subject: subject, body: body);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
