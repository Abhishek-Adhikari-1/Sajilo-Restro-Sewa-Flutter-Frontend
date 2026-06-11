import 'package:flutter/material.dart';

class CustomFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const CustomFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          // color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
    );
    
    // return AnimatedContainer(
    //   duration: const Duration(milliseconds: 200),
    //   margin: const EdgeInsets.only(right: 8.0),
    //   child: Material(
    //     color: Colors.transparent,
    //     child: InkWell(
    //       borderRadius: BorderRadius.circular(20),
    //       onTap: () => onSelected(!isSelected),
    //       child: Container(
    //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    //         decoration: BoxDecoration(
    //           gradient: isSelected
    //               ? LinearGradient(
    //                   colors: [
    //                     theme.colorScheme.primary,
    //                     theme.colorScheme.primary.withValues(alpha: 0.8),
    //                   ],
    //                   begin: Alignment.topLeft,
    //                   end: Alignment.bottomRight,
    //                 )
    //               : null,
    //           color: isSelected ? null : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
    //           borderRadius: BorderRadius.circular(20),
    //           border: Border.all(
    //             color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.2),
    //             width: 1,
    //           ),
    //           boxShadow: isSelected
    //               ? [
    //                   BoxShadow(
    //                     color: theme.colorScheme.primary.withValues(alpha: 0.3),
    //                     blurRadius: 8,
    //                     offset: const Offset(0, 4),
    //                   )
    //                 ]
    //               : [],
    //         ),
    //         child: Text(
    //           label,
    //           style: theme.textTheme.labelLarge?.copyWith(
    //             color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
    //             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
    //           ),
    //         ),
    //       ),
    //     ),
    //   ),
    // );
  }
}
