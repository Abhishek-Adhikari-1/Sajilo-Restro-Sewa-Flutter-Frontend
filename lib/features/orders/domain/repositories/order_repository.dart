import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/models/order_model.dart';

class OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;

  OrderRepository(this._remoteDataSource);

  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      return await _remoteDataSource.createOrder(order);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<OrderModel>> getActiveOrders() async {
    try {
      return await _remoteDataSource.getActiveOrders();
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<OrderModel> updateOrderStatus(String id, String status) async {
    try {
      return await _remoteDataSource.updateOrderStatus(id, status);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<OrderModel> addItemsToOrder(
    String id,
    List<OrderItemModel> items,
  ) async {
    try {
      return await _remoteDataSource.addItemsToOrder(id, items);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<OrderModel> updateOrderItems(
    String id,
    List<OrderItemModel> items,
    String? notes,
  ) async {
    try {
      return await _remoteDataSource.updateOrderItems(id, items, notes);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<OrderModel> updateOrderItemStatus(
    String id,
    String itemId,
    String status,
  ) async {
    try {
      return await _remoteDataSource.updateOrderItemStatus(id, itemId, status);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
