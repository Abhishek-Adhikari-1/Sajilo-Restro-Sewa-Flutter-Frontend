import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/menu_remote_datasource.dart';
import '../../data/models/category_model.dart';
import '../../data/models/menu_item_model.dart';

class MenuRepository {
  final MenuRemoteDataSource _remoteDataSource;

  MenuRepository(this._remoteDataSource);

  Future<(List<CategoryModel>, int)> getCategories({int cursor = 0, int limit = 20, String? search}) async {
    try {
      return await _remoteDataSource.getCategories(cursor: cursor, limit: limit, search: search);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<(List<MenuItemModel>, int)> getMenus({
    int cursor = 0,
    int limit = 25,
    String? search,
    String? categoryId,
    bool? isAvailable,
  }) async {
    try {
      return await _remoteDataSource.getMenus(
        cursor: cursor,
        limit: limit,
        search: search,
        categoryId: categoryId,
        isAvailable: isAvailable,
      );
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<MenuItemModel> createMenuItem(Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.createMenuItem(data);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<MenuItemModel> updateMenuItem(
      String id, Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.updateMenuItem(id, data);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> deleteMenuItem(String id) async {
    try {
      return await _remoteDataSource.deleteMenuItem(id);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<MenuItemModel> toggleAvailability(String id, bool isAvailable) async {
    try {
      return await _remoteDataSource.toggleAvailability(id, isAvailable);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<CategoryModel> createCategory(Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.createCategory(data);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<CategoryModel> updateCategory(
      String id, Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.updateCategory(id, data);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      return await _remoteDataSource.deleteCategory(id);
    } on ApiException catch (e) {
      throw ServerFailure(e.message, code: e.code, errors: e.errors);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
