import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/socket_client.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/order_model.dart';
import '../../domain/repositories/order_repository.dart';

part 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  final OrderRepository _repository;
  final SocketClient _socketClient;

  OrderCubit(this._repository, this._socketClient) : super(OrderInitial());

  void initSocket(String currentUserId, String currentUserRole) {
    _socketClient.socket?.on('order_created', (data) {
      if (data == null) return;
      try {
        final newOrder = OrderModel.fromJson(data);
        if (state is OrderLoaded) {
          final currentState = state as OrderLoaded;
          final existingIndex = currentState.orders.indexWhere(
            (o) => o.id == newOrder.id,
          );

          if (existingIndex >= 0) {
            final updatedOrders = List<OrderModel>.from(currentState.orders);
            updatedOrders[existingIndex] = newOrder;
            emit(OrderLoaded(orders: updatedOrders));
          } else {
            emit(OrderLoaded(orders: [...currentState.orders, newOrder]));
          }
        }
        
        // Trigger notification if applicable
        if (currentUserRole != 'admin' && newOrder.createdBy != currentUserId) {
          NotificationService.triggerNewOrderAlert(newOrder.id);
        }
      } catch (_) {}
    });

    _socketClient.socket?.on('order_updated', (data) {
      if (data == null) return;
      try {
        final Map<String, dynamic> payload = data as Map<String, dynamic>;
        final String id = payload['id'] ?? '';
        final String status = payload['status'] ?? '';
        
        if (state is OrderLoaded) {
          final currentState = state as OrderLoaded;
          
          // If the order is completed, paid, or cancelled, remove it from active orders
          if (status == 'completed' || status == 'paid' || status == 'cancelled') {
             final updatedOrders = currentState.orders.where((o) => o.id != id).toList();
             emit(OrderLoaded(orders: updatedOrders));
             return;
          }
          
          // If the payload is partial (e.g. from payment service), merge it with the existing order
          if (!payload.containsKey('table_id')) {
             final updatedOrders = currentState.orders.map((o) {
               if (o.id == id) {
                 return OrderModel(
                   id: o.id,
                   tableId: o.tableId,
                   tableNumber: o.tableNumber,
                   status: status,
                   items: o.items,
                   notes: o.notes,
                   createdBy: o.createdBy,
                   guestsCount: o.guestsCount,
                   createdAt: o.createdAt,
                   updatedAt: DateTime.now(),
                 );
               }
               return o;
             }).toList();
             emit(OrderLoaded(orders: updatedOrders));
             return;
          }

          // Otherwise it is a full order
          final updatedOrder = OrderModel.fromJson(payload);
          final updatedOrders = currentState.orders.map((o) {
            return o.id == updatedOrder.id ? updatedOrder : o;
          }).toList();
          emit(OrderLoaded(orders: updatedOrders));
          
          if (currentUserRole != 'admin' && updatedOrder.createdBy != currentUserId) {
            NotificationService.triggerOrderUpdatedAlert(updatedOrder.id);
          }
        }
      } catch (_) {}
    });

    // Fallback listeners for items if backend emits them separately
    _socketClient.socket?.on('order_items_added', (data) {
      // Since the backend 'order_updated' or similar might not have the full nested structure if not careful,
      // actually the backend returns the full order on item updates now! Wait, backend returns items array.
      // It's usually safer to just re-fetch or if the backend emits the full order, replace it.
      // The backend `addItemsToOrder` returns the items array, NOT the full order. Wait, in my previous edit I changed `addItemsToOrder` to return the FULL order!
      // So 'order_items_added' payload: { orderId: id, items: fullOrder }
      if (data != null && data['items'] != null) {
        try {
          final updatedOrder = OrderModel.fromJson(data['items']);
          if (state is OrderLoaded) {
            final currentState = state as OrderLoaded;
            final updatedOrders = currentState.orders.map((o) {
              return o.id == updatedOrder.id ? updatedOrder : o;
            }).toList();
            emit(OrderLoaded(orders: updatedOrders));
            
            if (currentUserRole != 'admin' && updatedOrder.createdBy != currentUserId) {
              NotificationService.triggerOrderUpdatedAlert(updatedOrder.id);
            }
          }
        } catch (_) {}
      }
    });

    _socketClient.socket?.on('order_item_updated', (data) {
      // Backend updateItemStatus returns the FULL order!
      if (data == null) return;
      try {
        final updatedOrder = OrderModel.fromJson(data);
        if (state is OrderLoaded) {
          final currentState = state as OrderLoaded;
          final updatedOrders = currentState.orders.map((o) {
            return o.id == updatedOrder.id ? updatedOrder : o;
          }).toList();
          emit(OrderLoaded(orders: updatedOrders));
        }
      } catch (_) {}
    });
  }

  Future<void> fetchActiveOrders() async {
    if (state is! OrderLoaded) {
      emit(OrderLoading());
    }
    try {
      final orders = await _repository.getActiveOrders();
      emit(OrderLoaded(orders: orders));
    } on ServerFailure catch (e) {
      emit(OrderError(message: e.message));
    } catch (e) {
      emit(OrderError(message: e.toString()));
    }
  }

  /// Convenience method: fetches active orders and filters by status='served'.
  Future<void> fetchServedOrders() async {
    if (state is! OrderLoaded) {
      emit(OrderLoading());
    }
    try {
      final orders = await _repository.getActiveOrders();
      final served = orders.where((o) => o.status == 'served').toList();
      emit(OrderLoaded(orders: served));
    } on ServerFailure catch (e) {
      emit(OrderError(message: e.message));
    } catch (e) {
      emit(OrderError(message: e.toString()));
    }
  }

  Future<void> createOrder(OrderModel order) async {
    final currentState = state;
    emit(OrderLoading());
    try {
      final newOrder = await _repository.createOrder(order);
      if (currentState is OrderLoaded) {
        emit(OrderLoaded(orders: [...currentState.orders, newOrder]));
      } else {
        emit(OrderLoaded(orders: [newOrder]));
      }
    } on ServerFailure catch (e) {
      emit(OrderError(message: e.message));
    } catch (e) {
      emit(OrderError(message: e.toString()));
    }
  }

  Future<void> updateOrderStatus(String id, String status) async {
    final currentState = state;
    if (currentState is OrderLoaded) {
      // Optimistic Update
      final optimisticOrders = currentState.orders.map((order) {
        if (order.id == id) {
          return OrderModel(
            id: order.id,
            tableId: order.tableId,
            status: status, // Optimistic status
            items: order.items.map((item) {
              String itemStatus = item.status;
              if (status == 'preparing' && itemStatus == 'pending') {
                itemStatus = 'preparing';
              } else if (status == 'ready' &&
                  (itemStatus == 'pending' || itemStatus == 'preparing')) {
                itemStatus = 'ready';
              } else if (status == 'served' && itemStatus == 'ready') {
                itemStatus = 'served';
              } else if (status == 'cancelled') {
                itemStatus = 'cancelled';
              }

              return OrderItemModel(
                id: item.id,
                name: item.name,
                price: item.price,
                quantity: item.quantity,
                specialInstructions: item.specialInstructions,
                status: itemStatus,
              );
            }).toList(),
            notes: order.notes,
            createdBy: order.createdBy,
            guestsCount: order.guestsCount,
            createdAt: order.createdAt,
            updatedAt: order.updatedAt,
          );
        }
        return order;
      }).toList();
      emit(OrderLoaded(orders: optimisticOrders));

      try {
        final updatedOrder = await _repository.updateOrderStatus(id, status);
        final finalState = state;
        if (finalState is OrderLoaded) {
          final updatedOrders = finalState.orders.map((order) {
            return order.id == id ? updatedOrder : order;
          }).toList();
          emit(OrderLoaded(orders: updatedOrders));
        }
      } on ServerFailure catch (_) {
        emit(currentState); // Revert
      } catch (_) {
        emit(currentState); // Revert
      }
    }
  }

  Future<void> addItemsToOrder(String id, List<OrderItemModel> items) async {
    final currentState = state;
    emit(OrderLoading());
    try {
      final updatedOrder = await _repository.addItemsToOrder(id, items);
      if (currentState is OrderLoaded) {
        final updatedOrders = currentState.orders.map((order) {
          return order.id == id ? updatedOrder : order;
        }).toList();
        emit(OrderLoaded(orders: updatedOrders));
      } else {
        emit(OrderLoaded(orders: [updatedOrder]));
      }
    } on ServerFailure catch (e) {
      emit(OrderError(message: e.message));
    } catch (e) {
      emit(OrderError(message: e.toString()));
    }
  }

  Future<void> updateOrderItems(String id, List<OrderItemModel> items, String? notes) async {
    final currentState = state;
    emit(OrderLoading());
    try {
      final updatedOrder = await _repository.updateOrderItems(id, items, notes);
      if (currentState is OrderLoaded) {
        final updatedOrders = currentState.orders.map((order) {
          return order.id == id ? updatedOrder : order;
        }).toList();
        emit(OrderLoaded(orders: updatedOrders));
      } else {
        emit(OrderLoaded(orders: [updatedOrder]));
      }
    } on ServerFailure catch (e) {
      emit(OrderError(message: e.message));
    } catch (e) {
      emit(OrderError(message: e.toString()));
    }
  }

  Future<void> updateOrderItemStatus(
    String id,
    String itemId,
    String status,
  ) async {
    final currentState = state;

    if (currentState is OrderLoaded) {
      // Optimistic update
      final optimisticOrders = currentState.orders.map((order) {
        if (order.id == id) {
          final updatedItems = order.items.map((item) {
            if (item.id == itemId) {
              return OrderItemModel(
                id: item.id,
                name: item.name,
                price: item.price,
                quantity: item.quantity,
                specialInstructions: item.specialInstructions,
                status: status, // New status
              );
            }
            return item;
          }).toList();

          return OrderModel(
            id: order.id,
            tableId: order.tableId,
            status: order
                .status, // Leaving order status as is, backend will return final correct status
            items: updatedItems,
            notes: order.notes,
            createdBy: order.createdBy,
            guestsCount: order.guestsCount,
            createdAt: order.createdAt,
            updatedAt: order.updatedAt,
          );
        }
        return order;
      }).toList();

      emit(OrderLoaded(orders: optimisticOrders));
    } else {
      emit(OrderLoading());
    }

    try {
      final updatedOrder = await _repository.updateOrderItemStatus(
        id,
        itemId,
        status,
      );
      final finalState = state;
      if (finalState is OrderLoaded) {
        final updatedOrders = finalState.orders.map((order) {
          return order.id == id ? updatedOrder : order;
        }).toList();
        emit(OrderLoaded(orders: updatedOrders));
      } else {
        emit(OrderLoaded(orders: [updatedOrder]));
      }
    } on ServerFailure catch (e) {
      // Revert back to original state
      if (currentState is OrderLoaded) {
        emit(currentState);
      } else {
        emit(OrderError(message: e.message));
      }
    } catch (e) {
      if (currentState is OrderLoaded) {
        emit(currentState);
      } else {
        emit(OrderError(message: e.toString()));
      }
    }
  }
}
