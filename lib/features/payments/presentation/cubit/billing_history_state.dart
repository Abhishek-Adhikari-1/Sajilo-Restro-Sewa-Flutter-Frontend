import '../../data/models/billing_history_model.dart';

abstract class BillingHistoryState {}

class BillingHistoryInitial extends BillingHistoryState {}

class BillingHistoryLoading extends BillingHistoryState {}

class BillingHistoryLoaded extends BillingHistoryState {
  final List<BillingHistoryItemModel> items;
  final int total;
  final bool hasReachedMax;
  final DateTime? startDate;
  final DateTime? endDate;
  final int currentOffset;

  BillingHistoryLoaded({
    required this.items,
    required this.total,
    required this.hasReachedMax,
    this.startDate,
    this.endDate,
    this.currentOffset = 0,
  });

  BillingHistoryLoaded copyWith({
    List<BillingHistoryItemModel>? items,
    int? total,
    bool? hasReachedMax,
    DateTime? startDate,
    DateTime? endDate,
    int? currentOffset,
  }) {
    return BillingHistoryLoaded(
      items: items ?? this.items,
      total: total ?? this.total,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currentOffset: currentOffset ?? this.currentOffset,
    );
  }
}

class BillingHistoryError extends BillingHistoryState {
  final String message;

  BillingHistoryError({required this.message});
}
