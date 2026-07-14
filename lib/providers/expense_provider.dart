import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_khata_new/database/hive_service.dart';
import 'package:digital_khata_new/models/expense.dart';
import 'package:digital_khata_new/models/user.dart';
import 'auth_provider.dart';

final expenseProvider = StateNotifierProvider<ExpenseNotifier, List<Expense>>((ref) {
  final user = ref.watch(authProvider);
  return ExpenseNotifier(ref, user);
});

final budgetProvider = StateNotifierProvider<BudgetNotifier, Budget?>((ref) {
  final user = ref.watch(authProvider);
  return BudgetNotifier(ref, user);
});

class ExpenseNotifier extends StateNotifier<List<Expense>> {
  final Ref _ref;
  final User? currentUser;

  ExpenseNotifier(this._ref, this.currentUser) : super([]) {
    _loadExpenses();
  }

  void _loadExpenses() {
    if (currentUser != null) {
      state = HiveService.getExpensesByUserId(currentUser!.id);
      print('📊 Loaded ${state.length} expenses');
    }
  }
    Future<void> deleteExpense(String id) async {
    print('🗑️ Deleting expense: $id');
    await HiveService.deleteExpense(id);
    _loadExpenses();
    print('✅ Expense deleted');
  }
 

  Future<void> addExpense({
    required double amount,
    required String category,
    required DateTime date,
    required String description,
    required String paymentMethod,
    String? receiptPath,
  }) async {
    print('➕ Adding expense...');

    if (currentUser == null) {
      print('❌ No user logged in');
      return;
    }

    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUser!.id,
      amount: amount,
      category: category,
      date: date,
      description: description,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
      receiptPath: receiptPath,
    );

    await HiveService.addExpense(expense);
    print('✅ Expense added successfully');
    _loadExpenses();
  }

  void refresh() {
    _loadExpenses();
  }

  double getTotalExpensesForMonth(int year, int month) {
    return state
        .where((e) => e.date.year == year && e.date.month == month)
        .fold(0, (sum, e) => sum + e.amount);
  }

  double getTotalExpensesForWeek(DateTime now) {
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return state
        .where((e) => e.date.isAfter(startOfWeek) && e.date.isBefore(endOfWeek))
        .fold(0, (sum, e) => sum + e.amount);
  }

  double getPercentageChange() {
    final now = DateTime.now();
    final thisMonth = getTotalExpensesForMonth(now.year, now.month);

    int prevMonth = now.month - 1;
    int prevYear = now.year;
    if (prevMonth == 0) {
      prevMonth = 12;
      prevYear = now.year - 1;
    }
    final lastMonth = getTotalExpensesForMonth(prevYear, prevMonth);

    if (lastMonth == 0) return 0;
    return ((thisMonth - lastMonth) / lastMonth) * 100;
  }

  String getBestDayToSave() {
    Map<int, double> weekdaySpending = {};
    for (var e in state) {
      final weekday = e.date.weekday;
      weekdaySpending[weekday] = (weekdaySpending[weekday] ?? 0) + e.amount;
    }
    if (weekdaySpending.isEmpty) return 'No data yet';
    int bestDay = weekdaySpending.entries.reduce((a, b) => a.value < b.value ? a : b).key;
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[bestDay - 1];
  }

  List<Map<String, dynamic>> getTopExpenses(int year, int month, int limit) {
    final monthExpenses = state
        .where((e) => e.date.year == year && e.date.month == month)
        .toList();
    monthExpenses.sort((a, b) => b.amount.compareTo(a.amount));
    return monthExpenses
        .take(limit)
        .map((e) => {
              'category': e.category,
              'amount': e.amount,
            })
        .toList();
  }

  List<double> getMonthlyTrend(int year) {
    List<double> monthlyTotals = List.filled(12, 0.0);
    for (var e in state) {
      if (e.date.year == year) {
        monthlyTotals[e.date.month - 1] += e.amount;
      }
    }
    return monthlyTotals;
  }

  List<double> getWeeklyTrend(int year) {
    List<double> weeklyTotals = List.filled(52, 0.0);
    for (var e in state) {
      if (e.date.year == year) {
        final weekNumber = ((e.date.difference(DateTime(year, 1, 1)).inDays / 7).floor() + 1);
        if (weekNumber <= 52 && weekNumber >= 1) {
          weeklyTotals[weekNumber - 1] += e.amount;
        }
      }
    }
    return weeklyTotals;
  }

  // 👇 NEW: Get weekly trend by month (Week 1, Week 2, Week 3, Week 4)
  List<double> getWeeklyTrendByMonth(int year, int month) {
    List<double> weeklyTotals = List.filled(5, 0.0); // Max 5 weeks in a month
    
    for (var e in state) {
      if (e.date.year == year && e.date.month == month) {
        // Calculate week number within the month (1-5)
        final dayOfMonth = e.date.day;
        int weekOfMonth = ((dayOfMonth - 1) / 7).floor();
        if (weekOfMonth >= 0 && weekOfMonth < weeklyTotals.length) {
          weeklyTotals[weekOfMonth] += e.amount;
        }
      }
    }
    
    return weeklyTotals;
  }

  // Get monthly summary
  Map<String, double> getMonthlySummary(int year, int month) {
    final monthExpenses = state.where((e) => e.date.year == year && e.date.month == month).toList();
    
    double total = 0;
    Map<String, double> categoryTotals = {};
    
    for (var e in monthExpenses) {
      total += e.amount;
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }
    
    return {
      'total': total,
      ...categoryTotals,
    };
  }

  // Get total expenses for date range
  double getTotalExpensesForDateRange(DateTime start, DateTime end) {
    return state
        .where((e) => e.date.isAfter(start) && e.date.isBefore(end))
        .fold(0, (sum, e) => sum + e.amount);
  }
}

class BudgetNotifier extends StateNotifier<Budget?> {
  final Ref _ref;
  final User? currentUser;

  BudgetNotifier(this._ref, this.currentUser) : super(null) {
    _loadBudget();
  }

  void _loadBudget() {
    if (currentUser != null) {
      state = HiveService.getBudget(currentUser!.id);
      print('💰 Loaded budget: ${state?.monthlyLimit}');
    }
  }
  

  Future<void> setBudget(double monthlyLimit) async {
    print('💰 Setting budget: $monthlyLimit');
    if (currentUser == null) return;

    final budget = Budget(
      userId: currentUser!.id,
      monthlyLimit: monthlyLimit,
      updatedAt: DateTime.now(),
    );

    await HiveService.saveBudget(budget);
    state = budget;
    print('✅ Budget saved');
  }

  void refresh() {
    _loadBudget();
  }
  
  // Get remaining budget for current month
  double getRemainingBudget(ExpenseNotifier expenseNotifier) {
    final now = DateTime.now();
    final spent = expenseNotifier.getTotalExpensesForMonth(now.year, now.month);
    if (state == null) return 0;
    return state!.monthlyLimit - spent;
  }
  
  // Get budget usage percentage
  double getBudgetPercentage(ExpenseNotifier expenseNotifier) {
    final now = DateTime.now();
    final spent = expenseNotifier.getTotalExpensesForMonth(now.year, now.month);
    if (state == null || state!.monthlyLimit == 0) return 0;
    return (spent / state!.monthlyLimit) * 100;
  }
}