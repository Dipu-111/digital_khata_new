import 'package:digital_khata_new/models/customer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_khata_new/providers/customer_provider.dart';
import 'package:digital_khata_new/providers/transaction_provider.dart';
import 'package:digital_khata_new/providers/theme_provider.dart';
import 'package:digital_khata_new/widgets/custom_drawer.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  String _selectedTab = 'All'; // All, Overdue, Upcoming

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerProvider);
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    // Build reminder items based on customer data
    final reminderItems = _buildReminderItems(customers);
    
    // Filter based on selected tab
    final filteredItems = _filterReminders(reminderItems, _selectedTab);
    
    // Count pending reminders (customers with due amount > 0)
    final pendingCount = reminderItems.where((item) => item['isOverdue'] == true || item['daysLeft'] <= 7).length;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      drawer: const CustomDrawer(
        onMenuItemSelected: null,
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reminders',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF1D293D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            onPressed: () {
              // Filter functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Summary Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pending Reminders',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$pendingCount customers',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D293D),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFF1D293D),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterTab('All', isDarkMode),
                const SizedBox(width: 8),
                _buildFilterTab('Overdue', isDarkMode),
                const SizedBox(width: 8),
                _buildFilterTab('Upcoming', isDarkMode),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Reminder List
          Expanded(
            child: filteredItems.isEmpty
                ? _buildEmptyState(isDarkMode)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) => const Divider(color: Color(0xFFE5E7EB), height: 1),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _buildReminderItem(item, isDarkMode);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add reminder manually coming soon')),
          );
        },
        backgroundColor: const Color(0xFF1D293D),
        elevation: 6,
        child: const Icon(Icons.add_alert_outlined, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterTab(String title, bool isDarkMode) {
    final isActive = _selectedTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF1D293D)
                : (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF5F7FA)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.white : const Color(0xFF1D293D),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _buildReminderItems(List<Customer> customers) {
    final items = <Map<String, dynamic>>[];
    
    for (var customer in customers) {
      final balance = ref.read(transactionProvider.notifier).getCustomerBalance(customer.id);
      
      if (balance > 0) {
        // Get last transaction date
        final transactions = ref.read(transactionProvider)
            .where((t) => t.customerId == customer.id)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        
        final lastTransactionDate = transactions.isNotEmpty ? transactions.first.date : null;
        
        // Calculate days since last transaction
        int daysSinceLast = 999;
        if (lastTransactionDate != null) {
          daysSinceLast = DateTime.now().difference(lastTransactionDate).inDays;
        }
        
        final isOverdue = daysSinceLast > 30;
        final daysLeft = daysSinceLast > 30 ? 0 : 30 - daysSinceLast;
        
        items.add({
          'customer': customer,
          'balance': balance,
          'daysSinceLast': daysSinceLast,
          'isOverdue': isOverdue,
          'daysLeft': daysLeft,
          'lastTransactionDate': lastTransactionDate,
        });
      }
    }
    
    // Sort by urgency (overdue first, then by days left)
    items.sort((a, b) {
      if (a['isOverdue'] && !b['isOverdue']) return -1;
      if (!a['isOverdue'] && b['isOverdue']) return 1;
      return a['daysLeft'].compareTo(b['daysLeft']);
    });
    
    return items;
  }

  List<Map<String, dynamic>> _filterReminders(List<Map<String, dynamic>> items, String tab) {
    if (tab == 'All') return items;
    if (tab == 'Overdue') return items.where((item) => item['isOverdue'] == true).toList();
    if (tab == 'Upcoming') return items.where((item) => item['isOverdue'] == false && item['daysLeft'] <= 7).toList();
    return items;
  }

  Widget _buildReminderItem(Map<String, dynamic> item, bool isDarkMode) {
    final customer = item['customer'] as Customer;
    final balance = item['balance'] as double;
    final daysSinceLast = item['daysSinceLast'] as int;
    final isOverdue = item['isOverdue'] as bool;
    final daysLeft = item['daysLeft'] as int;

    String statusText;
    Color statusColor;
    
    if (isOverdue) {
      statusText = 'Overdue';
      statusColor = const Color(0xFFDC2626);
    } else if (daysLeft == 0) {
      statusText = 'Today';
      statusColor = const Color(0xFF1D293D);
    } else if (daysLeft == 1) {
      statusText = 'Tomorrow';
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusText = 'In $daysLeft days';
      statusColor = const Color(0xFFF59E0B);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFF5F7FA),
            child: Text(
              customer.name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D293D),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Customer Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDarkMode ? Colors.white : const Color(0xFF1D293D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Due: रु ${balance.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFDC2626),
                  ),
                ),
                Text(
                  'Last transaction: $daysSinceLast days ago',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.grey.shade500 : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          // Status and Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  _sendReminder(customer, balance);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.notifications_none, size: 12, color: Color(0xFF1D293D)),
                      SizedBox(width: 4),
                      Text(
                        'Remind',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1D293D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendReminder(Customer customer, double balance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Send Reminder'),
        content: Text('Send payment reminder to ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reminder sent to ${customer.name}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D293D),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 64,
            color: isDarkMode ? Colors.grey.shade600 : const Color(0xFF6B7280),
          ),
          const SizedBox(height: 16),
          Text(
            'No reminders yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF1D293D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add customers with pending dues\nto see reminders here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.grey.shade500 : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}