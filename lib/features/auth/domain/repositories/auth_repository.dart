import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/models/session_model.dart';
import '../../data/models/active_session_model.dart';
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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  Future<void> verifyEmail(String token, String email) {
    return _remoteDataSource.verifyEmail(token, email);
  }

  Future<void> logoutAll() {
    return _remoteDataSource.logoutAll();
  }

  Future<List<ActiveSessionModel>> getSessions() {
    return _remoteDataSource.getSessions();
  }
}
