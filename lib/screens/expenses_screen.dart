import 'package:digital_khata_new/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:digital_khata_new/providers/expense_provider.dart';
import 'package:digital_khata_new/providers/theme_provider.dart';
import 'package:digital_khata_new/models/expense.dart';

import 'package:share_plus/share_plus.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  int _trendTabIndex = 0; // 0 = Monthly, 1 = Weekly

  // ---- Recent expenses date filter state ----
  String _filterLabel = 'All';
  DateTime? _filterStart;
  DateTime? _filterEnd;

  // ---- Recent expenses category filter + sort state ----
  Set<String> _selectedCategories = {};
  String _sortBy =
      'date_desc'; // date_desc, date_asc, amount_desc, amount_asc, category_asc

  static const Map<String, String> _sortOptions = {
    'date_desc': 'Newest First',
    'date_asc': 'Oldest First',
    'amount_desc': 'Amount: High to Low',
    'amount_asc': 'Amount: Low to High',
    'category_asc': 'Category: A to Z',
  };

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

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

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

  // ---- Date filter helpers ----

  List<Expense> _applyFilter(List<Expense> all) {
    if (_filterStart == null || _filterEnd == null) return all;
    final start =
        DateTime(_filterStart!.year, _filterStart!.month, _filterStart!.day);
    final end = DateTime(
        _filterEnd!.year, _filterEnd!.month, _filterEnd!.day, 23, 59, 59);
    return all.where((e) {
      return !e.date.isBefore(start) && !e.date.isAfter(end);
    }).toList();
  }

  List<Expense> _applyCategoryFilter(List<Expense> all) {
    if (_selectedCategories.isEmpty) return all;
    return all.where((e) => _selectedCategories.contains(e.category)).toList();
  }

  List<Expense> _applySort(List<Expense> all) {
    final sorted = List<Expense>.from(all);
    switch (_sortBy) {
      case 'date_asc':
        sorted.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'amount_desc':
        sorted.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        sorted.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'category_asc':
        sorted.sort((a, b) => a.category.compareTo(b.category));
        break;
      case 'date_desc':
      default:
        sorted.sort((a, b) => b.date.compareTo(a.date));
    }
    return sorted;
  }

  void _showFilterSheet() {
    final now = DateTime.now();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Filter Expenses',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.all_inclusive),
                  title: const Text('All'),
                  onTap: () {
                    setState(() {
                      _filterLabel = 'All';
                      _filterStart = null;
                      _filterEnd = null;
                    });
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.today),
                  title: const Text('Today'),
                  onTap: () {
                    setState(() {
                      _filterLabel = 'Today';
                      _filterStart = now;
                      _filterEnd = now;
                    });
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Yesterday'),
                  onTap: () {
                    final yesterday = now.subtract(const Duration(days: 1));
                    setState(() {
                      _filterLabel = 'Yesterday';
                      _filterStart = yesterday;
                      _filterEnd = yesterday;
                    });
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_view_month),
                  title: const Text('This Month'),
                  onTap: () {
                    setState(() {
                      _filterLabel = 'This Month';
                      _filterStart = DateTime(now.year, now.month, 1);
                      _filterEnd = DateTime(now.year, now.month + 1, 0);
                    });
                    Navigator.pop(sheetContext);
                  },
                ),
                ExpansionTile(
                  leading: const Icon(Icons.event_note),
                  title: const Text('Pick a Month (this year)'),
                  children: List.generate(now.month, (i) {
                    final monthIndex = i + 1;
                    final label = _monthNames[i];
                    return ListTile(
                      title: Text(label),
                      onTap: () {
                        setState(() {
                          _filterLabel = '$label ${now.year}';
                          _filterStart = DateTime(now.year, monthIndex, 1);
                          _filterEnd = DateTime(now.year, monthIndex + 1, 0);
                        });
                        Navigator.pop(sheetContext);
                      },
                    );
                  }),
                ),
                ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Single Day'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: DateTime(2020),
                      lastDate: now,
                    );
                    if (picked != null) {
                      setState(() {
                        _filterLabel =
                            '${picked.day}/${picked.month}/${picked.year}';
                        _filterStart = picked;
                        _filterEnd = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.date_range),
                  title: const Text('Custom Range'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: now,
                      initialDateRange: DateTimeRange(
                        start: now.subtract(const Duration(days: 7)),
                        end: now,
                      ),
                    );
                    if (range != null) {
                      setState(() {
                        _filterLabel =
                            '${range.start.day}/${range.start.month} - ${range.end.day}/${range.end.month}';
                        _filterStart = range.start;
                        _filterEnd = range.end;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCategoryFilterSheet() {
    final availableCategories = ref
        .read(expenseProvider)
        .map((e) => e.category)
        .toSet()
        .toList()
      ..sort();
    Set<String> tempSelected = Set.from(_selectedCategories);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Filter by Category',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (availableCategories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No categories yet',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    ...availableCategories.map((cat) => CheckboxListTile(
                          value: tempSelected.contains(cat),
                          title: Text(cat),
                          activeColor: const Color(0xFF1D293D),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (checked) {
                            setSheetState(() {
                              if (checked == true) {
                                tempSelected.add(cat);
                              } else {
                                tempSelected.remove(cat);
                              }
                            });
                          },
                        )),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setSheetState(() => tempSelected.clear());
                              },
                              child: const Text('Clear'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategories = tempSelected;
                                });
                                Navigator.pop(sheetContext);
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1D293D)),
                              child: const Text('Apply',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Sort By',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              ..._sortOptions.entries.map((entry) => ListTile(
                    title: Text(entry.value),
                    trailing: _sortBy == entry.key
                        ? const Icon(Icons.check, color: Color(0xFF1D293D))
                        : null,
                    onTap: () {
                      setState(() => _sortBy = entry.key);
                      Navigator.pop(sheetContext);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ---- Delete ----

  Future<void> _confirmDeleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Expense'),
        content: Text(
            'Delete "${expense.category}" expense of Rs${expense.amount.toStringAsFixed(0)}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(expenseProvider.notifier).deleteExpense(expense.id);
      ref.read(budgetProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Expense deleted'), backgroundColor: Colors.green),
        );
      }
    }
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

    // Apply category filter, then date filter, then sort
    final categoryFiltered = _applyCategoryFilter(expenses);
    final dateFiltered = _applyFilter(categoryFiltered);
    final sortedFiltered = _applySort(dateFiltered);
    // When no filter is active, cap the list for perf; a specific
    // filter is usually small already so we show it in full.
    final noFilterActive = _filterStart == null && _selectedCategories.isEmpty;
    final displayExpenses =
        noFilterActive ? sortedFiltered.take(15).toList() : sortedFiltered;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      drawer: CustomDrawer(
        onMenuItemSelected: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pop(context);
          } else if (index == 2) {
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

            // Recent Expenses Header + Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Expenses',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text('${displayExpenses.length} shown',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    icon: Icons.filter_list,
                    label: _filterLabel,
                    isDarkMode: isDarkMode,
                    onTap: _showFilterSheet,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    icon: Icons.category_outlined,
                    label: _selectedCategories.isEmpty
                        ? 'All Categories'
                        : _selectedCategories.length == 1
                            ? _selectedCategories.first
                            : '${_selectedCategories.length} Categories',
                    isDarkMode: isDarkMode,
                    onTap: _showCategoryFilterSheet,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    icon: Icons.sort,
                    label: _sortOptions[_sortBy]!,
                    isDarkMode: isDarkMode,
                    onTap: _showSortSheet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Recent Expenses List
            displayExpenses.isEmpty
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
                        Text(
                            expenses.isEmpty
                                ? 'No expenses yet'
                                : 'No expenses match these filters',
                            style: TextStyle(color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Text(
                            expenses.isEmpty
                                ? 'Tap + to add your first expense'
                                : 'Try adjusting the date or category filter',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade400)),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayExpenses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final expense = displayExpenses[index];
                      final icon =
                          categoryIcons[expense.category] ?? Icons.label;
                      return Dismissible(
                        key: ValueKey(expense.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: const Text('Delete Expense'),
                              content: Text(
                                  'Delete "${expense.category}" expense of Rs${expense.amount.toStringAsFixed(0)}? This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          return confirmed ?? false;
                        },
                        onDismissed: (_) async {
                          await ref
                              .read(expenseProvider.notifier)
                              .deleteExpense(expense.id);
                          ref.read(budgetProvider.notifier).refresh();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Expense deleted'),
                                  backgroundColor: Colors.green),
                            );
                          }
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Container(
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
                                        Text(
                                            expense.paymentMethod.toUpperCase(),
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
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    size: 20, color: Colors.grey.shade400),
                                onPressed: () => _confirmDeleteExpense(expense),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
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

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1D293D)),
            const SizedBox(width: 6),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16),
          ],
        ),
      ),
    );
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

  static const String _addNewCategoryValue = '__add_new_category__';

  // Mutable so the user can add their own categories at runtime.
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

  Future<void> _promptForNewCategory() async {
    final controller = TextEditingController();
    final newCategory = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Groceries',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D293D)),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newCategory != null && newCategory.isNotEmpty) {
      setState(() {
        if (!_categories.contains(newCategory)) {
          _categories.add(newCategory);
        }
        _selectedCategory = newCategory;
      });
    }
  }

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
    // Push the sheet up above the keyboard so fields at the bottom
    // (description, save button) stay reachable while typing.
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
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
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Category Dropdown (+ add new)
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    ..._categories.map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        )),
                    const DropdownMenuItem(
                      value: _addNewCategoryValue,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: Color(0xFF1D293D)),
                          SizedBox(width: 6),
                          Text('Add New Category',
                              style: TextStyle(
                                  color: Color(0xFF1D293D),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == _addNewCategoryValue) {
                      _promptForNewCategory();
                      return;
                    }
                    setState(() => _selectedCategory = value!);
                  },
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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
