import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/models/session_model.dart';

class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepository({AuthRemoteDataSource? remoteDataSource}) 
      : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource();

  Future<({UserModel user, SessionModel session})> login(String email, String password) {
    return _remoteDataSource.login(email, password);
  }

  Future<UserModel> getMe() {
    return _remoteDataSource.getMe();
  }

  Future<void> resendVerification(String email) {
    return _remoteDataSource.resendVerification(email);
  }

  Future<void> logout() {
    return _remoteDataSource.logout();
  }

  Future<void> logoutAll() {
    return _remoteDataSource.logoutAll();
  }
}
