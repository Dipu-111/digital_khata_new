import 'package:digital_khata_new/screens/more_screen.dart';
import 'package:digital_khata_new/screens/remainders_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_khata_new/providers/auth_provider.dart';
import 'package:digital_khata_new/providers/customer_provider.dart';
import 'package:digital_khata_new/providers/transaction_provider.dart';
import 'package:digital_khata_new/providers/theme_provider.dart';
import 'package:digital_khata_new/screens/add_customer_screen.dart';
import 'package:digital_khata_new/screens/customer_detail_screen.dart';
import 'package:digital_khata_new/screens/login_screen.dart';
import 'package:digital_khata_new/screens/reports_screen.dart';
import 'package:digital_khata_new/services/biometric_service.dart';
import 'package:digital_khata_new/services/export_service.dart';
import 'package:digital_khata_new/services/backup_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _backupData() async {
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
        const SnackBar(content: Text('Backup created!')),
      );
    }
  }

  void _exportData() async {
    final user = ref.read(authProvider);
    final customers = ref.read(customerProvider);
    final transactions = ref.read(transactionProvider);

    if (user == null) return;

    await ExportService.exportToCSV(
      customers: customers,
      transactions: transactions,
      shopName: user.shopName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final customers = ref.watch(customerProvider);
    final allTransactions = ref.watch(transactionProvider);
    final totalDue = ref.watch(transactionProvider.notifier).getTotalDue();
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    // Calculate totals for ReportsScreen
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

    final filteredCustomers = _searchQuery.isEmpty
        ? customers
        : customers
            .where((c) =>
                c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                c.phone.contains(_searchQuery))
            .toList();

    final List<Widget> _screens = [
      _buildHomeContent(user, filteredCustomers, totalDue, isDarkMode),
      ReportsScreen(
        totalCredit: totalCredit,
        totalPayment: totalPayment,
        netBalance: netBalance,
        transactions: allTransactions,
        customers: customers,
      ),
      const RemindersScreen(),
      const MoreScreen(),
    ];

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        selectedItemColor: const Color(0xFF1D293D),
        unselectedItemColor: const Color(0xFF6B7280),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            activeIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      drawer: Drawer(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              height: 160,
              decoration: const BoxDecoration(color: Color(0xFF1D293D)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.store,
                          size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.shopName ?? 'Digital Khata',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Digital Khata',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            // Drawer Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(Icons.home, 'Home', () {
                    setState(() => _currentIndex = 0);
                    Navigator.pop(context);
                  }),
                  _buildDrawerItem(Icons.people, 'Customers', () {
                    setState(() => _currentIndex = 0);
                    Navigator.pop(context);
                  }),
                  _buildDrawerItem(Icons.bar_chart, 'Reports', () {
                    setState(() => _currentIndex = 1);
                    Navigator.pop(context);
                  }),
                  _buildDrawerItem(Icons.notifications, 'Reminders', () {
                    setState(() => _currentIndex = 2);
                    Navigator.pop(context);
                  }),
                  const Divider(color: Color(0xFFE5E7EB)),
                  _buildDrawerItem(Icons.cloud, 'Backup Data', () {
                    Navigator.pop(context);
                    _backupData();
                  }),
                  _buildDrawerItem(Icons.file_download, 'Export Excel', () {
                    Navigator.pop(context);
                    _exportData();
                  }),
                  _buildDrawerItem(Icons.dark_mode, 'Dark Mode', () {
                    ref.read(themeProvider.notifier).toggleTheme();
                    Navigator.pop(context);
                  }),
                  _buildDrawerItem(Icons.help, 'Help & Support', () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Help & Support coming soon')),
                    );
                  }),
                  const Divider(color: Color(0xFFE5E7EB)),
                  _buildDrawerItem(Icons.logout, 'Logout', () {
                    Navigator.pop(context);
                    _showLogoutDialog();
                  }, isLogout: true),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
                ).then((_) {
                  setState(() {});
                });
              },
              backgroundColor: const Color(0xFF1D293D),
              elevation: 6,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap,
      {bool isLogout = false}) {
    return ListTile(
      leading:
          Icon(icon, color: isLogout ? Colors.red : const Color(0xFF6B7280)),
      title: Text(
        title,
        style:
            TextStyle(color: isLogout ? Colors.red : const Color(0xFF1D293D)),
      ),
      onTap: onTap,
    );
  }

  Widget _buildHomeContent(
      user, List customers, double totalDue, bool isDarkMode) {
    final filteredCustomers = _searchQuery.isEmpty
        ? customers
        : customers
            .where((c) =>
                c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                c.phone.contains(_searchQuery))
            .toList();

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        title: Text(
          user?.shopName ?? 'Digital Khata',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF1D293D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              height: 160,
              decoration: const BoxDecoration(color: Color(0xFF1D293D)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.store,
                          size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.shopName ?? 'Digital Khata',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Digital Khata',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            // Drawer Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(Icons.home, 'Home', () {
                    setState(() => _currentIndex = 0);
                    Navigator.pop(context);
                  }),
                  _buildDrawerItem(Icons.people, 'Customers', () {
                    setState(() => _currentIndex = 0);
                    Navigator.pop(context);
                  }),
                  _buildDrawerItem(Icons.bar_chart, 'Reports', () {
                    setState(() => _currentIndex = 1);
                    Navigator.pop(context);
                  }),
                  _buildDrawerItem(Icons.notifications, 'Reminders', () {
                    setState(() => _currentIndex = 2);
                    Navigator.pop(context);
                  }),
                  const Divider(color: Color(0xFFE5E7EB)),
                  _buildDrawerItem(Icons.cloud, 'Backup Data', () {
                    Navigator.pop(context);
                    _backupData();
                  }),
                  _buildDrawerItem(Icons.file_download, 'Export Excel', () {
                    Navigator.pop(context);
                    _exportData();
                  }),
                  _buildDrawerItem(Icons.dark_mode, 'Dark Mode', () {
                    ref.read(themeProvider.notifier).toggleTheme();
                    Navigator.pop(context);
                  }),
                  _buildDrawerItem(Icons.help, 'Help & Support', () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Help & Support coming soon')),
                    );
                  }),
                  const Divider(color: Color(0xFFE5E7EB)),
                  _buildDrawerItem(Icons.logout, 'Logout', () {
                    Navigator.pop(context);
                    _showLogoutDialog();
                  }, isLogout: true),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
          return Future.value();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                      color:
                          isDarkMode ? Colors.white : const Color(0xFF1D293D)),
                  decoration: InputDecoration(
                    hintText: 'Search customers...',
                    hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF6B7280)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

              const SizedBox(height: 16),

              // Total Due Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL PENDING (DUE)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'रु ${totalDue.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Customer List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Customers',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    '${filteredCustomers.length} customers',
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Customer List
              Expanded(
                child: filteredCustomers.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 48, color: Color(0xFF6B7280)),
                            SizedBox(height: 8),
                            Text('No customers found',
                                style: TextStyle(color: Color(0xFF6B7280))),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredCustomers.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Color(0xFFE5E7EB), height: 1),
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];
                          final balance = ref
                              .watch(transactionProvider.notifier)
                              .getCustomerBalance(customer.id);

                          return InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CustomerDetailScreen(customer: customer),
                                ),
                              );
                              setState(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFF5F7FA),
                                    radius: 22,
                                    child: Text(
                                      customer.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Color(0xFF1D293D),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          customer.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Color(0xFF1D293D),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          customer.phone,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'रु ${balance.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: balance > 0
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
