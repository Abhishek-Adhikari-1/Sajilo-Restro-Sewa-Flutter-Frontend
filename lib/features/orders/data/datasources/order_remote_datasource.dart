import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/order_model.dart';

class OrderRemoteDataSource {
  final Dio _dio;

  OrderRemoteDataSource(this._dio);

  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.orders,
        data: order.toJson(),
      );
      final data = response.data is Map<String, dynamic> && response.data.containsKey('data') 
          ? response.data['data'] 
          : response.data;
      return OrderModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to create order.");
    }
  }

  Future<List<OrderModel>> getActiveOrders() async {
    try {
      final response = await _dio.get(ApiEndpoints.activeOrders);
      final data = response.data is Map<String, dynamic> && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
          
      if (data is List) {
        return data.map((e) => OrderModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to load active orders.");
    }
  }

  Future<OrderModel> updateOrderStatus(String id, String status) async {
    try {
      final response = await _dio.patch(
        '${ApiEndpoints.orders}/$id/status',
        data: {'status': status},
      );
      final data = response.data is Map<String, dynamic> && response.data.containsKey('data') 
          ? response.data['data'] 
          : response.data;
      return OrderModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to update order status.");
    }
  }

  Future<OrderModel> addItemsToOrder(String id, List<OrderItemModel> items) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.orders}/$id/items',
        data: items.map((e) => e.toJson()).toList(),
      );
      final data = response.data is Map<String, dynamic> && response.data.containsKey('data') 
          ? response.data['data'] 
          : response.data;
      return OrderModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to add items to order.");
    }
  }

  Future<OrderModel> updateOrderItems(String id, List<OrderItemModel> items, String? notes) async {
    try {
      final response = await _dio.put(
        '${ApiEndpoints.orders}/$id/items',
        data: {
          'items': items.map((e) => e.toJson()).toList(),
          'notes': notes,
        },
      );
      final data = response.data is Map<String, dynamic> && response.data.containsKey('data') 
          ? response.data['data'] 
          : response.data;
      return OrderModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to update order items.");
    }
  }

  Future<OrderModel> updateOrderItemStatus(String id, String itemId, String status) async {
    try {
      final response = await _dio.patch(
        '${ApiEndpoints.orders}/$id/items/$itemId/status',
        data: {'status': status},
      );
      final data = response.data is Map<String, dynamic> && response.data.containsKey('data') 
          ? response.data['data'] 
          : response.data;
      return OrderModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to update item status.");
    }
  }
}
