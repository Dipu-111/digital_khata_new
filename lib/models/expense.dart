import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 3)
class Expense {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final double amount;
  
  @HiveField(3)
  final String category;
  
  @HiveField(4)
  final DateTime date;
  
  @HiveField(5)
  final String description;
  
  @HiveField(6)
  final String paymentMethod; // cash, card, upi
  
  @HiveField(7)
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
    required this.paymentMethod,
    required this.createdAt,
  });
}

@HiveType(typeId: 4)
class Budget {
  @HiveField(0)
  final String userId;
  
  @HiveField(1)
  final double monthlyLimit;
  
  @HiveField(2)
  final DateTime updatedAt;

  Budget({
    required this.userId,
    required this.monthlyLimit,
    required this.updatedAt,
  });
}