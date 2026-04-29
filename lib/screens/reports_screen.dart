import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_khata_new/models/customer.dart';
import 'package:digital_khata_new/models/transaction.dart';
import 'package:digital_khata_new/providers/theme_provider.dart';
import 'package:digital_khata_new/widgets/custom_drawer.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  final double totalCredit;
  final double totalPayment;
  final double netBalance;
  final List<Transaction> transactions;
  final List<Customer> customers;

  const ReportsScreen({
    super.key,
    required this.totalCredit,
    required this.totalPayment,
    required this.netBalance,
    required this.transactions,
    required this.customers,
  });

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
      drawer: CustomDrawer(
        onMenuItemSelected: (index) {
          if (index == 0) {
            // Navigate to Home
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            // Already on Reports - just close drawer
            Navigator.pop(context);
          } else if (index == 2) {
            // Navigate to Reminders
            Navigator.pushReplacementNamed(context, '/reminders');
          }
        },
      ),
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF1D293D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          return Future.value();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              const Text(
                'Financial Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D293D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Summary of all your business transactions',
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode
                      ? Colors.grey.shade400
                      : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 20),

              // Stats Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Credit',
                      amount: widget.totalCredit,
                      color: const Color(0xFFDC2626),
                      icon: Icons.arrow_downward,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Payment',
                      amount: widget.totalPayment,
                      color: const Color(0xFF16A34A),
                      icon: Icons.arrow_upward,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Net Balance Card
              _buildNetBalanceCard(widget.netBalance, isDarkMode),
              const SizedBox(height: 24),

              // Recent Transactions Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          isDarkMode ? Colors.white : const Color(0xFF1D293D),
                    ),
                  ),
                  Text(
                    'Last 10 entries',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.grey.shade500
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Transaction List
              widget.transactions.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: isDarkMode
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No transactions yet',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.transactions.length > 10
                          ? 10
                          : widget.transactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final t = widget.transactions.reversed.toList()[index];
                        final customer = widget.customers.firstWhere(
                          (c) => c.id == t.customerId,
                          orElse: () => Customer(
                            id: '',
                            userId: '',
                            name: 'Unknown',
                            phone: '',
                            address: '',
                            createdAt: DateTime.now(),
                          ),
                        );
                        return _buildTransactionTile(
                            t, customer.name, isDarkMode);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color:
                  isDarkMode ? Colors.grey.shade400 : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rs ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetBalanceCard(double netBalance, bool isDarkMode) {
    final isPositive = netBalance >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFF16A34A), const Color(0xFF15803D)]
              : [const Color(0xFFDC2626), const Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Net Balance',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rs ${netBalance.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPositive
                ? 'Customers owe you this amount'
                : 'You owe this amount to customers',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
      Transaction t, String customerName, bool isDarkMode) {
    final isCredit = t.type == 'credit';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isCredit ? Colors.red : Colors.green).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color:
                  isCredit ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : const Color(0xFF1D293D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.description,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs ${t.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isCredit
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${t.date.day}/${t.date.month}/${t.date.year}',
                style: TextStyle(
                  fontSize: 10,
                  color:
                      isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
