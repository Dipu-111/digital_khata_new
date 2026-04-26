import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 1)
class Customer {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String name;
  
  @HiveField(3)
  final String phone;
  
  @HiveField(4)
  final String address;
  
  @HiveField(5)
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.address,
    required this.createdAt,
  });
}