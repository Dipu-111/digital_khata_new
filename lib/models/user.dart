import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String shopName;
  
  @HiveField(2)
  final String ownerName;
  
  @HiveField(3)
  final String phone;
  
  @HiveField(4)
  final String password;
  
  @HiveField(5)
  final DateTime createdAt;

  User({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.phone,
    required this.password,
    required this.createdAt,
  });
}