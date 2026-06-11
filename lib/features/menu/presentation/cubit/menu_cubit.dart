import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/category_model.dart';
import '../../data/models/menu_item_model.dart';
import '../../domain/repositories/menu_repository.dart';
import '../../../../core/network/socket_client.dart';

part 'menu_state.dart';

class MenuCubit extends Cubit<MenuState> {
  final MenuRepository _repository;
  final SocketClient _socketClient;

  MenuCubit(this._repository, this._socketClient) : super(MenuInitial());

  void initSocket() {
    _socketClient.socket?.on('menu_updated', (data) {
      if (data == null) return;
      try {
        final Map<String, dynamic> itemJson = data['menu'] ?? data;
        final updatedMenu = MenuItemModel.fromJson(itemJson);
        if (state is MenuLoaded) {
          final currentState = state as MenuLoaded;
          final existingIndex = currentState.menus.indexWhere((m) => m.id == updatedMenu.id);
          if (existingIndex >= 0) {
            final updatedMenus = List<MenuItemModel>.from(currentState.menus);
            updatedMenus[existingIndex] = updatedMenu;
            emit(currentState.copyWith(menus: updatedMenus));
          } else {
            emit(currentState.copyWith(menus: [...currentState.menus, updatedMenu]));
          }
        }
      } catch (_) {}
    });

    _socketClient.socket?.on('menu_status_updated', (data) {
      if (data == null) return;
      try {
        if (state is MenuLoaded) {
          final currentState = state as MenuLoaded;
          final updatedMenus = currentState.menus.map((m) {
            return m.id == data['id'] 
              ? MenuItemModel(
                  id: m.id,
                  name: m.name,
                  description: m.description,
                  price: m.price,
                  categoryId: m.categoryId,
                  image: m.image,
                  isAvailable: data['isAvailable'] ?? data['is_available'] ?? m.isAvailable,
                  estimatedPreparationTime: m.estimatedPreparationTime,
                  createdAt: m.createdAt,
                  updatedAt: DateTime.tryParse(data['updatedAt'] ?? data['updated_at'] ?? '') ?? m.updatedAt,
                ) 
              : m;
          }).toList();
          emit(currentState.copyWith(menus: updatedMenus));
        }
      } catch (_) {}
    });

    _socketClient.socket?.on('menu_deleted', (data) {
      if (data == null) return;
      try {
        if (state is MenuLoaded) {
          final currentState = state as MenuLoaded;
          emit(currentState.copyWith(
            menus: currentState.menus.where((m) => m.id != data['id']).toList(),
          ));
        }
      } catch (_) {}
    });
  }

  Future<void> fetchMenuData({String? search, String? categoryId}) async {
    final currentState = state;
    List<CategoryModel> categories = [];
    
    if (currentState is! MenuLoaded) {
      emit(MenuLoading());
    } else {
      categories = currentState.categories;
    }
    
    try {
      if (categories.isEmpty) {
        categories = await _repository.getCategories(cursor: 0, limit: 25);
      }
      
      final menus = await _repository.getMenus(
        cursor: 0, 
        limit: 25,
        search: search,
        categoryId: categoryId,
      );
      
      emit(MenuLoaded(
        categories: categories, 
        menus: menus,
        categoryCursor: currentState is MenuLoaded ? currentState.categoryCursor : categories.length,
        menuCursor: menus.length,
        hasReachedMaxCategories: currentState is MenuLoaded ? currentState.hasReachedMaxCategories : categories.length < 25,
        hasReachedMaxMenus: menus.length < 25,
        currentSearch: search,
        currentCategoryId: categoryId,
      ));
    } on ServerFailure catch (e) {
      emit(MenuError(message: e.message));
    } catch (e) {
      emit(MenuError(message: e.toString()));
    }
  }

  Future<void> fetchMoreMenus() async {
    final currentState = state;
    if (currentState is! MenuLoaded || currentState.hasReachedMaxMenus || currentState.isFetchingMoreMenus) return;

    emit(currentState.copyWith(isFetchingMoreMenus: true));

    try {
      final menus = await _repository.getMenus(
        cursor: currentState.menuCursor, 
        limit: 25,
        search: currentState.currentSearch,
        categoryId: currentState.currentCategoryId,
      );
      emit(currentState.copyWith(
        menus: List.of(currentState.menus)..addAll(menus),
        menuCursor: currentState.menuCursor + menus.length,
        hasReachedMaxMenus: menus.length < 25,
        isFetchingMoreMenus: false,
      ));
    } catch (_) {
      emit(currentState.copyWith(isFetchingMoreMenus: false));
    }
  }

