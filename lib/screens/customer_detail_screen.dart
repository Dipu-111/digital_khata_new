import 'package:digital_khata_new/models/transaction.dart';
import 'package:digital_khata_new/providers/customer_provider.dart';
import 'package:digital_khata_new/services/pdf_receipt_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:digital_khata_new/models/customer.dart';
import 'package:digital_khata_new/providers/transaction_provider.dart';
import 'package:digital_khata_new/providers/auth_provider.dart';
import 'package:digital_khata_new/screens/add_transaction_screen.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  void _sendWhatsAppReminder() {
    final balance = ref
        .read(transactionProvider.notifier)
        .getCustomerBalance(widget.customer.id);
    final shopName = ref.read(authProvider)?.shopName ?? 'Our Shop';

    if (balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending dues for this customer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Create message
    final message = '''
*Payment Reminder* 📋

Dear ${widget.customer.name},

Your pending balance is *रु ${balance.toStringAsFixed(0)}*

Please clear your dues at your earliest convenience.

- ${shopName}
📞 Contact: ${widget.customer.phone}
''';

    // Share via WhatsApp
    Share.share(message, subject: 'Payment Reminder');
  }

  Future<void> _printCustomerStatement() async {
    final user = ref.read(authProvider);
    final transactions = ref
        .watch(transactionProvider)
        .where((t) => t.customerId == widget.customer.id)
        .toList();
    final balance = ref
        .read(transactionProvider.notifier)
        .getCustomerBalance(widget.customer.id);

    if (user == null) return;

    await PdfReceiptService.printCustomerStatement(
      customer: widget.customer,
      transactions: transactions,
      balance: balance,
      shopName: user.shopName,
      ownerName: user.ownerName,
      shopPhone: user.phone,
    );
  }

  bool _isSelectionMode = false;
  String? _selectedTransactionId;

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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.customer.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1D293D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          // WhatsApp Button
          IconButton(
            onPressed: _sendWhatsAppReminder,
            icon: const Icon(
              FontAwesomeIcons.whatsapp,
              color: Colors.green,
              size: 24,
            ),
            tooltip: 'Send WhatsApp Reminder',
          ),
          IconButton(
            onPressed: _printCustomerStatement,
            icon: const Icon(Icons.print),
            tooltip: 'Print Statement',
          ),
        ],
      ),
      body: Column(
        children: [
          // Customer Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFF8FAFC),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: balance > 0
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      child: Text(
                        widget.customer.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: balance > 0
                              ? Colors.red.shade600
                              : Colors.green.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.customer.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D293D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 14,
                                color: Color(0xFF45556C),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.customer.phone,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF45556C),
                                ),
                              ),
                            ],
                          ),
                          if (widget.customer.address.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Color(0xFF45556C),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.customer.address,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF45556C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF45556C),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'रु ${balance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: balance > 0
                                  ? Colors.red.shade600
                                  : Colors.green.shade600,
                            ),
                          ),
                          if (balance > 0)
                            Text(
                              'Due Amount',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade400,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // WhatsApp Button in Info Card
                if (balance > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: InkWell(
                      onTap: _sendWhatsAppReminder,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FontAwesomeIcons.whatsapp,
                              color: Colors.green.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Send WhatsApp Reminder',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaction History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D293D),
                        ),
                      ),
                      Text(
                        '${transactions.length} entries',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: transactions.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text('No transactions yet'),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: transactions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final t = transactions[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (t.type == 'credit'
                                              ? Colors.red
                                              : Colors.green)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      t.type == 'credit'
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: t.type == 'credit'
                                          ? Colors.red.shade600
                                          : Colors.green.shade600,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.description,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${t.date.day}/${t.date.month}/${t.date.year}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'रु ${t.amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: t.type == 'credit'
                                          ? Colors.red.shade600
                                          : Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: const Color(0xFFE2E8F0), width: 0.8),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showAddTransaction('credit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.arrow_downward, size: 18),
                label: const Text('Add Credit'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showAddTransaction('payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.arrow_upward, size: 18),
                label: const Text('Receive Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add these methods
  void _showEditTransactionDialog(Transaction transaction) {
    final amountController = TextEditingController(
      text: transaction.amount.toString(),
    );
    final descriptionController = TextEditingController(
      text: transaction.description,
    );
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit, color: Color(0xFF1D293D)),
                  SizedBox(width: 12),
                  Text(
                    'Edit Transaction',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: const Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          ref
                              .read(transactionProvider.notifier)
                              .updateTransaction(
                                id: transaction.id,
                                customerId: widget.customer.id,
                                type: transaction.type,
                                amount: double.parse(amountController.text),
                                description: descriptionController.text,
                              );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaction updated'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D293D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String type, String id, {String? customerId}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this $type?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (type == 'customer' && customerId != null) {
                await ref
                    .read(customerProvider.notifier)
                    .deleteCustomer(customerId);
                if (mounted) Navigator.pop(context);
              } else {
                await ref
                    .read(transactionProvider.notifier)
                    .deleteTransaction(id);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$type deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddTransaction(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddTransactionScreen(customerId: widget.customer.id, type: type),
      ),
    );
  }
}
