import 'package:equatable/equatable.dart';

class ExpenseModel extends Equatable {
  final String id;
  final String description;
  final double amount;
  final String category;
  final String? notes;
  final DateTime date;
  final String? createdBy;
  final DateTime createdAt;

  const ExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    this.notes,
    required this.date,
    this.createdBy,
    required this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      description: json['description'],
      amount: double.parse(json['amount'].toString()),
      category: json['category'],
      notes: json['notes'],
      date: DateTime.parse(json['date']),
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'category': category,
      'notes': notes,
      'date': date.toIso8601String(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        description,
        amount,
        category,
        notes,
        date,
        createdBy,
        createdAt,
      ];
}
