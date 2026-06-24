class ActiveSessionModel {
  final String id;
  final String? userAgent;
  final String? ipAddress;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isCurrent;

  ActiveSessionModel({
    required this.id,
    this.userAgent,
    this.ipAddress,
    required this.createdAt,
    required this.expiresAt,
    this.isCurrent = false,
  });

  factory ActiveSessionModel.fromJson(Map<String, dynamic> json) {
    return ActiveSessionModel(
      id: json['id'],
      userAgent: json['userAgent'],
      ipAddress: json['ipAddress'],
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
      expiresAt: DateTime.parse(json['expiresAt']).toLocal(),
      isCurrent: json['isCurrent'] ?? false,
    );
  }
}
