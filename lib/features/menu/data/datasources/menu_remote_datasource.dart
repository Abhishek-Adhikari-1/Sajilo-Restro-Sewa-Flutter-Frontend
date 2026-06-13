import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';

class MenuRemoteDataSource {
  final Dio _dio;

  MenuRemoteDataSource(this._dio);

  Future<(List<CategoryModel>, int)> getCategories({int cursor = 0, int limit = 25, String? search}) async {
    try {
      final response = await _dio.get(ApiEndpoints.categories, queryParameters: {
        if (cursor > 0) 'offset': cursor,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      });
      final data = response.data is Map<String, dynamic> && response.data.containsKey('categories') 
          ? response.data['categories'] 
          : response.data;
          
      final total = response.data is Map<String, dynamic> && response.data.containsKey('total') 
          ? (response.data['total'] as int? ?? 0)
          : 0;

      if (data is List) {
        return (data.map((e) => CategoryModel.fromJson(e)).toList(), total);
      }
      return (<CategoryModel>[], 0);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to load categories.");
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
      final response = await _dio.get(ApiEndpoints.menus, queryParameters: {
        if (cursor > 0) 'offset': cursor,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        'isAvailable': ?isAvailable,
      });
      final data = response.data is Map<String, dynamic> && response.data.containsKey('menus') 
          ? response.data['menus'] 
          : response.data;
      final total = response.data is Map<String, dynamic> && response.data.containsKey('total') 
          ? (response.data['total'] as int? ?? 0)
          : 0;

      if (data is List) {
        final list = data.map((e) => MenuItemModel.fromJson(e)).toList();
        return (list, total);
      }
      return (<MenuItemModel>[], 0);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to load menus.");
    }
  }

  Future<MenuItemModel> createMenuItem(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiEndpoints.menus, data: data);
      final responseData = response.data is Map<String, dynamic> &&
              response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return MenuItemModel.fromJson(responseData as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to create menu item.");
    }
  }

  Future<MenuItemModel> updateMenuItem(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.patch('${ApiEndpoints.menus}/$id', data: data);
      final responseData = response.data is Map<String, dynamic> &&
              response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return MenuItemModel.fromJson(responseData as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to update menu item.");
    }
  }

  Future<void> deleteMenuItem(String id) async {
    try {
      await _dio.delete('${ApiEndpoints.menus}/$id');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to delete menu item.");
    }
  }

  Future<MenuItemModel> toggleAvailability(String id, bool isAvailable) async {
    try {
      final response = await _dio.patch(
        '${ApiEndpoints.menus}/$id/status',
        data: {'isAvailable': isAvailable},
      );
      final responseData = response.data is Map<String, dynamic> &&
              response.data.containsKey('data')
          ? response.data['data']
          : (response.data is Map<String, dynamic> && response.data.containsKey('menu')
              ? response.data['menu']
              : response.data);
      return MenuItemModel.fromJson(responseData as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to toggle availability.");
    }
  }

  Future<CategoryModel> createCategory(Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post(ApiEndpoints.categories, data: data);
      final responseData = response.data is Map<String, dynamic> &&
              response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return CategoryModel.fromJson(responseData as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to create category.");
    }
  }

  Future<CategoryModel> updateCategory(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.patch('${ApiEndpoints.categories}/$id', data: data);
      final responseData = response.data is Map<String, dynamic> &&
              response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return CategoryModel.fromJson(responseData as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to update category.");
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _dio.delete('${ApiEndpoints.categories}/$id');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to delete category.");
    }
  }
}

