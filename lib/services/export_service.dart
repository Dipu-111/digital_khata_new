import 'dart:io';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:digital_khata_new/models/customer.dart';
import 'package:digital_khata_new/models/transaction.dart';
import 'package:path_provider/path_provider.dart';

class ExportService {
  static Future<void> exportToCSV({
    required List<Customer> customers,
    required List<Transaction> transactions,
    required String shopName,
  }) async {
    // Prepare customers data
    List<List<String>> customersData = [
      ['Digital Khata Export'],
      ['Generated: ${DateTime.now().toLocal()}'],
      ['Shop: $shopName'],
      [''],
      ['CUSTOMERS LIST'],
      ['Name', 'Phone', 'Address', 'Created Date']
    ];
    
    for (var c in customers) {
      customersData.add([
        c.name,
        c.phone,
        c.address,
        '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}',
      ]);
    }
    
    // Prepare transactions data
    List<List<String>> transactionsData = [
      [''],
      ['TRANSACTIONS LIST'],
      ['Date', 'Customer', 'Type', 'Amount', 'Description']
    ];
    
    for (var t in transactions) {
      final customer = customers.firstWhere(
        (c) => c.id == t.customerId,
        orElse: () => Customer(id: '', userId: '', name: 'Unknown', phone: '', address: '', createdAt: DateTime.now()),
      );
      transactionsData.add([
        '${t.date.day}/${t.date.month}/${t.date.year}',
        customer.name,
        t.type == 'credit' ? 'Credit (Given)' : 'Payment (Received)',
        'रु ${t.amount.toStringAsFixed(0)}',
        t.description,
      ]);
    }
    
    // Combine data
    final allData = [...customersData, ...transactionsData];
    
    // Convert to CSV
    String csv = const ListToCsvConverter().convert(allData);
    
    // Save to temporary file
    final directory = await getTemporaryDirectory();
    final fileName = 'khata_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final filePath = '${directory.path}/$fileName';
    File file = File(filePath);
    await file.writeAsString(csv);
    
    // Share file
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Digital Khata Export - $shopName',
    );
  }
}