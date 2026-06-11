import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';

class MenuRemoteDataSource {
  final Dio _dio;

  MenuRemoteDataSource(this._dio);

  Future<List<CategoryModel>> getCategories({int cursor = 0, int limit = 25}) async {
    try {
      final response = await _dio.get(ApiEndpoints.categories, queryParameters: {
        if (cursor > 0) 'offset': cursor,
        'limit': limit,
      });
      final data = response.data is Map<String, dynamic> && response.data.containsKey('categories') 
          ? response.data['categories'] 
          : response.data;
          
      if (data is List) {
        return data.map((e) => CategoryModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to load categories.");
    }
  }

  Future<List<MenuItemModel>> getMenus({
    int cursor = 0,
    int limit = 25,
    String? search,
    String? categoryId,
  }) async {
    try {
      final response = await _dio.get(ApiEndpoints.menus, queryParameters: {
        if (cursor > 0) 'offset': cursor,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      });
      final data = response.data is Map<String, dynamic> && response.data.containsKey('menus') 
          ? response.data['menus'] 
          : response.data;

      if (data is List) {
        return data.map((e) => MenuItemModel.fromJson(e)).toList();
      }
      return [];
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

  Future<MenuItemModel> toggleAvailability(String id) async {
    try {
      final response =
          await _dio.patch('${ApiEndpoints.menus}/$id/toggle-availability');
      final responseData = response.data is Map<String, dynamic> &&
              response.data.containsKey('data')
          ? response.data['data']
          : response.data;
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

