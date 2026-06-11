import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class SessionCheckLoading extends AuthState {}

class LoginLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserModel user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  final String? errorMessage;

  const Unauthenticated({this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

class AccountRestricted extends AuthState {
  final UserModel user;
  final String reason;
  final bool isRechecking;

  const AccountRestricted({
    required this.user,
    required this.reason,
    this.isRechecking = false,
  });

  @override
  List<Object?> get props => [user, reason, isRechecking];
}

class EmailUnverified extends AuthState {
  final UserModel user;
  final bool isResending;

  const EmailUnverified({
    required this.user,
    this.isResending = false,
  });

  @override
  List<Object?> get props => [user, isResending];
}
