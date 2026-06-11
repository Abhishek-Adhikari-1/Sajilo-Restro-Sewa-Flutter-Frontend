import '../../data/models/side_panel_models.dart';

abstract class SidePanelState {}

class SidePanelHidden extends SidePanelState {}

class SidePanelLoading extends SidePanelState {}

class SidePanelOrderLoaded extends SidePanelState {
  final SidePanelOrderModel order;
  SidePanelOrderLoaded(this.order);
}

class SidePanelCustomerLoaded extends SidePanelState {
  final SidePanelCustomerModel customer;
  SidePanelCustomerLoaded(this.customer);
}

class SidePanelError extends SidePanelState {
  final String message;
  SidePanelError(this.message);
}
