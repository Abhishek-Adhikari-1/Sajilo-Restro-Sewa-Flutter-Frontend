import '../models/payment_model.dart';
import '../models/billing_history_model.dart';
import '../models/side_panel_models.dart';
import '../datasources/payment_remote_datasource.dart';

class PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepository(this.remoteDataSource);

  Future<void> checkout(PaymentRequestModel request) async {
    await remoteDataSource.checkout(request);
  }

  Future<BillingHistoryResponse> getBillingHistory({
    String? startDate,
    String? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    return await remoteDataSource.getBillingHistory(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }

  Future<SidePanelOrderModel> getOrderDetails(String orderId) async {
    return await remoteDataSource.getOrderDetails(orderId);
  }

  Future<SidePanelCustomerModel> getCustomerDetails(String customerId) async {
    return await remoteDataSource.getCustomerDetails(customerId);
  }
}
 
