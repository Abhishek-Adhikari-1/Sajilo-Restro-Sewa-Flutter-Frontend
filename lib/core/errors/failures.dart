import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  final String? code;
  final List<dynamic>? errors;

  const ServerFailure(super.message, {this.code, this.errors});

  @override
  List<Object?> get props => [message, code, errors];
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
