class SidePanelOrderModel {
  final String id;
  final String status;
  final int guestsCount;
  final String? notes;
  final String? tableNumber;
  final String? tableSection;
  final String? tableId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdByName;
  final String? createdByImage;
  final List<SidePanelOrderItem> items;

  SidePanelOrderModel({
    required this.id,
    required this.status,
    required this.guestsCount,
    this.notes,
    this.tableNumber,
    this.tableSection,
    this.tableId,
    required this.createdAt,
    required this.updatedAt,
    this.createdByName,
    this.createdByImage,
    required this.items,
  });

  factory SidePanelOrderModel.fromJson(Map<String, dynamic> json) {
    return SidePanelOrderModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      guestsCount: (json['guestsCount'] as num?)?.toInt() ?? 0,
      notes: json['notes']?.toString(),
      tableNumber: json['table']?['tableNumber']?.toString(),
      tableSection: json['table']?['section']?.toString(),
      tableId: json['table']?['id']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()).toLocal() : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'].toString()).toLocal() : DateTime.now(),
      createdByName: json['createdByUser'] != null ? '${json['createdByUser']['firstName']} ${json['createdByUser']['lastName']}' : null,
      createdByImage: json['createdByUser']?['avatar']?['secureUrl']?.toString() ?? json['createdByUser']?['avatar']?['url']?.toString(),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => SidePanelOrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SidePanelOrderItem {
  final int quantity;
  final double priceAtTime;
  final String menuName;
  final String status;
  final String? notes;

  SidePanelOrderItem({
    required this.quantity,
    required this.priceAtTime,
    required this.menuName,
    required this.status,
    this.notes,
  });

  factory SidePanelOrderItem.fromJson(Map<String, dynamic> json) {
    return SidePanelOrderItem(
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      priceAtTime: (json['priceAtTime'] as num?)?.toDouble() ?? 0.0,
      menuName: json['menu']?['name']?.toString() ?? 'Unknown',
      status: json['status']?.toString() ?? '',
      notes: json['notes']?.toString(),
    );
  }
}

class SidePanelCustomerModel {
  final String id;
  final String name;
  final String? phone;
  final DateTime createdAt;

  SidePanelCustomerModel({
    required this.id,
    required this.name,
    this.phone,
    required this.createdAt,
  });

  factory SidePanelCustomerModel.fromJson(Map<String, dynamic> json) {
    return SidePanelCustomerModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      phone: json['phone']?.toString(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString()).toLocal() 
          : DateTime.now(),
    );
  }
}
