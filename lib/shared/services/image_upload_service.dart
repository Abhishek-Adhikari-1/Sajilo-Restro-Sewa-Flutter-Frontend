import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/errors/exceptions.dart';

class ImageUploadService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  static Future<Map<String, dynamic>?> uploadImage(XFile file, {String folder = "general"}) async {
    try {
      final token = await SecureStorage.getToken(AppConstants.tokenKey);
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.name,
        ),
        'folder': folder,
      });

      final response = await _dio.post(
        ApiEndpoints.imageUpload,
        data: formData,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic> && data.containsKey('image')) {
          return data['image'] as Map<String, dynamic>;
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        throw ApiException.fromJson(e.response!.data);
      }
      throw ApiException(message: "Failed to upload image.");
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  static Future<Map<String, dynamic>?> pickAndUpload({
    ImageSource source = ImageSource.gallery,
    String folder = "general",
  }) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile == null) return null;

    return await uploadImage(pickedFile, folder: folder);
  }
}
