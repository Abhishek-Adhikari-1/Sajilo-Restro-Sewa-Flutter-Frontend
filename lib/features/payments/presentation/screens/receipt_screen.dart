import 'package:sajilo_restro_sewa/core/errors/app_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../orders/data/models/order_model.dart';

class ReceiptScreen extends StatelessWidget {
  final String customerName;
  final String customerPhone;
  final OrderModel order;
  // Passing calculated values from checkout
  final double subtotal;
  final double discountValue;
  final String discountType;
  final double taxValue;
  final String taxType;
  final double total;
  final String method;

  const ReceiptScreen({
    super.key,
    required this.customerName,
    required this.customerPhone,
    required this.order,
    this.subtotal = 0,
    this.discountValue = 0,
    this.discountType = 'fixed',
    this.taxValue = 0,
    this.taxType = 'percentage',
    this.total = 0,
    this.method = 'cash',
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final tableNumberStr = (order.tableNumber ?? order.tableId).toString();
    final shortTableNumber = tableNumberStr.length > 4 ? tableNumberStr.substring(0, 4) : tableNumberStr;

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('Receipt'),
        centerTitle: true,
        automaticallyImplyLeading: false, // User must press "Done"
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                // Header
                const Icon(Icons.restaurant, size: 48, color: Colors.black),
                const SizedBox(height: 8),
                Text(
                  const String.fromEnvironment('RESTRO_NAME', defaultValue: 'SAJILO RESTRO SEWA').toUpperCase(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  String.fromEnvironment('RESTRO_LOCATION', defaultValue: 'Kathmandu, Nepal'),
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                _buildDashedLine(),
                const SizedBox(height: 16),
                // Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      _buildInfoRow('Receipt No:', order.id.substring(0, 8).toUpperCase()),
                      _buildInfoRow('Date:', dateFormat.format(DateTime.now())),
                      _buildInfoRow('Table:', shortTableNumber),
                      if (customerName != 'Anonymous' && customerName != 'N/A' && customerName.isNotEmpty)
                        _buildInfoRow('Customer:', customerName),
                      if (customerPhone.isNotEmpty && customerPhone != 'N/A')
                        _buildInfoRow('Phone:', customerPhone),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildDashedLine(),
                const SizedBox(height: 16),
                // Items
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: order.items.map((item) {
                      if (item.status == 'cancelled') return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item.quantity}x ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                            Expanded(child: Text(item.name, style: const TextStyle(color: Colors.black))),
                            Text(currencyFormat.format(item.price * item.quantity), style: const TextStyle(color: Colors.black)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDashedLine(),
                const SizedBox(height: 16),
                // Totals
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      _buildInfoRow('Subtotal:', currencyFormat.format(subtotal > 0 ? subtotal : order.totalAmount)),
                      if (discountValue > 0)
                        _buildInfoRow(
                          'Discount (${discountType == 'percentage' ? '$discountValue%' : 'fixed'}):',
                          '-${currencyFormat.format(_getDiscountAmount())}',
                        ),
                      if (taxValue > 0)
                        _buildInfoRow(
                          'Tax (${taxType == 'percentage' ? '$taxValue%' : 'fixed'}):',
                          '+${currencyFormat.format(_getTaxAmount())}',
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                          Text(
                            currencyFormat.format(total > 0 ? total : order.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Payment Method:', method.toUpperCase()),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildDashedLine(),
                const SizedBox(height: 24),
                // Footer
                const Text('Thank you for dining with us!', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppErrorHandler.show(context, 'Printing receipt...');
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Print Receipt'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    // Pop until we reach the cashier shell (root)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getDiscountAmount() {
    if (discountType == 'fixed') return discountValue;
    return subtotal * (discountValue / 100);
  }

  double _getTaxAmount() {
    final sub = subtotal - _getDiscountAmount();
    if (taxType == 'fixed') return taxValue;
    return sub * (taxValue / 100);
  }

  Widget _buildDashedLine() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 5.0;
          const dashHeight = 1.0;
          final dashCount = (boxWidth / (2 * dashWidth)).floor();
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return const SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(decoration: BoxDecoration(color: Colors.black26)),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }
}
