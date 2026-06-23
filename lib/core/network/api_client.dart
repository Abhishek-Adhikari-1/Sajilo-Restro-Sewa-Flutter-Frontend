import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../storage/secure_storage.dart';
import '../services/user_agent_service.dart';

class ApiClient {
  final http.Client _client = http.Client();

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final userAgent = await UserAgentService.getUserAgent();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': userAgent,
    };

    if (requiresAuth) {
      final token = await SecureStorage.getToken(AppConstants.tokenKey);
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.post(
        Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 10));

      return _processResponse(response);
    } on SocketException {
      throw ApiException(message: 'No Internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Unexpected error occurred: $e');
    }
  }

  Future<dynamic> get(String endpoint, {bool requiresAuth = true}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.get(
        Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      return _processResponse(response);
    } on SocketException {
      throw ApiException(message: 'No Internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Unexpected error occurred: $e');
    }
  }
  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.put(
        Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } on SocketException {
      throw ApiException(message: 'No Internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Unexpected error occurred: $e');
    }
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.patch(
        Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } on SocketException {
      throw ApiException(message: 'No Internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Unexpected error occurred: $e');
    }
  }

  Future<dynamic> delete(String endpoint, {bool requiresAuth = true}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client.delete(
        Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } on SocketException {
      throw ApiException(message: 'No Internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Unexpected error occurred: $e');
    }
  }
  dynamic _processResponse(http.Response response) {
    final body = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      if (body is Map<String, dynamic>) {
         throw ApiException.fromJson(body);
      }
      throw ApiException(message: 'Server Error: ${response.statusCode}');
    }
  }
}
