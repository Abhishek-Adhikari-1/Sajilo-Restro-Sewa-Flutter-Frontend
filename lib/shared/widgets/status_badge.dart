import 'package:flutter/material.dart';

enum StatusType { order, table, payment }

class StatusBadge extends StatelessWidget {
  final String status;
  final StatusType type;

  const StatusBadge({
    super.key,
    required this.status,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    
    switch (type) {
      case StatusType.order:
        switch (status.toLowerCase()) {
          case 'pending':
            backgroundColor = Colors.amber.withValues(alpha: 0.15);
            textColor = Colors.amber.shade900;
            break;
          case 'preparing':
            backgroundColor = Colors.blue.withValues(alpha: 0.15);
            textColor = Colors.blue.shade900;
            break;
          case 'ready':
            backgroundColor = Colors.green.withValues(alpha: 0.15);
            textColor = Colors.green.shade900;
            break;
          case 'served':
            backgroundColor = Colors.purple.withValues(alpha: 0.15);
            textColor = Colors.purple.shade900;
            break;
          case 'paid':
            backgroundColor = Colors.teal.withValues(alpha: 0.15);
            textColor = Colors.teal.shade900;
            break;
          case 'cancelled':
            backgroundColor = Colors.red.withValues(alpha: 0.15);
            textColor = Colors.red.shade900;
            break;
          default:
            backgroundColor = Colors.grey.withValues(alpha: 0.15);
            textColor = Colors.grey.shade900;
        }
        break;
      case StatusType.table:
        switch (status.toLowerCase()) {
          case 'available':
            backgroundColor = Colors.green.withValues(alpha: 0.15);
            textColor = Colors.green.shade900;
            break;
          case 'occupied':
            backgroundColor = Colors.red.withValues(alpha: 0.15);
            textColor = Colors.red.shade900;
            break;
          case 'reserved':
            backgroundColor = Colors.amber.withValues(alpha: 0.15);
            textColor = Colors.amber.shade900;
            break;
          case 'maintenance':
            backgroundColor = Colors.grey.withValues(alpha: 0.15);
            textColor = Colors.grey.shade900;
            break;
          default:
            backgroundColor = Colors.grey.withValues(alpha: 0.15);
            textColor = Colors.grey.shade900;
        }
        break;
      case StatusType.payment:
        switch (status.toLowerCase()) {
          case 'pending':
            backgroundColor = Colors.amber.withValues(alpha: 0.15);
            textColor = Colors.amber.shade900;
            break;
          case 'paid':
            backgroundColor = Colors.green.withValues(alpha: 0.15);
            textColor = Colors.green.shade900;
            break;
          case 'cancelled':
          case 'failed':
            backgroundColor = Colors.red.withValues(alpha: 0.15);
            textColor = Colors.red.shade900;
            break;
          default:
            backgroundColor = Colors.grey.withValues(alpha: 0.15);
            textColor = Colors.grey.shade900;
        }
        break;
    }

    // In dark mode, adjust text color to be more readable
    if (Theme.of(context).brightness == Brightness.dark) {
      textColor = _lighten(textColor);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _lighten(Color color, [double amount = .2]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}
