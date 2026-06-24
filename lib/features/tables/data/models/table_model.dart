class TableModel {
  final String id;
  final int tableNumber;
  final int capacity;
  final int occupiedSeats;
  final String status;
  final String section;
  final String? reservedFor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<dynamic> orders;
  final List<String> activeOrders;

  const TableModel({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.occupiedSeats,
    required this.status,
    required this.section,
    this.reservedFor,
    required this.createdAt,
    required this.updatedAt,
    this.orders = const [],
    this.activeOrders = const [],
  });

  TableModel copyWith({
    String? id,
    int? tableNumber,
    int? capacity,
    int? occupiedSeats,
    String? status,
    String? section,
    String? reservedFor,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<dynamic>? orders,
    List<String>? activeOrders,
  }) {
    return TableModel(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      capacity: capacity ?? this.capacity,
      occupiedSeats: occupiedSeats ?? this.occupiedSeats,
      status: status ?? this.status,
      section: section ?? this.section,
      reservedFor: reservedFor ?? this.reservedFor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      orders: orders ?? this.orders,
      activeOrders: activeOrders ?? this.activeOrders,
    );
  }

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'] as String? ?? '',
      tableNumber: json['tableNumber'] as int? ?? 0,
      capacity: json['capacity'] as int? ?? 0,
      occupiedSeats: json['occupiedSeats'] as int? ?? 0,
      status: json['status'] as String? ?? 'available',
      section: json['section'] as String? ?? '',
      reservedFor: json['reservedFor'] as String?,
      orders: json['orders'] as List<dynamic>? ?? [],
      activeOrders: (json['activeOrders'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tableNumber': tableNumber,
        'capacity': capacity,
        'occupiedSeats': occupiedSeats,
        'status': status,
        'section': section,
        'reservedFor': reservedFor,
        'orders': orders,
        'activeOrders': activeOrders,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static DateTime _parseDate(dynamic dateString) {
    if (dateString == null) return DateTime.now();
    try {
      return DateTime.parse(dateString).toLocal();
    } catch (e) {
      return DateTime.now();
    }
  }
}
