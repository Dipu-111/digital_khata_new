import 'package:digital_khata_new/providers/customer_provider.dart';
import 'package:digital_khata_new/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_khata_new/providers/auth_provider.dart';
import 'package:digital_khata_new/providers/theme_provider.dart';
import 'package:digital_khata_new/services/biometric_service.dart';
import 'package:digital_khata_new/services/export_service.dart';
import 'package:digital_khata_new/services/backup_service.dart';
import 'package:digital_khata_new/screens/login_screen.dart';
import 'package:digital_khata_new/widgets/custom_drawer.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
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
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text(
          'More',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF1D293D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Profile Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFF5F7FA),
                    child: const Icon(
                      Icons.store,
                      size: 30,
                      color: Color(0xFF1D293D),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.shopName ?? 'Shop Name',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1D293D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.ownerName ?? 'Owner Name',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode
                                ? Colors.grey.shade400
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.phone ?? 'Phone Number',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.grey.shade500
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // App Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'APP SETTINGS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? Colors.grey.shade400
                      : const Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: 'Switch between light and dark theme',
                    isDarkMode: isDarkMode,
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (value) {
                        ref.read(themeProvider.notifier).toggleTheme();
                      },
                      activeThumbColor: const Color(0xFF1D293D),
                    ),
                  ),
                  const Divider(color: Color(0xFFE5E7EB), height: 1),
                  _buildMenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Enable payment reminders',
                    isDarkMode: isDarkMode,
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {},
                      activeColor: const Color(0xFF1D293D),
                    ),
                  ),
                  const Divider(color: Color(0xFFE5E7EB), height: 1),
                  _buildMenuItem(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: 'English / नेपाली',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Language support coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Data Management Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'DATA MANAGEMENT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? Colors.grey.shade400
                      : const Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.backup_outlined,
                    title: 'Backup Data',
                    subtitle: 'Save your data to device',
                    isDarkMode: isDarkMode,
                    onTap: _backupData,
                  ),
                  const Divider(color: Color(0xFFE5E7EB), height: 1),
                  _buildMenuItem(
                    icon: Icons.restore_outlined,
                    title: 'Restore Data',
                    subtitle: 'Restore from backup file',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Restore feature coming soon')),
                      );
                    },
                  ),
                  const Divider(color: Color(0xFFE5E7EB), height: 1),
                  _buildMenuItem(
                    icon: Icons.file_download_outlined,
                    title: 'Export to Excel',
                    subtitle: 'Export customers and transactions',
                    isDarkMode: isDarkMode,
                    onTap: _exportData,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Support Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'SUPPORT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? Colors.grey.shade400
                      : const Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'FAQs, tutorials, contact us',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Help & Support coming soon')),
                      );
                    },
                  ),
                  const Divider(color: Color(0xFFE5E7EB), height: 1),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'Version 1.0.0',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      _showAboutDialog();
                    },
                  ),
                  const Divider(color: Color(0xFFE5E7EB), height: 1),
                  _buildMenuItem(
                    icon: Icons.share_outlined,
                    title: 'Share App',
                    subtitle: 'Share Digital Khata with others',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Share feature coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Logout Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                onTap: _showLogoutDialog,
              ),
            ),

            const SizedBox(height: 30),

            // Version Text
            Center(
              child: Text(
                'Digital Khata v1.0.0',
                style: TextStyle(
                  fontSize: 11,
                  color: isDarkMode
                      ? Colors.grey.shade600
                      : const Color(0xFF6B7280),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6B7280), size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : const Color(0xFF1D293D),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.grey.shade500 : const Color(0xFF6B7280),
        ),
      ),
      trailing:
          trailing ?? const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
      onTap: onTap,
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About Digital Khata'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.store, size: 48, color: Color(0xFF1D293D)),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Digital Khata',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Version: 1.0.0',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              'A simple credit ledger app for small shopkeepers in Nepal.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('• Track customer credits and payments'),
            const Text('• Send WhatsApp reminders'),
            const Text('• Export data to Excel'),
            const Text('• Backup and restore data'),
            const Text('• Dark mode support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
