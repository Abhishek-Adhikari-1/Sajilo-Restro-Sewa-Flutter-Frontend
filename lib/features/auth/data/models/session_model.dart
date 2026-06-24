class SessionModel {
  final String token;
  final DateTime expiresAt;

  SessionModel({
    required this.token,
    required this.expiresAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      token: json['token'] ?? '',
      expiresAt: DateTime.parse(json['expiresAt'] ?? DateTime.now().toIso8601String()).toLocal(),
    );
  }
}
