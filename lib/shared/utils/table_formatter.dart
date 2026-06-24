class TableFormatter {
  static String format(String? section, int? tableNumber, [String? tableId]) {
    final numberStr = tableNumber?.toString() ?? (tableId ?? 'Unknown').substring(0, 4);
    if (section != null && section.trim().isNotEmpty) {
      final initials = section
          .trim()
          .split(" ")
          .where((word) => word.isNotEmpty)
          .take(3)
          .map((word) => word[0].toUpperCase())
          .join();
      return '$initials-$numberStr';
    }
    return 'T-$numberStr';
  }
}
