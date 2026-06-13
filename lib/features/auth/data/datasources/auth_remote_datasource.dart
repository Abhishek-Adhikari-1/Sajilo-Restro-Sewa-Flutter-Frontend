import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../models/active_session_model.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<({UserModel user, SessionModel session})> login(String email, String password) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {'email': email, 'password': password},
      requiresAuth: false,
    );
    
    return (
      user: UserModel.fromJson(response['user']),
      session: SessionModel.fromJson(response['session']),
    );
  }

  Future<UserModel> getMe() async {
    final response = await _apiClient.get('/auth/me');
    return UserModel.fromJson(response['user']);
  }

  Future<void> resendVerification(String email) async {
    await _apiClient.post(
      '/auth/resend-verification',
      body: {'email': email},
    );
  }

  Future<void> logout() async {
    await _apiClient.post('/auth/logout');
  }

  Future<void> logoutAll() async {
    await _apiClient.post('/auth/logout-all');
  }

  Future<List<ActiveSessionModel>> getSessions() async {
    final response = await _apiClient.get('/auth/sessions');
    final List<dynamic> sessions = response['sessions'] ?? [];
    return sessions.map((s) => ActiveSessionModel.fromJson(s)).toList();
  }
}
