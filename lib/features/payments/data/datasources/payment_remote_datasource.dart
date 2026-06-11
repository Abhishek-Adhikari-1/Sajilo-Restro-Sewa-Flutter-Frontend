import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/payment_model.dart';
import '../models/billing_history_model.dart';
import '../models/side_panel_models.dart';

class PaymentRemoteDataSource {
  final Dio dio;

  PaymentRemoteDataSource(this.dio);

  Future<void> checkout(PaymentRequestModel request) async {
    try {
      await dio.post('/payments/checkout', data: request.toJson());
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data as Map<String, dynamic>);
      }
      throw ApiException(message: e.message ?? "Unknown network error");
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<BillingHistoryResponse> getBillingHistory({
    String? startDate,
    String? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get('/payments/history', queryParameters: {
        'startDate': startDate,
        'endDate': endDate,
        'limit': limit,
        'offset': offset,
      });
      return BillingHistoryResponse.fromJson(response.data);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<SidePanelOrderModel> getOrderDetails(String orderId) async {
    try {
      final response = await dio.get('/orders/$orderId');
      return SidePanelOrderModel.fromJson(response.data['data']);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<SidePanelCustomerModel> getCustomerDetails(String customerId) async {
    try {
      final response = await dio.get('/customers/$customerId');
      return SidePanelCustomerModel.fromJson(response.data['data']);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
 
