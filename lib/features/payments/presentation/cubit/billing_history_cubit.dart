import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/billing_history_model.dart';
import '../../data/repositories/payment_repository.dart';
import 'billing_history_state.dart';

class BillingHistoryCubit extends Cubit<BillingHistoryState> {
  final PaymentRepository _repository;
  int _currentLimit = 10;
  
  int get limit => _currentLimit;

  BillingHistoryCubit(this._repository) : super(BillingHistoryInitial());

  Future<void> fetchHistory({
    DateTime? startDate,
    DateTime? endDate,
    bool isRefresh = false,
    int? limit,
    int? newOffset,
  }) async {
    try {
      if (limit != null) {
        _currentLimit = limit;
      }
      if (state is BillingHistoryLoading) return;

      int currentOffset = newOffset ?? 0;
      
      final currentState = state;
      if (!isRefresh && currentState is BillingHistoryLoaded && newOffset == null) {
        currentOffset = currentState.currentOffset;
        startDate ??= currentState.startDate;
        endDate ??= currentState.endDate;
      } else if (isRefresh && currentState is BillingHistoryLoaded) {
        startDate ??= currentState.startDate;
        endDate ??= currentState.endDate;
      }

      emit(BillingHistoryLoading());

      final startStr = startDate?.toUtc().toIso8601String();
      final endStr = endDate?.toUtc().toIso8601String();

      final response = await _repository.getBillingHistory(
        startDate: startStr,
        endDate: endStr,
        limit: _currentLimit,
        offset: currentOffset,
      );

      final List<BillingHistoryItemModel> newItems = response.items;
      
      emit(BillingHistoryLoaded(
        items: newItems,
        total: response.total,
        hasReachedMax: currentOffset + newItems.length >= response.total,
        startDate: startDate,
        endDate: endDate,
        currentOffset: currentOffset,
      ));
    } catch (e) {
      emit(BillingHistoryError(message: e.toString()));
    }
  }

  void resetFilter() {
    fetchHistory(startDate: null, endDate: null, isRefresh: true);
  }
}
