import 'package:digital_khata_new/models/customer.dart';
import 'package:digital_khata_new/models/transaction.dart';
import 'package:digital_khata_new/services/backup_service.dart';
import 'package:digital_khata_new/services/pdf_receipt_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_khata_new/providers/auth_provider.dart';
import 'package:digital_khata_new/providers/customer_provider.dart';
import 'package:digital_khata_new/providers/transaction_provider.dart';
import 'package:digital_khata_new/providers/theme_provider.dart';
import 'package:digital_khata_new/screens/customer_detail_screen.dart';
import 'package:digital_khata_new/screens/add_customer_screen.dart';
import 'package:digital_khata_new/screens/login_screen.dart';
import 'package:digital_khata_new/screens/reports_screen.dart';
import 'package:digital_khata_new/services/biometric_service.dart';
import 'package:digital_khata_new/services/export_service.dart';
import 'package:digital_khata_new/widgets/edit_customer_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Future<void> _printAllCustomersSummary() async {
    final user = ref.read(authProvider);
    final customers = ref.read(customerProvider);

    if (user == null) return;

    await PdfReceiptService.printAllCustomersSummary(
      customers: customers,
      getCustomerBalance: (customerId) {
        return ref
            .read(transactionProvider.notifier)
            .getCustomerBalance(customerId);
      },
      shopName: user.shopName,
      ownerName: user.ownerName,
      shopPhone: user.phone,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await BiometricService.clearCredentials();
                await BiometricService.clearLoginState();
                ref.read(authProvider.notifier).logout();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showCustomerOptions(Customer customer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF1D293D)),
              title: const Text('Edit Customer'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => EditCustomerDialog(customer: customer),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Customer',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteCustomerConfirmation(customer.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCustomerConfirmation(String customerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Customer'),
        content: const Text(
            'This will also delete all transactions for this customer. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(customerProvider.notifier)
                  .deleteCustomer(customerId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Customer deleted successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _backupData() async {
    final user = ref.read(authProvider);
    final customers = ref.read(customerProvider);
    final transactions = ref.read(transactionProvider);

    if (user == null) return;

    await BackupService.shareBackup(
      customers: customers,
      transactions: transactions,
      shopName: user.shopName,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup created and shared!')),
      );
    }
  }

  Future<void> _restoreData() async {
    try {
      // Pick backup file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return;

      final filePath = result.files.single.path!;
      final backupData = await BackupService.restoreBackup(filePath);

      if (backupData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid backup file')),
        );
        return;
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Restore Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'This will replace all current data with backup data.'),
              const SizedBox(height: 8),
              Text('Backup date: ${backupData['backupDate']}'),
              Text('Customers: ${(backupData['customers'] as List).length}'),
              Text(
                  'Transactions: ${(backupData['transactions'] as List).length}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Restore customers
      final customersList = (backupData['customers'] as List)
          .map((c) => Customer(
                id: c['id'],
                userId: c['userId'],
                name: c['name'],
                phone: c['phone'],
                address: c['address'],
                createdAt: DateTime.parse(c['createdAt']),
              ))
          .toList();

      // Restore transactions
      final transactionsList = (backupData['transactions'] as List)
          .map((t) => Transaction(
                id: t['id'],
                userId: t['userId'],
                customerId: t['customerId'],
                type: t['type'],
                amount: t['amount'].toDouble(),
                description: t['description'],
                date: DateTime.parse(t['date']),
                updatedAt: t['updatedAt'] != null
                    ? DateTime.parse(t['updatedAt'])
                    : null,
              ))
          .toList();

      await ref.read(customerProvider.notifier).restoreCustomers(customersList);
      await ref
          .read(transactionProvider.notifier)
          .restoreTransactions(transactionsList);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data restored successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final customers = ref.watch(customerProvider);
    final allTransactions = ref.watch(transactionProvider);
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    final filteredCustomers = _searchQuery.isEmpty
        ? customers
        : customers
            .where((c) =>
                c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                c.phone.contains(_searchQuery))
            .toList();

    double totalCredit = 0;
    double totalPayment = 0;

    for (var t in allTransactions) {
      if (t.type == 'credit') {
        totalCredit += t.amount;
      } else if (t.type == 'payment') {
        totalPayment += t.amount;
      }
    }

    final netBalance = totalCredit - totalPayment;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Digital Khata'),
        backgroundColor: const Color(0xFF1D293D),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchQuery.isEmpty ? ' ' : '';
                if (_searchQuery.isNotEmpty) {
                  _searchController.clear();
                }
              });
            },
            icon: Icon(_searchQuery.isEmpty ? Icons.search : Icons.close),
          ),
          IconButton(
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            onPressed: () async {
              await ExportService.exportToCSV(
                customers: customers,
                transactions: allTransactions,
                shopName: user?.shopName ?? 'Digital Khata',
              );
            },
            icon: const Icon(Icons.file_download),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              // Drawer Header - Profile Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1D293D),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.store,
                        size: 35,
                        color: Color(0xFF1D293D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.shopName ?? 'Shop Name',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.ownerName ?? 'Owner Name',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.phone ?? 'Phone Number',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Drawer Items
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                tileColor: _currentIndex == 0 ? Colors.grey.shade100 : null,
                onTap: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Customers'),
                tileColor: _currentIndex == 0 ? Colors.grey.shade100 : null,
                onTap: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Reports'),
                tileColor: _currentIndex == 1 ? Colors.grey.shade100 : null,
                onTap: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).toggleTheme();
                    Navigator.pop(context);
                  },
                  activeColor: const Color(0xFF1D293D),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.print, color: Color(0xFF1D293D)),
                title: const Text('Print Summary Report'),
                onTap: () {
                  Navigator.pop(context);
                  _printAllCustomersSummary();
                },
              ),
              ListTile(
                leading: const Icon(Icons.backup, color: Color(0xFF1D293D)),
                title: const Text('Backup Data'),
                onTap: () {
                  Navigator.pop(context);
                  _backupData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore, color: Color(0xFF1D293D)),
                title: const Text('Restore Data'),
                onTap: () {
                  Navigator.pop(context);
                  _restoreData();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog();
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildCustomerListTab(filteredCustomers),
          ReportsScreen(
            totalCredit: totalCredit,
            totalPayment: totalPayment,
            netBalance: netBalance,
            transactions: allTransactions,
            customers: customers,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        selectedItemColor: const Color(0xFF1D293D),
        unselectedItemColor: Colors.grey.shade500,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
                );
              },
              backgroundColor: const Color(0xFF1D293D),
              elevation: 8,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildCustomerListTab(List<Customer> customers) {
    final totalDue = ref.read(transactionProvider.notifier).getTotalDue();
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    return Column(
      children: [
        // Small Total Due Card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: totalDue > 0 ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: totalDue > 0 ? Colors.red.shade200 : Colors.green.shade200,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Due Amount:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                'रु ${totalDue.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: totalDue > 0
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
        // Customer List Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Customers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${customers.length} customers',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Customer List
        Expanded(
          child: customers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No customers added yet'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    final balance = ref
                        .read(transactionProvider.notifier)
                        .getCustomerBalance(customer.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustomerDetailScreen(customer: customer),
                            ),
                          );
                        },
                        onLongPress: () {
                          _showCustomerOptions(customer);
                        },
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: balance > 0
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          child: Text(
                            customer.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: balance > 0
                                  ? Colors.red.shade600
                                  : Colors.green.shade600,
                            ),
                          ),
                        ),
                        title: Text(
                          customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          customer.phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        trailing: Text(
                          'रु ${balance.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: balance > 0
                                ? Colors.red.shade600
                                : Colors.green.shade600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
