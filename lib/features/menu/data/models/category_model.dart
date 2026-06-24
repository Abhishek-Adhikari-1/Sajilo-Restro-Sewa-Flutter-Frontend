class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final String? iconId;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.iconId,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: (json['icon'] is Map) ? (json['icon'] as Map)['url'] as String? : json['icon'] as String?,
      iconId: json['iconId'] as String? ?? json['icon_id'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      createdAt: _parseTimestamp(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseTimestamp(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'iconId': iconId,
        'icon_id': iconId,
        'description': description,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static DateTime _parseTimestamp(dynamic json) {
    if (json == null) return DateTime.now();
    if (json is String) {
      return (DateTime.tryParse(json) ?? DateTime.now()).toLocal();
    }
    if (json is Map<String, dynamic>) {
      final seconds = (json['_seconds'] as num?)?.toInt() ?? 0;
      final nanoseconds = (json['_nanoseconds'] as num?)?.toInt() ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000)
          .add(Duration(microseconds: nanoseconds ~/ 1000));
    }
    return DateTime.now();
  }
}
