import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_khata_new/providers/expense_provider.dart';

class BudgetDialog extends ConsumerStatefulWidget {
  const BudgetDialog({super.key});

  @override
  ConsumerState<BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends ConsumerState<BudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _monthlyBudgetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentBudget = ref.read(budgetProvider);
    if (currentBudget != null) {
      _monthlyBudgetController.text = currentBudget.monthlyLimit.toString();
    }
  }

  void _saveBudget() {
    if (_formKey.currentState!.validate()) {
      final monthlyLimit = double.tryParse(_monthlyBudgetController.text) ?? 0;
      ref.read(budgetProvider.notifier).setBudget(monthlyLimit);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget updated successfully'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set Monthly Budget', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _monthlyBudgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Budget (₹)',
                  hintText: 'Enter your monthly budget',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Budget amount is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
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
                    onPressed: _saveBudget,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D293D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}