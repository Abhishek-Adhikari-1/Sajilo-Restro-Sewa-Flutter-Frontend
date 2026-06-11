import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/socket_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit({AuthRepository? repository}) 
      : _repository = repository ?? AuthRepository(),
        super(AuthInitial());

  Future<void> checkSession() async {
    emit(SessionCheckLoading());
    try {
      final token = await SecureStorage.getToken(AppConstants.tokenKey);
      if (token == null) {
        emit(const Unauthenticated());
        return;
      }

      final user = await _repository.getMe();
      _handleUserRouting(user);
    } catch (e) {
      await SecureStorage.deleteAll();
      emit(const Unauthenticated(errorMessage: 'Session expired. Please log in again.'));
    }
  }

  Future<void> login(String email, String password) async {
    emit(LoginLoading());
    try {
      final result = await _repository.login(email, password);
      
      await SecureStorage.saveToken(AppConstants.tokenKey, result.session.token);
      
      _handleUserRouting(result.user);
    } on ApiException catch (e) {
      emit(Unauthenticated(errorMessage: e.message));
    } catch (e) {
      emit(Unauthenticated(errorMessage: 'Unexpected error occurred: $e'));
    }
  }

  void _handleUserRouting(UserModel user) {
    if (!user.emailVerified) {
      emit(EmailUnverified(user: user));
      return;
    }

    if (user.status == 'inactive' || 
        user.status == 'suspended' || 
        user.status == 'disabled') {
      emit(AccountRestricted(
        user: user, 
        reason: 'Account is ${user.status}. Please contact support.',
      ));
      return;
    }

    // Connect socket if authenticated and active
    SocketClient().connect();
    
    emit(Authenticated(user));
  }

  Future<void> resendVerification() async {
    final currentState = state;
    if (currentState is EmailUnverified) {
      emit(EmailUnverified(user: currentState.user, isResending: true));
      try {
        await _repository.resendVerification(currentState.user.email);
        emit(EmailUnverified(user: currentState.user, isResending: false));
      } catch (e) {
        emit(EmailUnverified(user: currentState.user, isResending: false));
        // Error handling could be added here, maybe emit a different state or use a side effect
      }
    }
  }

  Future<void> recheckStatus() async {
    final currentState = state;
    if (currentState is AccountRestricted) {
      emit(AccountRestricted(user: currentState.user, reason: currentState.reason, isRechecking: true));
      try {
        final user = await _repository.getMe();
        _handleUserRouting(user);
      } catch (e) {
        emit(AccountRestricted(user: currentState.user, reason: currentState.reason, isRechecking: false));
      }
    }
  }

  Future<void> recheckEmailVerification() async {
    final currentState = state;
    if (currentState is EmailUnverified) {
      emit(EmailUnverified(user: currentState.user, isResending: true)); // Reuse loading state
      try {
        final user = await _repository.getMe();
        _handleUserRouting(user);
      } catch (e) {
        emit(EmailUnverified(user: currentState.user, isResending: false));
      }
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {}
    
    _clearSession();
  }

  Future<void> logoutAll() async {
    try {
      await _repository.logoutAll();
    } catch (_) {}
    
    _clearSession();
  }

  void _clearSession() async {
    SocketClient().disconnect();
    await SecureStorage.deleteAll();
    emit(const Unauthenticated(errorMessage: 'Logged out successfully'));
  }
}
