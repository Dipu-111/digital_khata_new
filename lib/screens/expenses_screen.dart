import 'package:digital_khata_new/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:digital_khata_new/providers/expense_provider.dart';
import 'package:digital_khata_new/providers/theme_provider.dart';

import 'package:share_plus/share_plus.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  int _trendTabIndex = 0; // 0 = Monthly, 1 = Weekly

  final Map<String, IconData> categoryIcons = {
    'Food & Dining': Icons.restaurant,
    'Shopping': Icons.shopping_bag,
    'Transport': Icons.directions_car,
    'Entertainment': Icons.movie,
    'Bills': Icons.bolt,
    'Rent': Icons.home,
    'Health': Icons.medical_services,
    'Education': Icons.school,
    'Travel': Icons.flight,
    'Subscription': Icons.subscriptions,
    'Other': Icons.label,
  };

  void _showAddExpensePopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddExpensePopup(
        onExpenseAdded: () {
          setState(() {});
          ref.read(expenseProvider.notifier).refresh();
          ref.read(budgetProvider.notifier).refresh();
        },
        riverpodRef: ref,
      ),
    );
  }

  void _showAddBudgetDialog() {
    final budget = ref.read(budgetProvider);
    final controller =
        TextEditingController(text: budget?.monthlyLimit.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Budget Amount (Rs)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.currency_rupee),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await ref
                    .read(budgetProvider.notifier)
                    .setBudget(double.parse(controller.text));
                setState(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Budget updated'),
                      backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D293D)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareReport() async {
    final totalSpent = ref
        .read(expenseProvider.notifier)
        .getTotalExpensesForMonth(DateTime.now().year, DateTime.now().month);

    final message = '📊 Digital Khata - Expense Report\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        'Total spent this month: Rs${totalSpent.toStringAsFixed(0)}\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        'Track your expenses with Digital Khata!';

    await Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseProvider);
    final budget = ref.watch(budgetProvider);
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    final now = DateTime.now();
    final totalThisMonth = ref
        .read(expenseProvider.notifier)
        .getTotalExpensesForMonth(now.year, now.month);
    final totalThisWeek =
        ref.read(expenseProvider.notifier).getTotalExpensesForWeek(now);
    final percentageChange =
        ref.read(expenseProvider.notifier).getPercentageChange();
    final bestDayToSave = ref.read(expenseProvider.notifier).getBestDayToSave();
    final topExpenses = ref
        .read(expenseProvider.notifier)
        .getTopExpenses(now.year, now.month, 3);
    final remainingBudget = budget != null
        ? (budget.monthlyLimit - totalThisMonth).toDouble()
        : 0.0;
    final budgetPercentage =
        budget != null ? (totalThisMonth / budget.monthlyLimit) * 100 : 0.0;
    final monthlyTrend =
        ref.read(expenseProvider.notifier).getMonthlyTrend(now.year);
    final weeklyTrendByMonth = ref
        .read(expenseProvider.notifier)
        .getWeeklyTrendByMonth(now.year, now.month);

    String budgetAlert = '';
    Color alertColor = Colors.transparent;
    if (budgetPercentage >= 100) {
      budgetAlert = '❌ Budget exceeded! You\'ve crossed your monthly limit.';
      alertColor = Colors.red;
    } else if (budgetPercentage >= 90) {
      budgetAlert =
          '⚠️ Careful! You\'ve used 90% of your budget. Rs${remainingBudget.toStringAsFixed(0)} left.';
      alertColor = Colors.orange;
    } else if (budgetPercentage >= 80) {
      budgetAlert =
          '⚠️ You\'ve used 80% of your budget. Rs${remainingBudget.toStringAsFixed(0)} remaining.';
      alertColor = Colors.orange;
    }

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
        title: const Text('Personal Expenses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        backgroundColor: const Color(0xFF1D293D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: _showAddBudgetDialog,
            tooltip: 'Set Budget',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReport,
            tooltip: 'Share Report',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpensePopup,
        backgroundColor: const Color(0xFF1D293D),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Expense', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget Card
            GestureDetector(
              onTap: _showAddBudgetDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: budget == null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline,
                              color: const Color(0xFF1D293D), size: 20),
                          const SizedBox(width: 8),
                          const Text('Tap to set monthly budget',
                              style: TextStyle(fontSize: 14)),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.track_changes,
                                      color: const Color(0xFF1D293D), size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Monthly Budget',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.edit,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('Tap to edit',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500)),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 16, thickness: 0.5),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Budget',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF6B7280))),
                              Text(
                                  'Rs ${budget.monthlyLimit.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Spent',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF6B7280))),
                              Text('Rs ${totalThisMonth.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFDC2626))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Remaining',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF6B7280))),
                              Text('Rs ${remainingBudget.toStringAsFixed(0)}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: remainingBudget > 0
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFDC2626))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (budgetPercentage / 100).clamp(0.0, 1.0),
                              backgroundColor: Colors.grey.shade200,
                              color: budgetPercentage >= 90
                                  ? Colors.red
                                  : (budgetPercentage >= 70
                                      ? Colors.orange
                                      : Colors.green),
                              minHeight: 6,
                            ),
                          ),
                          if (budgetAlert.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: alertColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        size: 16, color: alertColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(budgetAlert,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: alertColor))),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Smart Insights Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb,
                          color: Color(0xFF155DFC), size: 18),
                      const SizedBox(width: 8),
                      const Text('Smart Insights',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    percentageChange > 0
                        ? '📈 You spent ${percentageChange.toStringAsFixed(0)}% more this month'
                        : percentageChange < 0
                            ? '📉 You spent ${percentageChange.abs().toStringAsFixed(0)}% less this month'
                            : '📊 Your spending is similar to last month',
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF45556C)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '⭐ Best day to save: $bestDayToSave',
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF45556C)),
                  ),
                  if (topExpenses.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '🔥 Top expenses: ${topExpenses.map((e) => '${e['category']} (Rs${e['amount']})').join(', ')}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF45556C)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Spending Trend with Tabs
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Spending Trend',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTrendTab('Monthly', 0),
                      const SizedBox(width: 12),
                      _buildTrendTab('Weekly', 1),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_trendTabIndex == 0 && monthlyTrend.isNotEmpty)
                    SizedBox(
                      height: 180,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (value, meta) {
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
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < months.length) {
                                    return Text(months[value.toInt()],
                                        style: const TextStyle(fontSize: 10));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true, reservedSize: 40),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(monthlyTrend.length,
                                  (i) => FlSpot(i.toDouble(), monthlyTrend[i])),
                              isCurved: true,
                              color: const Color(0xFF1D293D),
                              barWidth: 2.5,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF1D293D).withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_trendTabIndex == 1 && weeklyTrendByMonth.isNotEmpty)
                    SizedBox(
                      height: 180,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (value, meta) {
                                  final weekNum = value.toInt() + 1;
                                  return Text('W$weekNum',
                                      style: const TextStyle(fontSize: 10));
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true, reservedSize: 40),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(
                                  weeklyTrendByMonth.length,
                                  (i) => FlSpot(
                                      i.toDouble(), weeklyTrendByMonth[i])),
                              isCurved: true,
                              color: const Color(0xFF1D293D),
                              barWidth: 2.5,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF1D293D).withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Recent Expenses Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Expenses',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text('${expenses.length} total',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 12),

            // Recent Expenses List
            expenses.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('No expenses yet',
                            style: TextStyle(color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Text('Tap + to add your first expense',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade400)),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: expenses.length > 15 ? 15 : expenses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final expense = expenses.reversed.toList()[index];
                      final icon =
                          categoryIcons[expense.category] ?? Icons.label;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFF5F7FA),
                              child: Icon(icon,
                                  size: 18, color: const Color(0xFF1D293D)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(expense.category,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(_formatDate(expense.date),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500)),
                                      const SizedBox(width: 6),
                                      Container(
                                          width: 3,
                                          height: 3,
                                          decoration: const BoxDecoration(
                                              color: Colors.grey,
                                              shape: BoxShape.circle)),
                                      const SizedBox(width: 6),
                                      Text(expense.paymentMethod.toUpperCase(),
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade400)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Rs${expense.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDC2626),
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return 'Today';
    } else if (date.day == now.day - 1 &&
        date.month == now.month &&
        date.year == now.year) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildTrendTab(String title, int index) {
    final isSelected = _trendTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _trendTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D293D) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1D293D),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ==================== ADD EXPENSE POPUP ====================

