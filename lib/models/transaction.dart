import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 2)
class Transaction {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String customerId;
  
  @HiveField(3)
  final String type; // 'credit' or 'payment'
  
  @HiveField(4)
  final double amount;
  
  @HiveField(5)
  final String description;
  
  @HiveField(6)
  final DateTime date;
  
  @HiveField(7)
  final DateTime? updatedAt; // For edit tracking

  Transaction({
    required this.id,
    required this.userId,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.updatedAt,
  });
  
  // Copy method for editing
  Transaction copyWith({
    String? id,
    String? userId,
    String? customerId,
    String? type,
    double? amount,
    String? description,
    DateTime? date,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}