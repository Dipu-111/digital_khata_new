import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_khata_new/providers/auth_provider.dart';
import 'package:digital_khata_new/providers/customer_provider.dart';
import 'package:digital_khata_new/providers/transaction_provider.dart';
import 'package:digital_khata_new/providers/theme_provider.dart';
import 'package:digital_khata_new/services/biometric_service.dart';
import 'package:digital_khata_new/services/export_service.dart';
import 'package:digital_khata_new/services/backup_service.dart';
import 'package:digital_khata_new/screens/login_screen.dart';

class CustomDrawer extends ConsumerStatefulWidget {
  final void Function(int)? onMenuItemSelected;

  const CustomDrawer({
    super.key,
    this.onMenuItemSelected, // 👈 Now optional
  });

  @override
  ConsumerState<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends ConsumerState<CustomDrawer> {
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    Navigator.pop(context);
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
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    return Drawer(
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
                    child: const Icon(Icons.store, size: 40, color: Colors.white),
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
                  if (widget.onMenuItemSelected != null) {
                    widget.onMenuItemSelected!(0);
                  }
                  Navigator.pop(context);
                }),
                _buildDrawerItem(Icons.people, 'Customers', () {
                  if (widget.onMenuItemSelected != null) {
                    widget.onMenuItemSelected!(0);
                  }
                  Navigator.pop(context);
                }),
                _buildDrawerItem(Icons.bar_chart, 'Reports', () {
                  if (widget.onMenuItemSelected != null) {
                    widget.onMenuItemSelected!(1);
                  }
                  Navigator.pop(context);
                }),
                _buildDrawerItem(Icons.notifications, 'Reminders', () {
                  if (widget.onMenuItemSelected != null) {
                    widget.onMenuItemSelected!(2);
                  }
                  Navigator.pop(context);
                }),
                const Divider(color: Color(0xFFE5E7EB)),
                _buildDrawerItem(Icons.cloud, 'Backup Data', () {
                  _backupData();
                }),
                _buildDrawerItem(Icons.file_download, 'Export Excel', () {
                  _exportData();
                }),
                _buildDrawerItem(Icons.dark_mode, 'Dark Mode', () {
                  ref.read(themeProvider.notifier).toggleTheme();
                  Navigator.pop(context);
                  
                }),
                _buildDrawerItem(Icons.help, 'Help & Support', () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help & Support coming soon')),
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
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap,
      {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : const Color(0xFF6B7280)),
      title: Text(
        title,
        style: TextStyle(color: isLogout ? Colors.red : const Color(0xFF1D293D)),
      ),
      onTap: onTap,
    );
  }
}