import 'package:flutter/material.dart';
import '../../features/tables/data/models/table_model.dart';
import 'status_badge.dart';

class TableCard extends StatelessWidget {
  final TableModel table;
  final VoidCallback onTap;

  const TableCard({
    super.key,
    required this.table,
    required this.onTap,
  });

  String _getInitials(String section) {
    return section
        .trim()
        .split(" ")
        .where((word) => word.isNotEmpty)
        .take(3)
        .map((word) => word[0].toUpperCase())
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Status specific styling
    Color cardColor;
    Color iconColor;
    
    switch (table.status.toLowerCase()) {
      case 'occupied':
        cardColor = Colors.red.withValues(alpha: 0.05);
        iconColor = Colors.red;
        break;
      case 'reserved':
        cardColor = Colors.amber.withValues(alpha: 0.05);
        iconColor = Colors.amber;
        break;
      case 'maintenance':
        cardColor = Colors.grey.withValues(alpha: 0.05);
        iconColor = Colors.grey;
        break;
      case 'available':
      default:
        cardColor = Colors.green.withValues(alpha: 0.05);
        iconColor = Colors.green;
        break;
    }

    if (theme.brightness == Brightness.dark) {
      cardColor = cardColor.withValues(alpha: 0.15);
    }

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: iconColor.withValues(alpha: 0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getInitials(table.section)}-${table.tableNumber}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    table.status == 'occupied' 
                        ? Icons.people 
                        : Icons.table_restaurant,
                    color: iconColor,
                  ),
                ],
              ),
              const Spacer(),
              StatusBadge(status: table.status, type: StatusType.table),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${table.occupiedSeats}/${table.capacity}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                   ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        table.section,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