  Future<void> fetchMoreCategories() async {
    final currentState = state;
    if (currentState is! MenuLoaded || currentState.hasReachedMaxCategories || currentState.isFetchingMoreCategories) return;

    emit(currentState.copyWith(isFetchingMoreCategories: true));

    try {
      final categories = await _repository.getCategories(cursor: currentState.categoryCursor, limit: 25);
      emit(currentState.copyWith(
        categories: List.of(currentState.categories)..addAll(categories),
        categoryCursor: currentState.categoryCursor + categories.length,
        hasReachedMaxCategories: categories.length < 25,
        isFetchingMoreCategories: false,
      ));
    } catch (_) {
      emit(currentState.copyWith(isFetchingMoreCategories: false));
    }
  }

  Future<void> createMenuItem(Map<String, dynamic> data) async {
    try {
      final newItem = await _repository.createMenuItem(data);
      final currentState = state;
      if (currentState is MenuLoaded) {
        emit(currentState.copyWith(
          menus: [...currentState.menus, newItem],
        ));
      }
    } on ServerFailure catch (e) {
      emit(MenuError(message: e.message));
    } catch (e) {
      emit(MenuError(message: e.toString()));
    }
  }

  Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _repository.updateMenuItem(id, data);
      final currentState = state;
      if (currentState is MenuLoaded) {
        final updatedMenus = currentState.menus.map((m) {
          return m.id == id ? updated : m;
        }).toList();
        emit(currentState.copyWith(
          menus: updatedMenus,
        ));
      }
    } on ServerFailure catch (e) {
      emit(MenuError(message: e.message));
    } catch (e) {
      emit(MenuError(message: e.toString()));
    }
  }

  Future<void> deleteMenuItem(String id) async {
    try {
      await _repository.deleteMenuItem(id);
      final currentState = state;
      if (currentState is MenuLoaded) {
        emit(currentState.copyWith(
          menus: currentState.menus.where((m) => m.id != id).toList(),
        ));
      }
    } on ServerFailure catch (e) {
      emit(MenuError(message: e.message));
    } catch (e) {
      emit(MenuError(message: e.toString()));
    }
  }

  Future<void> toggleAvailability(String id) async {
    try {
      final updated = await _repository.toggleAvailability(id);
      final currentState = state;
      if (currentState is MenuLoaded) {
        final updatedMenus = currentState.menus.map((m) {
          return m.id == id ? updated : m;
        }).toList();
        emit(currentState.copyWith(
          menus: updatedMenus,
        ));
      }
    } on ServerFailure catch (e) {
      emit(MenuError(message: e.message));
    } catch (e) {
      emit(MenuError(message: e.toString()));
    }
  }

  Future<void> createCategory(Map<String, dynamic> data) async {
    try {
      final newCat = await _repository.createCategory(data);
      final currentState = state;
      if (currentState is MenuLoaded) {
        emit(currentState.copyWith(
          categories: [...currentState.categories, newCat],
        ));
      }
    } on ServerFailure catch (e) {
      emit(MenuError(message: e.message));
    } catch (e) {
      emit(MenuError(message: e.toString()));
    }
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _repository.updateCategory(id, data);
      final currentState = state;
      if (currentState is MenuLoaded) {
        final updatedCats = currentState.categories.map((c) {
          return c.id == id ? updated : c;
        }).toList();
        emit(currentState.copyWith(
          categories: updatedCats,
        ));
      }
    } on ServerFailure catch (e) {
      emit(MenuError(message: e.message));
    } catch (e) {
      emit(MenuError(message: e.toString()));
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);
      final currentState = state;
      if (currentState is MenuLoaded) {
        emit(currentState.copyWith(
          categories: currentState.categories.where((c) => c.id != id).toList(),
        ));
      }
    } on ServerFailure catch (e) {
      emit(MenuError(message: e.message));
    } catch (e) {
      emit(MenuError(message: e.toString()));
    }
  }
}
