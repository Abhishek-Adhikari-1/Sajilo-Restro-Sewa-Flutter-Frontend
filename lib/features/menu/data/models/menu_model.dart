import 'package:equatable/equatable.dart';

class MenuModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int price;
  final int? estimatedPreparationTime;
  final String? imageId;
  final String categoryId;
  final String? categoryName;
  final bool isAvailable;

  const MenuModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.estimatedPreparationTime,
    this.imageId,
    required this.categoryId,
    this.categoryName,
    required this.isAvailable,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: json['price'] as int,
      estimatedPreparationTime: json['estimatedPreparationTime'] as int?,
      imageId: json['imageId'] as String?,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'estimatedPreparationTime': estimatedPreparationTime,
      'imageId': imageId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'isAvailable': isAvailable,
    };
  }

  MenuModel copyWith({
    String? id,
    String? name,
    String? description,
    int? price,
    int? estimatedPreparationTime,
    String? imageId,
    String? categoryId,
    String? categoryName,
    bool? isAvailable,
  }) {
    return MenuModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      estimatedPreparationTime: estimatedPreparationTime ?? this.estimatedPreparationTime,
      imageId: imageId ?? this.imageId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        estimatedPreparationTime,
        imageId,
        categoryId,
        categoryName,
        isAvailable,
      ];
}
