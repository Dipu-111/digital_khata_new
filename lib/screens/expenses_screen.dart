import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:digital_khata_new/providers/expense_provider.dart';
import 'package:digital_khata_new/providers/theme_provider.dart';
import 'package:digital_khata_new/screens/add_expense_screen.dart';
import 'package:digital_khata_new/widgets/budget_dialog.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String _filterType = 'month';
  DateTime _selectedDate = DateTime.now();

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

  final Map<String, Color> categoryColors = {
    'Food & Dining': const Color(0xFFDC2626),
    'Shopping': const Color(0xFFF59E0B),
    'Transport': const Color(0xFF3B82F6),
    'Entertainment': const Color(0xFF8B5CF6),
    'Bills': const Color(0xFF06B6D4),
    'Rent': const Color(0xFF1D293D),
    'Health': const Color(0xFF10B981),
    'Education': const Color(0xFFF97316),
    'Travel': const Color(0xFFEC4899),
    'Subscription': const Color(0xFF6B7280),
    'Other': const Color(0xFF9CA3AF),
  };

  void _refreshData() {
    setState(() {});
    ref.read(expenseProvider.notifier).refresh();
    ref.read(budgetProvider.notifier).refresh();
  }

  void _showBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => const BudgetDialog(),
    ).then((_) {
      _refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseProvider);
    final budget = ref.watch(budgetProvider);
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    final now = DateTime.now();
    final totalThisMonth = ref.read(expenseProvider.notifier).getTotalExpensesForMonth(now.year, now.month);
    final totalThisWeek = ref.read(expenseProvider.notifier).getTotalExpensesForWeek(now);
    final remainingBudget = budget != null ? (budget.monthlyLimit - totalThisMonth).toDouble() : 0.0;
    final budgetPercentage = budget != null ? ((totalThisMonth / budget.monthlyLimit) * 100).toDouble() : 0.0;
    
    final categoryExpenses = ref.read(expenseProvider.notifier).getCategoryWiseExpenses(now.year, now.month);
    final filteredExpenses = _filterExpenses(expenses, now);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: const Color(0xFF1D293D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: _showBudgetDialog,
            tooltip: 'Set Budget',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Tabs
            _buildFilterTabs(isDarkMode),
            const SizedBox(height: 16),

            // Summary Cards Row
            Row(
              children: [
                Expanded(child: _buildSummaryCard('This Month', totalThisMonth, const Color(0xFFDC2626), isDarkMode)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryCard('This Week', totalThisWeek, const Color(0xFFF59E0B), isDarkMode)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryCard('Budget Left', remainingBudget > 0 ? remainingBudget : 0.0, const Color(0xFF16A34A), isDarkMode)),
              ],
            ),
            const SizedBox(height: 20),

            // Monthly Budget Progress
            if (budget != null)
              _buildBudgetProgress(totalThisMonth, budget.monthlyLimit, remainingBudget, budgetPercentage, isDarkMode),
            
            const SizedBox(height: 24),

            // Expense Breakdown - Pie Chart
            if (categoryExpenses.isNotEmpty) ...[
              _buildSectionHeader('Expense Breakdown', isDarkMode),
              const SizedBox(height: 12),
              _buildPieChart(categoryExpenses, isDarkMode),
              const SizedBox(height: 16),
              _buildCategoryList(categoryExpenses, isDarkMode),
            ],

            const SizedBox(height: 24),

            // Recent Expenses
            _buildSectionHeader('Recent Expenses', isDarkMode),
            const SizedBox(height: 12),
            filteredExpenses.isEmpty
                ? _buildEmptyState(isDarkMode)
                : _buildExpensesList(filteredExpenses, isDarkMode),

            // See All Button
            if (filteredExpenses.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All expenses coming soon')),
                      );
                    },
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1D293D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          if (result == true) {
            _refreshData();
          }
        },
        backgroundColor: const Color(0xFF1D293D),
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white, size: 22),
        label: const Text(
          'Add Expense',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFilterTabs(bool isDarkMode) {
    return Row(
      children: [
        _buildFilterChip('Week', 'week', isDarkMode),
        const SizedBox(width: 8),
        _buildFilterChip('Month', 'month', isDarkMode),
        const SizedBox(width: 8),
        _buildFilterChip('Custom', 'custom', isDarkMode),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDarkMode) {
    final isSelected = _filterType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1D293D)
                : (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF5F7FA)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : const Color(0xFF45556C),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Text(
            '₹ ${amount.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetProgress(double spent, double total, double left, double percentage, bool isDarkMode) {
    Color progressColor;
    if (percentage < 70) {
      progressColor = const Color(0xFF16A34A);
    } else if (percentage < 90) {
      progressColor = const Color(0xFFF59E0B);
    } else {
      progressColor = const Color(0xFFDC2626);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Budget', style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF6B7280))),
              Text('₹ ${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              color: progressColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹ ${spent.toStringAsFixed(0)} used', style: TextStyle(fontSize: 12, color: progressColor)),
              Text('₹ ${left.toStringAsFixed(0)} left', style: TextStyle(fontSize: 12, color: progressColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : const Color(0xFF1D293D))),
      ],
    );
  }

  Widget _buildPieChart(Map<String, double> categoryExpenses, bool isDarkMode) {
    final List<PieChartSectionData> sections = [];
    int index = 0;
    final colors = categoryColors.values.toList();

    for (var entry in categoryExpenses.entries) {
      sections.add(
        PieChartSectionData(
          value: entry.value,
          title: '${((entry.value / categoryExpenses.values.reduce((a, b) => a + b)) * 100).toStringAsFixed(0)}%',
          color: colors[index % colors.length],
          radius: 70,
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
      index++;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: 40,
            sectionsSpace: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(Map<String, double> categoryExpenses, bool isDarkMode) {
    final total = categoryExpenses.values.reduce((a, b) => a + b);
    final colors = categoryColors.values.toList();
    int index = 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: categoryExpenses.entries.map((entry) {
          final percentage = (entry.value / total) * 100;
          final color = colors[index % colors.length];
          index++;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(entry.key, style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : const Color(0xFF1D293D)))),
                Text('₹ ${entry.value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                SizedBox(width: 45, child: Text('(${percentage.toStringAsFixed(0)}%)', style: TextStyle(fontSize: 12, color: color))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpensesList(List<dynamic> expenses, bool isDarkMode) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length > 5 ? 5 : expenses.length,
      separatorBuilder: (_, __) => const Divider(color: Color(0xFFE5E7EB), height: 1),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final icon = categoryIcons[expense.category] ?? Icons.label;
        final date = _formatDate(expense.date);
        
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (categoryColors[expense.category] ?? const Color(0xFF6B7280)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: categoryColors[expense.category] ?? const Color(0xFF6B7280)),
          ),
          title: Text(expense.category, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : const Color(0xFF1D293D))),
          subtitle: Text(date, style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.grey.shade500 : const Color(0xFF6B7280))),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('₹ ${expense.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 18, color: Color(0xFF6B7280)),
            ],
          ),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Expense details coming soon')),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('No expenses yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF45556C))),
          const SizedBox(height: 4),
          Text('Tap + to add your first expense', style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey.shade500 : const Color(0xFF6B7280))),
        ],
      ),
    );
  }

  List<dynamic> _filterExpenses(List<dynamic> expenses, DateTime now) {
    if (_filterType == 'week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return expenses.where((e) => e.date.isAfter(startOfWeek) && e.date.isBefore(endOfWeek)).toList();
    } else if (_filterType == 'month') {
      return expenses.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    }
    return expenses;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return 'Today';
    } else if (date.day == now.day - 1 && date.month == now.month && date.year == now.year) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}