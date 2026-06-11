class ApiException implements Exception {
  final String message;
  final String? code;
  final List<ValidationError>? errors;

  ApiException({required this.message, this.code, this.errors});

  factory ApiException.fromJson(Map<String, dynamic> json) {
    List<ValidationError>? validationErrors;
    if (json['errors'] != null) {
      validationErrors = (json['errors'] as List)
          .map((e) => ValidationError.fromJson(e))
          .toList();
    }
    return ApiException(
      message: json['message'] ?? "Something went wrong",
      code: json['code']?.toString(),
      errors: validationErrors,
    );
  }
}

class ValidationError {
  final String field;
  final String message;

  ValidationError({required this.field, required this.message});

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      field: json['field'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
