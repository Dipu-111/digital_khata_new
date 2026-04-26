import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:digital_khata_new/models/customer.dart';
import 'package:digital_khata_new/models/transaction.dart';

class PdfReceiptService {
  
  // ==================== PRINT ALL CUSTOMERS SUMMARY ====================
  
  static Future<void> printAllCustomersSummary({
    required List<Customer> customers,
    required Function(String) getCustomerBalance,
    required String shopName,
    required String ownerName,
    required String shopPhone,
  }) async {
    final pdf = pw.Document();
    
    // Calculate totals
    double totalPending = 0;
    List<Map<String, dynamic>> customerData = [];
    
    for (var customer in customers) {
      final balance = getCustomerBalance(customer.id);
      customerData.add({
        'name': customer.name,
        'phone': customer.phone,
        'address': customer.address,
        'balance': balance,
      });
      if (balance > 0) {
        totalPending += balance;
      }
    }
    
    // Sort by balance (highest first)
    customerData.sort((a, b) => (b['balance'] as double).compareTo(a['balance'] as double));
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      shopName,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(ownerName, style: pw.TextStyle(fontSize: 12)),
                    pw.Text('📞 $shopPhone', style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 8),
                    pw.Divider(),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 16),
              
              // Title
              pw.Center(
                child: pw.Text(
                  'CUSTOMERS SUMMARY REPORT',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Summary Card
              pw.Container(
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Pending Credit:',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'रु ${totalPending.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: totalPending > 0 ? PdfColors.red : PdfColors.green,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Customers Table Title
              pw.Text(
                'Customers List:',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              
              // Table Header
              pw.Container(
                padding: pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border.all(),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text('Customer Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('Phone', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('Pending Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, ),textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
              ),
              
              // Table Rows
              ...customerData.map((customer) {
                final balance = customer['balance'] as double;
                return pw.Container(
                  padding: pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(customer['name']),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(customer['phone']),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'रु ${balance.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                            color: balance > 0 ? PdfColors.red : PdfColors.green,
                           
                          ), textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              
              pw.SizedBox(height: 20),
              
              // Footer
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Digital Khata',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );
    
    // Save and share
    final directory = await getTemporaryDirectory();
    final fileName = 'customers_summary_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Customers Summary Report - $shopName',
    );
  }
  
  // ==================== PRINT SINGLE CUSTOMER STATEMENT ====================
  
  static Future<void> printCustomerStatement({
    required Customer customer,
    required List<Transaction> transactions,
    required double balance,
    required String shopName,
    required String ownerName,
    required String shopPhone,
  }) async {
    final pdf = pw.Document();
    
    // Sort transactions by date (oldest first)
    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      shopName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(ownerName, style: pw.TextStyle(fontSize: 12)),
                    pw.Text('📞 $shopPhone', style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 8),
                    pw.Divider(),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 16),
              
              // Title
              pw.Center(
                child: pw.Text(
                  'CUSTOMER STATEMENT',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Customer Info
              pw.Container(
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('Customer Name: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(customer.name),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text('Phone: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(customer.phone),
                      ],
                    ),
                    if (customer.address.isNotEmpty)
                      pw.Row(
                        children: [
                          pw.Text('Address: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(customer.address),
                        ],
                      ),
                    pw.SizedBox(height: 8),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Current Balance:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          'रु ${balance.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: balance > 0 ? PdfColors.red : PdfColors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Transactions Table Title
              pw.Text(
                'Transaction History:',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              
              // Table Header
              pw.Container(
                padding: pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border.all(),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, ),textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
              ),
              
              // Table Rows
              ...sortedTransactions.map((t) {
                return pw.Container(
                  padding: pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text('${t.date.day}/${t.date.month}/${t.date.year}'),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          t.type == 'credit' ? 'Credit' : 'Payment',
                          style: pw.TextStyle(
                            color: t.type == 'credit' ? PdfColors.red : PdfColors.green,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(t.description),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'रु ${t.amount.toStringAsFixed(0)}',
                          style: pw.TextStyle(),
                            textAlign: pw.TextAlign.right,
                          
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              
              pw.SizedBox(height: 20),
              
              // Footer
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Digital Khata',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );
    
    // Save and share
    final directory = await getTemporaryDirectory();
    final fileName = '${customer.name}_statement_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Customer Statement - ${customer.name}',
    );
  }
}