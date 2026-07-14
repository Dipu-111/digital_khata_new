import 'package:hive_flutter/hive_flutter.dart';
import 'package:digital_khata_new/models/user.dart';
import 'package:digital_khata_new/models/customer.dart';
import 'package:digital_khata_new/models/transaction.dart';
import 'package:digital_khata_new/models/expense.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HiveService {
  static const String usersBox = 'users';
  static const String customersBox = 'customers';
  static const String transactionsBox = 'transactions';

  static late Box<User> userBox;
  static late Box<Customer> customerBox;
  static late Box<Transaction> transactionBox;
  static late Box<Expense> expenseBox;
  static late Box<Budget> budgetBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(CustomerAdapter());
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(BudgetAdapter());

    userBox = await Hive.openBox<User>(usersBox);
    customerBox = await Hive.openBox<Customer>(customersBox);
    transactionBox = await Hive.openBox<Transaction>(transactionsBox);
    expenseBox = await Hive.openBox<Expense>('expenses');
    budgetBox = await Hive.openBox<Budget>('budget');
  }

  // User Methods
  static Future<void> addUser(User user) async {
    await userBox.put(user.id, user);
  }

  static User? getUserByPhone(String phone) {
    try {
      return userBox.values.firstWhere((user) => user.phone == phone);
    } catch (e) {
      return null;
    }
  }

  static User? getUserById(String id) {
    return userBox.get(id);
  }

  static List<User> getAllUsers() {
    return userBox.values.toList();
  }

  // Customer Methods
  static Future<void> addCustomer(Customer customer) async {
    await customerBox.put(customer.id, customer);
  }

  static Future<void> updateCustomer(Customer customer) async {
    await customerBox.put(customer.id, customer);
  }

  static Future<void> deleteCustomer(String id) async {
    await customerBox.delete(id);
  }

  static List<Customer> getCustomersByUserId(String userId) {
    return customerBox.values.where((c) => c.userId == userId).toList();
  }

  static Customer? getCustomerById(String id) {
    return customerBox.get(id);
  }

  // Transaction Methods
  static Future<void> addTransaction(Transaction transaction) async {
    await transactionBox.put(transaction.id, transaction);
  }

  static Future<void> updateTransaction(Transaction transaction) async {
    await transactionBox.put(transaction.id, transaction);
  }

  static Future<void> deleteTransaction(String id) async {
    await transactionBox.delete(id);
  }

  static Transaction? getTransactionById(String id) {
    return transactionBox.get(id);
  }

  static List<Transaction> getTransactionsByUserId(String userId) {
    return transactionBox.values.where((t) => t.userId == userId).toList();
  }

  static List<Transaction> getTransactionsByCustomer(String customerId) {
    return transactionBox.values
        .where((t) => t.customerId == customerId)
        .toList();
  }

  static double getCustomerBalance(String customerId) {
    final transactions = getTransactionsByCustomer(customerId);
    double balance = 0;
    for (var t in transactions) {
      if (t.type == 'credit') {
        balance += t.amount;
      } else if (t.type == 'payment') {
        balance -= t.amount;
      }
    }
    return balance;
  }

  static double getTotalDue(String userId) {
    final customers = getCustomersByUserId(userId);
    double total = 0;
    for (var c in customers) {
      total += getCustomerBalance(c.id);
    }
    return total;
  }

  // Expense Methods
  static Future<void> addExpense(Expense expense) async {
    await expenseBox.put(expense.id, expense);
  }

  static Future<void> updateExpense(Expense expense) async {
    await expenseBox.put(expense.id, expense);
  }

  static Future<void> deleteExpense(String id) async {
    await expenseBox.delete(id);
  }

  static Expense? getExpenseById(String id) {
    return expenseBox.get(id);
  }

  static List<Expense> getExpensesByUserId(String userId) {
    return expenseBox.values.where((e) => e.userId == userId).toList();
  }

  // Budget Methods
  static Future<void> saveBudget(Budget budget) async {
    await budgetBox.put(budget.userId, budget);
  }

  static Budget? getBudget(String userId) {
    return budgetBox.get(userId);
  }

  // Login State Methods
  static Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('user_id');
  }

  static Future<String?> getLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<void> saveLoginState(String userId, bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', isLoggedIn);
    if (isLoggedIn) {
      await prefs.setString('user_id', userId);
    }
  }
}
