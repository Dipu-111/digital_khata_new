import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_khata_new/models/customer.dart';
import 'package:digital_khata_new/providers/transaction_provider.dart';
import 'package:digital_khata_new/providers/auth_provider.dart';
import 'package:digital_khata_new/providers/customer_provider.dart';
import 'package:digital_khata_new/providers/theme_provider.dart';
import 'package:digital_khata_new/screens/add_transaction_screen.dart';
import 'package:digital_khata_new/widgets/edit_customer_dialog.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => EditCustomerDialog(customer: widget.customer),
    ).then((_) {
      setState(() {});
    });
  }

  Future<void> _deleteCustomer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Customer'),
        content: const Text(
            'This will also delete all transactions for this customer. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(customerProvider.notifier)
          .deleteCustomer(widget.customer.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref
        .watch(transactionProvider)
        .where((t) => t.customerId == widget.customer.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final balance = ref
        .read(transactionProvider.notifier)
        .getCustomerBalance(widget.customer.id);
    final user = ref.read(authProvider);
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    // Calculate meaningful texts based on balance
    String balanceLabel;
    String balanceSubtitle;
    Color balanceColor;

    if (balance > 0) {
      balanceLabel = 'Customer Owes You';
      balanceSubtitle = 'Pending payment from customer';
      balanceColor = const Color(0xFFDC2626); // Red
    } else if (balance < 0) {
      balanceLabel = 'You Owe Customer';
      balanceSubtitle = 'Refund or credit to customer';
      balanceColor = const Color(0xFF16A34A); // Green
    } else {
      balanceLabel = 'Balance Settled';
      balanceSubtitle = 'All payments cleared';
      balanceColor = const Color(0xFF6B7280); // Grey
    }

    // Calculate totals
    double totalCreditGiven = 0;
    double totalPaymentReceived = 0;
    for (var t in transactions) {
      if (t.type == 'credit') {
        totalCreditGiven += t.amount;
      } else if (t.type == 'payment') {
        totalPaymentReceived += t.amount;
      }
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        title: Text(
          widget.customer.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF1D293D),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditDialog,
            tooltip: 'Edit Customer',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteCustomer,
            tooltip: 'Delete Customer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Customer Profile Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: isDarkMode
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF8FAFC),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: const Color(0xFFF5F7FA),
                    child: Text(
                      widget.customer.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D293D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.customer.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          isDarkMode ? Colors.white : const Color(0xFF1D293D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.customer.phone,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  if (widget.customer.address.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.customer.address,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Balance Card with Option B (Label + Subtitle)
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
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                balanceLabel,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: balanceColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                balanceSubtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDarkMode
                                      ? Colors.grey.shade500
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Rs ${balance.abs().toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: balanceColor,
                            ),
                          ),
                        ],
                      ),
                      if (balance != 0) ...[
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFE5E7EB), thickness: 0.5),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Goods Given',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDarkMode
                                        ? Colors.grey.shade400
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Rs ${totalCreditGiven.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Payments Received',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDarkMode
                                        ? Colors.grey.shade400
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Rs ${totalPaymentReceived.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTransactionScreen(
                              customerId: widget.customer.id,
                              type: 'credit',
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      icon: const Icon(Icons.arrow_downward, size: 18),
                      label: const Text('Goods Given'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F7FA),
                        foregroundColor: const Color(0xFFDC2626),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTransactionScreen(
                              customerId: widget.customer.id,
                              type: 'payment',
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      icon: const Icon(Icons.arrow_upward, size: 18),
                      label: const Text('Payment Received'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F7FA),
                        foregroundColor: const Color(0xFF16A34A),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Transaction History Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'TRANSACTION HISTORY',
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
            ),
            const SizedBox(height: 12),

            // Transaction List
            transactions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
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
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Color(0xFFE5E7EB), height: 1),
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${t.date.day} ${_getMonth(t.date.month)} ${t.date.year}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF1D293D),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t.type == 'credit'
                                      ? 'Goods Given'
                                      : 'Payment Received',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: t.type == 'credit'
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Rs ${t.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: t.type == 'credit'
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
