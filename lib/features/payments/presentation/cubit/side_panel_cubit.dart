import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/payment_repository.dart';
import 'side_panel_state.dart';

class SidePanelCubit extends Cubit<SidePanelState> {
  final PaymentRepository _repository;

  SidePanelCubit(this._repository) : super(SidePanelHidden());

  void hidePanel() {
    emit(SidePanelHidden());
  }

  Future<void> fetchOrderDetails(String orderId) async {
    emit(SidePanelLoading());
    try {
      final order = await _repository.getOrderDetails(orderId);
      emit(SidePanelOrderLoaded(order));
    } catch (e) {
      emit(SidePanelError(e.toString()));
    }
  }

  Future<void> fetchCustomerDetails(String customerId) async {
    emit(SidePanelLoading());
    try {
      final customer = await _repository.getCustomerDetails(customerId);
      emit(SidePanelCustomerLoaded(customer));
    } catch (e) {
      emit(SidePanelError(e.toString()));
    }
  }
}
