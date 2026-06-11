import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/exceptions.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/payment_repository.dart';
import 'payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository repository;

  PaymentCubit(this.repository) : super(PaymentInitial());

  Future<void> checkout(PaymentRequestModel request) async {
    emit(PaymentLoading());
    try {
      await repository.checkout(request);
      emit(PaymentSuccess());
    } on ApiException catch (e) {
      emit(PaymentError(e.message));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }
}
