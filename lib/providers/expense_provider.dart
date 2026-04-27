import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_khata_new/database/hive_service.dart';
import 'package:digital_khata_new/models/expense.dart';
import 'package:digital_khata_new/models/user.dart';
import 'auth_provider.dart';

final expenseProvider =
    StateNotifierProvider<ExpenseNotifier, List<Expense>>((ref) {
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
    }
  }

  Future<void> addExpense({
    required double amount,
    required String category,
    required DateTime date,
    required String description,
    required String paymentMethod,
  }) async {
    if (currentUser == null) return;

    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUser!.id,
      amount: amount,
      category: category,
      date: date,
      description: description,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
    );

    await HiveService.addExpense(expense);
    _loadExpenses();
  }

  Future<void> updateExpense(Expense expense) async {
    await HiveService.updateExpense(expense);
    _loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await HiveService.deleteExpense(id);
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

  Map<String, double> getCategoryWiseExpenses(int year, int month) {
    final Map<String, double> categoryMap = {};

    for (var e in state) {
      if (e.date.year == year && e.date.month == month) {
        categoryMap[e.category] = (categoryMap[e.category] ?? 0) + e.amount;
      }
    }

    return categoryMap;
  }

  void refresh() {
    _loadExpenses();
  }
}

class BudgetNotifier extends StateNotifier<Budget?> {
  final Ref _ref;
  final User? currentUser;

  BudgetNotifier(this._ref, this.currentUser) : super(null) {
    _loadBudget();
  }
  void refresh() {
    _loadBudget();
  }

  void _loadBudget() {
    if (currentUser != null) {
      state = HiveService.getBudget(currentUser!.id);
    }
  }

  Future<void> setBudget(double monthlyLimit) async {
    if (currentUser == null) return;

    final budget = Budget(
      userId: currentUser!.id,
      monthlyLimit: monthlyLimit,
      updatedAt: DateTime.now(),
    );

    await HiveService.saveBudget(budget);
    state = budget;
  }

  double getRemainingBudget(int year, int month) {
    if (state == null) return 0;
    final totalExpenses = _ref
        .read(expenseProvider.notifier)
        .getTotalExpensesForMonth(year, month);
    return state!.monthlyLimit - totalExpenses;
  }

  double getBudgetPercentage(int year, int month) {
    if (state == null) return 0;
    final totalExpenses = _ref
        .read(expenseProvider.notifier)
        .getTotalExpensesForMonth(year, month);
    return (totalExpenses / state!.monthlyLimit) * 100;
  }
}
