class MenuItemModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? categoryId; // Note: backend stores as 'category'
  final String? image;
  final String? imageId;
  final bool isAvailable;
  final int estimatedPreparationTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MenuItemModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.categoryId,
    this.image,
    this.imageId,
    required this.isAvailable,
    required this.estimatedPreparationTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      categoryId: json['categoryId'] as String? ?? json['category_id'] as String? ?? json['category'] as String?,
      image: (json['image'] is Map) ? (json['image'] as Map)['url'] as String? : json['image'] as String?,
      imageId: json['imageId'] as String? ?? json['image_id'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? json['is_available'] as bool? ?? true,
      estimatedPreparationTime:
          (json['estimatedPreparationTime'] as num?)?.toInt() ?? (json['estimated_preparation_time'] as num?)?.toInt() ?? 0,
      createdAt: _parseTimestamp(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseTimestamp(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'categoryId': categoryId,
        'image': image,
        'imageId': imageId,
        'image_id': imageId,
        'isAvailable': isAvailable,
        'estimatedPreparationTime': estimatedPreparationTime,
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
