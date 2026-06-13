import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/socket_client.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repository;
  final SocketClient _socketClient;
  String? _currentRole;
  String _currentPeriod = 'today';

  DashboardCubit(this._repository, this._socketClient) : super(DashboardInitial()) {
    _socketClient.socket?.on('order_created', (_) => _refreshDashboard());
    _socketClient.socket?.on('order_updated', (_) => _refreshDashboard());
    _socketClient.socket?.on('order_completed', (_) => _refreshDashboard());
    _socketClient.socket?.on('order_items_added', (_) => _refreshDashboard());
    _socketClient.socket?.on('order_item_updated', (_) => _refreshDashboard());
    _socketClient.socket?.on('table_updated', (_) => _refreshDashboard());
  }

  void _refreshDashboard() {
    if (_currentRole != null) {
      fetchDashboard(_currentRole!, period: _currentPeriod);
    }
  }

  Future<void> fetchDashboard(String role, {String? period}) async {
    _currentRole = role;
    if (period != null) {
      _currentPeriod = period;
    }
    
    if (state is! DashboardLoaded) {
      emit(DashboardLoading());
    }
    try {
      Map<String, dynamic> data;
      switch (role.toLowerCase()) {
        case 'admin':
          data = await _repository.getAdminDashboard(period: _currentPeriod);
          break;
        case 'waiter':
          data = await _repository.getWaiterDashboard();
          break;
        case 'kitchen':
          data = await _repository.getKitchenDashboard();
          break;
        case 'cashier':
          data = await _repository.getCashierDashboard();
          break;
        default:
          emit(const DashboardError("Invalid role specified for dashboard."));
          return;
      }
      emit(DashboardLoaded(data));
    } on Failure catch (e) {
      emit(DashboardError(e.message));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
