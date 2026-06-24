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

  MenuRepository get repository => _repository;

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
          final updatedIsAvailable = data['isAvailable'] ?? data['is_available'];
          
          if (currentState.currentIsAvailable != null && 
              updatedIsAvailable != null && 
              updatedIsAvailable != currentState.currentIsAvailable) {
            fetchMenuData(
              search: currentState.currentSearch,
              categoryId: currentState.currentCategoryId,
              offset: currentState.menuOffset,
              limit: currentState.limit,
              isAvailable: currentState.currentIsAvailable,
            );
          } else {
            final updatedMenus = currentState.menus.map((m) {
              return m.id == data['id'] 
                ? MenuItemModel(
                    id: m.id,
                    name: m.name,
                    description: m.description,
                    price: m.price,
                    categoryId: m.categoryId,
                    image: m.image,
                    isAvailable: updatedIsAvailable ?? m.isAvailable,
                    estimatedPreparationTime: m.estimatedPreparationTime,
                    createdAt: m.createdAt,
                    updatedAt: DateTime.tryParse(data['updatedAt'] ?? data['updated_at'] ?? '')?.toLocal() ?? m.updatedAt,
                  ) 
                : m;
            }).toList();
            emit(currentState.copyWith(menus: updatedMenus));
          }
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

  Future<void> fetchMenuData({String? search, String? categoryId, int offset = 0, int limit = 10, bool? isAvailable}) async {
    final currentState = state;
    List<CategoryModel> categories = [];
    
    if (currentState is! MenuLoaded) {
      emit(MenuLoading());
    } else {
      categories = currentState.categories;
      if (currentState.categorySearch != null && currentState.categorySearch!.isNotEmpty) {
        categories = [];
      }
    }
    
    try {
      int catTotal = currentState is MenuLoaded ? currentState.categoryTotal : 0;
      if (categories.isEmpty) {
        final (fetchedCats, fetchedTotal) = await _repository.getCategories(cursor: 0, limit: 25);
        categories = fetchedCats;
        catTotal = fetchedTotal;
      }
      
      final (menus, total) = await _repository.getMenus(
        cursor: offset, 
        limit: limit,
        search: search,
        categoryId: categoryId,
        isAvailable: isAvailable,
      );
      
      emit(MenuLoaded(
        categories: categories, 
        menus: menus,
        categoryCursor: currentState is MenuLoaded ? currentState.categoryCursor : categories.length,
        menuCursor: offset + menus.length,
        hasReachedMaxCategories: currentState is MenuLoaded ? currentState.hasReachedMaxCategories : categories.length < 25,
        hasReachedMaxMenus: offset + menus.length >= total,
        currentSearch: search,
        currentCategoryId: categoryId,
        total: total,
        menuOffset: offset,
        limit: limit,
        currentIsAvailable: isAvailable,
        editedMenus: currentState is MenuLoaded ? currentState.editedMenus : const {},
        categorySearch: null,
        categoryTotal: catTotal,
        categoryOffset: currentState is MenuLoaded ? currentState.categoryOffset : 0,
        categoryLimit: currentState is MenuLoaded ? currentState.categoryLimit : 25,
        editedCategories: currentState is MenuLoaded ? currentState.editedCategories : const {},
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
      final (menus, total) = await _repository.getMenus(
        cursor: currentState.menuCursor, 
        limit: 25,
        search: currentState.currentSearch,
        categoryId: currentState.currentCategoryId,
        isAvailable: currentState.currentIsAvailable,
      );
      emit(currentState.copyWith(
        menus: List.of(currentState.menus)..addAll(menus),
        menuCursor: currentState.menuCursor + menus.length,
        hasReachedMaxMenus: currentState.menuCursor + menus.length >= total,
        total: total,
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
      final (fetchedCats, _) = await _repository.getCategories(cursor: currentState.categoryCursor, limit: 25, search: currentState.categorySearch);
      emit(currentState.copyWith(
        categories: List.of(currentState.categories)..addAll(fetchedCats),
        categoryCursor: currentState.categoryCursor + fetchedCats.length,
        hasReachedMaxCategories: fetchedCats.length < 25,
        isFetchingMoreCategories: false,
      ));
    } catch (_) {
      emit(currentState.copyWith(isFetchingMoreCategories: false));
    }
  }

  Future<void> fetchCategoriesOnly({String? search, int offset = 0, int limit = 25}) async {
    final currentState = state;
    if (currentState is! MenuLoaded) {
      emit(MenuLoading());
    }

    try {
      final (categories, total) = await _repository.getCategories(cursor: offset, limit: limit, search: search);
      
      if (currentState is MenuLoaded) {
        emit(currentState.copyWith(
          categories: categories,
          categoryCursor: offset + categories.length,
          hasReachedMaxCategories: offset + categories.length >= total,
          categorySearch: search,
          categoryOffset: offset,
          categoryLimit: limit,
          categoryTotal: total,
        ));
      } else {
        emit(MenuLoaded(
          categories: categories,
          menus: const [],
          categoryCursor: offset + categories.length,
          hasReachedMaxCategories: offset + categories.length >= total,
          categorySearch: search,
          categoryOffset: offset,
          categoryLimit: limit,
          categoryTotal: total,
        ));
      }
    } on ServerFailure catch (e) {
      emit(MenuError(message: e.message));
    } catch (e) {
      emit(MenuError(message: e.toString()));
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
        if (currentState.currentIsAvailable != null && updated.isAvailable != currentState.currentIsAvailable) {
          fetchMenuData(
            search: currentState.currentSearch,
            categoryId: currentState.currentCategoryId,
            offset: currentState.menuOffset,
            limit: currentState.limit,
            isAvailable: currentState.currentIsAvailable,
          );
        } else {
          final updatedMenus = currentState.menus.map((m) {
            return m.id == id ? updated : m;
          }).toList();
          emit(currentState.copyWith(
            menus: updatedMenus,
          ));
        }
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
    final currentState = state;
    if (currentState is! MenuLoaded) return;

    final existingIndex = currentState.menus.indexWhere((m) => m.id == id);
    if (existingIndex < 0) return;

    final currentMenu = currentState.menus[existingIndex];
    final currentLocalAvailability = currentState.editedMenus.containsKey(id)
        ? currentState.editedMenus[id]!
        : currentMenu.isAvailable;

    final nextAvailable = !currentLocalAvailability;

    final newEditedMenus = Map<String, bool>.from(currentState.editedMenus);

    if (currentMenu.isAvailable == nextAvailable) {
      newEditedMenus.remove(id);
    } else {
      newEditedMenus[id] = nextAvailable;
    }

    emit(currentState.copyWith(editedMenus: newEditedMenus));
  }

  Future<void> toggleCategoryAvailability(String id) async {
    final currentState = state;
    if (currentState is! MenuLoaded) return;

    final existingIndex = currentState.categories.indexWhere((c) => c.id == id);
    if (existingIndex < 0) return;

    final currentCategory = currentState.categories[existingIndex];
    final currentLocalAvailability = currentState.editedCategories.containsKey(id)
        ? currentState.editedCategories[id]!
        : currentCategory.isActive;

    final nextAvailable = !currentLocalAvailability;

    final newEditedCategories = Map<String, bool>.from(currentState.editedCategories);

    if (currentCategory.isActive == nextAvailable) {
      newEditedCategories.remove(id);
    } else {
      newEditedCategories[id] = nextAvailable;
    }

    emit(currentState.copyWith(editedCategories: newEditedCategories));
  }

  Future<void> saveChanges() async {
    if (state is! MenuLoaded) return;
    final currentState = state as MenuLoaded;
    if ((currentState.editedMenus.isEmpty && currentState.editedCategories.isEmpty) || currentState.isSaving) return;

    emit(currentState.copyWith(isSaving: true, clearErrorMessage: true));

    try {
      for (final entry in currentState.editedMenus.entries) {
        final id = entry.key;
        final isAvailable = entry.value;
        await _repository.toggleAvailability(id, isAvailable);
      }

      for (final entry in currentState.editedCategories.entries) {
        final id = entry.key;
        final isActive = entry.value;
        await _repository.updateCategory(id, {'is_active': isActive});
      }

      emit(currentState.copyWith(
        isSaving: false,
        editedMenus: const {},
        editedCategories: const {},
      ));

      fetchMenuData(
        search: currentState.currentSearch,
        categoryId: currentState.currentCategoryId,
        offset: currentState.menuOffset,
        limit: currentState.limit,
        isAvailable: currentState.currentIsAvailable,
      );
    } on ServerFailure catch (e) {
      emit(currentState.copyWith(isSaving: false, errorMessage: e.message));
    } catch (e) {
      emit(currentState.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  void discardChanges() {
    if (state is MenuLoaded) {
      final currentState = state as MenuLoaded;
      emit(currentState.copyWith(
        editedMenus: const {},
        editedCategories: const {},
        clearErrorMessage: true,
      ));
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
