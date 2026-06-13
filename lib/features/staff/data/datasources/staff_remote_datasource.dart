import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../auth/data/models/user_model.dart';

class StaffRemoteDataSource {
  final Dio _dio;

  StaffRemoteDataSource(this._dio);

  Future<List<UserModel>> getStaff() async {
    try {
      final response = await _dio.get(ApiEndpoints.users);
      final data = response.data is Map<String, dynamic> && response.data.containsKey('users')
          ? response.data['users']
          : response.data;

      if (data is List) {
        return data.map((e) => UserModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to load staff list.");
    }
  }

  Future<Map<String, dynamic>> createStaff(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiEndpoints.users, data: data);
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        final userModel = UserModel.fromJson(responseData['data'] as Map<String, dynamic>);
        final password = responseData['generatedPassword'] as String? ?? '';
        return {
          'user': userModel,
          'generatedPassword': password,
        };
      }
      throw ApiException(message: "Invalid response from server.");
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to create staff member.");
    }
  }

  Future<UserModel> updateStaff(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('${ApiEndpoints.users}/$id', data: data);
      final responseData = response.data is Map<String, dynamic> && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return UserModel.fromJson(responseData as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to update staff member.");
    }
  }
}
