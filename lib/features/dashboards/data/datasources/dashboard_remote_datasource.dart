import 'package:dio/dio.dart';
import 'package:sajilo_restro_sewa/core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';

class DashboardRemoteDataSource {
  final Dio dio;

  DashboardRemoteDataSource(this.dio);

  Future<Map<String, dynamic>> fetchAdminDashboard({String period = 'today'}) async {
    try {
      final response = await dio.get('${ApiEndpoints.dashboardAdmin}?period=$period');
      final data = response.data is Map<String, dynamic> && response.data.containsKey('data') 
          ? response.data['data'] 
          : response.data;
      return data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data as Map<String, dynamic>);
      }
      throw ApiException(message: e.message ?? "Unknown network error");
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchWaiterDashboard() async {
    try {
      final response = await dio.get(ApiEndpoints.dashboardWaiter);
      final data = response.data is Map<String, dynamic> && response.data.containsKey('data') 
          ? response.data['data'] 
          : response.data;
      return data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data as Map<String, dynamic>);
      }
      throw ApiException(message: e.message ?? "Unknown network error");
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchKitchenDashboard() async {
    try {
      final response = await dio.get(ApiEndpoints.dashboardKitchen);
      final data = response.data is Map<String, dynamic> && response.data.containsKey('data') 
          ? response.data['data'] 
          : response.data;
      return data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data as Map<String, dynamic>);
      }
      throw ApiException(message: e.message ?? "Unknown network error");
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchCashierDashboard() async {
    try {
      final response = await dio.get(ApiEndpoints.dashboardCashier);
      final data = response.data is Map<String, dynamic> && response.data.containsKey('data') 
          ? response.data['data'] 
          : response.data;
      return data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data as Map<String, dynamic>);
      }
      throw ApiException(message: e.message ?? "Unknown network error");
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
