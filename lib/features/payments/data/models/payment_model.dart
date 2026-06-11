class PaymentRequestModel {
  final String orderId;
  final String method;
  final String? customerName;
  final String? customerPhone;
  final String? discountType;
  final double? discountValue;
  final String? taxType;
  final double? taxValue;
  final String? notes;

  PaymentRequestModel({
    required this.orderId,
    required this.method,
    this.customerName,
    this.customerPhone,
    this.discountType,
    this.discountValue,
    this.taxType,
    this.taxValue,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'order_id': orderId,
      'method': method,
    };
    
    if ((customerName != null && customerName!.isNotEmpty) || 
        (customerPhone != null && customerPhone!.isNotEmpty)) {
      data['customer'] = {
        if (customerName != null && customerName!.isNotEmpty) 'name': customerName,
        if (customerPhone != null && customerPhone!.isNotEmpty) 'phone': customerPhone,
      };
    }

    if (discountType != null && discountValue != null) {
      data['discount_type'] = discountType;
      data['discount_value'] = discountValue;
    }

    if (taxType != null && taxValue != null) {
      data['tax_type'] = taxType;
      data['tax_value'] = taxValue;
    }

    if (notes != null && notes!.isNotEmpty) {
      data['notes'] = notes;
    }
    
    return data;
  }
}
