import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:digital_khata_new/models/customer.dart';
import 'package:digital_khata_new/models/transaction.dart';

class BackupService {
  
  // Backup all data to a JSON file
  static Future<String?> createBackup({
    required List<Customer> customers,
    required List<Transaction> transactions,
    required String shopName,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      
      if (!await backupDir.exists()) {
        await backupDir.create();
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'khata_backup_$timestamp.json';
      final filePath = '${backupDir.path}/$fileName';
      
      final backupData = {
        'shopName': shopName,
        'backupDate': DateTime.now().toIso8601String(),
        'customers': customers.map((c) => {
          'id': c.id,
          'userId': c.userId,
          'name': c.name,
          'phone': c.phone,
          'address': c.address,
          'createdAt': c.createdAt.toIso8601String(),
        }).toList(),
        'transactions': transactions.map((t) => {
          'id': t.id,
          'userId': t.userId,
          'customerId': t.customerId,
          'type': t.type,
          'amount': t.amount,
          'description': t.description,
          'date': t.date.toIso8601String(),
          'updatedAt': t.updatedAt?.toIso8601String(),
        }).toList(),
      };
      
      final jsonString = jsonEncode(backupData);
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      return filePath;
    } catch (e) {
      print('Backup error: $e');
      return null;
    }
  }
  
  // Share backup file
  static Future<void> shareBackup({
    required List<Customer> customers,
    required List<Transaction> transactions,
    required String shopName,
  }) async {
    final filePath = await createBackup(
      customers: customers,
      transactions: transactions,
      shopName: shopName,
    );
    
    if (filePath != null) {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Digital Khata Backup - $shopName',
      );
    }
  }
  
  // Get all backup files
  static Future<List<FileSystemEntity>> getBackupFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/backups');
    
    if (!await backupDir.exists()) {
      return [];
    }
    
    return await backupDir.list().toList();
  }
  
  // Restore from backup file
  static Future<Map<String, dynamic>?> restoreBackup(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Restore error: $e');
      return null;
    }
  }
  
  // Delete old backups (keep only last 5)
  static Future<void> cleanOldBackups() async {
    final files = await getBackupFiles();
    if (files.length <= 5) return;
    
    // Sort by last modified
    files.sort((a, b) {
      final aStat = File(a.path).statSync();
      final bStat = File(b.path).statSync();
      return bStat.modified.compareTo(aStat.modified);
    });
    
    // Delete files beyond 5
    for (int i = 5; i < files.length; i++) {
      await File(files[i].path).delete();
    }
  }
}