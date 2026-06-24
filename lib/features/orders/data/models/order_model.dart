class OrderItemModel {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String? specialInstructions;
  final String status;

  OrderItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.specialInstructions,
    this.status = 'pending',
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
      specialInstructions: json['special_instructions'],
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'special_instructions': specialInstructions,
      'status': status,
    };
  }
}

class OrderModel {
  final String id;
  final String tableId;
  final int? tableNumber;
  final String? tableSection;
  final String status;
  final List<OrderItemModel> items;
  final String? notes;
  final String createdBy;
  final int guestsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderModel({
    required this.id,
    required this.tableId,
    this.tableNumber,
    this.tableSection,
    required this.status,
    required this.items,
    this.notes,
    required this.createdBy,
    this.guestsCount = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalAmount =>
      items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String? ?? '',
      tableId: json['table_id'] as String? ?? '',
      tableNumber: json['table_number'] as int?,
      tableSection: json['table_section'] as String?,
      status: json['status'] as String? ?? 'pending',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String? ?? '',
      guestsCount: (json['guests_count'] as num?)?.toInt() ?? 1,
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'table_id': tableId,
        'table_number': tableNumber,
        'table_section': tableSection,
        'status': status,
        'items': items.map((e) => e.toJson()).toList(),
        'notes': notes,
        'guests_count': guestsCount,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
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
