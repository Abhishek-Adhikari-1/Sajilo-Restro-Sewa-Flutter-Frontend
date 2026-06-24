class BillingHistoryItemModel {
  final String id;
  final String orderId;
  final String? tableId;
  final int? tableNumber;
  final String? tableSection;
  final String? customerId;
  final double subtotal;
  final double totalAmount;
  final String method;
  final String status;
  final String? discountType;
  final double? discountValue;
  final String? taxType;
  final double? taxValue;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdByName;
  final String? createdByImage;

  BillingHistoryItemModel({
    required this.id,
    required this.orderId,
    this.tableId,
    this.tableNumber,
    this.tableSection,
    this.customerId,
    required this.subtotal,
    required this.totalAmount,
    required this.method,
    required this.status,
    this.discountType,
    this.discountValue,
    this.taxType,
    this.taxValue,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdByName,
    this.createdByImage,
  });

  factory BillingHistoryItemModel.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>? ?? {};

    return BillingHistoryItemModel(
      id: payment['id']?.toString() ?? '',
      orderId: payment['orderId']?.toString() ?? '',
      tableId: payment['tableId']?.toString() ?? json['table_id']?.toString(),
      tableNumber: (payment['tableNumber'] as num?)?.toInt() ?? (json['table_number'] as num?)?.toInt(),
      tableSection: payment['tableSection']?.toString() ?? json['table_section']?.toString(),
      customerId: payment['customerId']?.toString(),
      subtotal: (payment['subtotal'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (payment['totalAmount'] as num?)?.toDouble() ?? 0.0,
      method: payment['method']?.toString() ?? '',
      status: payment['status']?.toString() ?? '',
      discountType: payment['discountType']?.toString(),
      discountValue: (payment['discountValue'] as num?)?.toDouble(),
      taxType: payment['taxType']?.toString(),
      taxValue: (payment['taxValue'] as num?)?.toDouble(),
      notes: payment['notes']?.toString(),
      createdAt: payment['createdAt'] != null 
          ? DateTime.parse(payment['createdAt'].toString()).toLocal() 
          : DateTime.now(),
      updatedAt: payment['updatedAt'] != null 
          ? DateTime.parse(payment['updatedAt'].toString()).toLocal() 
          : DateTime.now(),
      createdByName: json['createdByName']?.toString(),
      createdByImage: json['createdByImage']?.toString(),
    );
  }
}

class BillingHistoryResponse {
  final List<BillingHistoryItemModel> items;
  final int total;

  BillingHistoryResponse({
    required this.items,
    required this.total,
  });

  factory BillingHistoryResponse.fromJson(Map<String, dynamic> json) {
    return BillingHistoryResponse(
      items: (json['data'] as List<dynamic>?)
              ?.map((e) => BillingHistoryItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}