class AddExpensePopup extends StatefulWidget {
  final VoidCallback onExpenseAdded;
  final WidgetRef riverpodRef;

  const AddExpensePopup({
    super.key,
    required this.onExpenseAdded,
    required this.riverpodRef,
  });

  @override
  State<AddExpensePopup> createState() => _AddExpensePopupState();
}

class _AddExpensePopupState extends State<AddExpensePopup> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Food & Dining';
  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMethod = 'cash';
  bool _isLoading = false;
  String _selectedQuickAmount = '';

  final List<String> _categories = [
    'Food & Dining',
    'Shopping',
    'Transport',
    'Entertainment',
    'Bills',
    'Rent',
    'Health',
    'Education',
    'Travel',
    'Subscription',
    'Other'
  ];

  final List<String> _quickAmounts = ['100', '500', '1000', '2000', '5000'];

  Future<void> _saveExpense() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter amount'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.riverpodRef.read(expenseProvider.notifier).addExpense(
            amount: double.parse(_amountController.text),
            category: _selectedCategory,
            date: _selectedDate,
            description: _descriptionController.text,
            paymentMethod: _selectedPaymentMethod,
            receiptPath: null,
          );

      setState(() => _isLoading = false);

      if (mounted) {
        widget.onExpenseAdded();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Expense added!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Add Expense',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: 'Rs ',
                  hintText: 'Enter amount',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),

              // Quick Amount Buttons
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.5,
                ),
                itemCount: _quickAmounts.length,
                itemBuilder: (context, index) {
                  final amount = _quickAmounts[index];
                  final isSelected = _selectedQuickAmount == amount;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedQuickAmount = amount;
                        _amountController.text = amount;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1D293D)
                            : Colors.transparent,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Rs$amount',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1D293D),
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                      value: category, child: Text(category));
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: 12),

              // Date Row
              Row(
                children: [
                  _buildDateChip('Today', DateTime.now()),
                  _buildDateChip('Yesterday',
                      DateTime.now().subtract(const Duration(days: 1))),
                  _buildDateChip(
                      'This Week',
                      DateTime.now().subtract(
                          Duration(days: DateTime.now().weekday - 1))),
                ],
              ),
              const SizedBox(height: 8),

              // Date Picker
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          primaryColor: const Color(0xFF1D293D),
                          colorScheme: const ColorScheme.light(
                              primary: Color(0xFF1D293D)),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Payment Method
              Row(
                children: [
                  _buildPaymentChip('Cash', 'cash'),
                  const SizedBox(width: 8),
                  _buildPaymentChip('Card', 'card'),
                  const SizedBox(width: 8),
                  _buildPaymentChip('UPI', 'upi'),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Description (optional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D293D),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save Expense'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, DateTime date) {
    final isSelected = _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;
    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D293D) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1D293D),
                fontSize: 12)),
      ),
    );
  }

  Widget _buildPaymentChip(String label, String value) {
    final isSelected = _selectedPaymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPaymentMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                isSelected ? const Color(0xFF1D293D) : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color:
                        isSelected ? Colors.white : const Color(0xFF1D293D))),
          ),
        ),
      ),
    );
  }
}
