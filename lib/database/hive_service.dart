import 'package:digital_khata_new/models/expense.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:digital_khata_new/models/user.dart';
import 'package:digital_khata_new/models/customer.dart';
import 'package:digital_khata_new/models/transaction.dart';

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

    // Register adapters
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(CustomerAdapter());
    Hive.registerAdapter(TransactionAdapter());

    // Open boxes
    userBox = await Hive.openBox<User>(usersBox);
    customerBox = await Hive.openBox<Customer>(customersBox);
    transactionBox = await Hive.openBox<Transaction>(transactionsBox);
    expenseBox = await Hive.openBox<Expense>('expenses');
budgetBox = await Hive.openBox<Budget>('budget');

  }

  // ==================== USER METHODS ====================

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

  // ==================== CUSTOMER METHODS ====================

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

  // ==================== TRANSACTION METHODS ====================

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

  // ==================== DELETE ALL DATA FOR USER ====================

  static Future<void> deleteAllUserData(String userId) async {
    // Delete all customers for this user
    final customers = getCustomersByUserId(userId);
    for (var c in customers) {
      await deleteCustomer(c.id);
    }

    // Delete all transactions for this user
    final transactions = getTransactionsByUserId(userId);
    for (var t in transactions) {
      await deleteTransaction(t.id);
    }
  }

  // ==================== CLEAR ALL DATA (Admin/Reset) ====================

  static Future<void> clearAllData() async {
    await customerBox.clear();
    await transactionBox.clear();
    await userBox.clear();
  }

  // ==================== GET COUNTS ====================

  static int getCustomerCount(String userId) {
    return getCustomersByUserId(userId).length;
  }

  static int getTransactionCount(String userId) {
    return getTransactionsByUserId(userId).length;
  }

  static double getTotalCredit(String userId) {
    final transactions = getTransactionsByUserId(userId);
    double total = 0;
    for (var t in transactions) {
      if (t.type == 'credit') {
        total += t.amount;
      }
    }
    return total;
  }

  static double getTotalPayment(String userId) {
    final transactions = getTransactionsByUserId(userId);
    double total = 0;
    for (var t in transactions) {
      if (t.type == 'payment') {
        total += t.amount;
      }
    }
    return total;
  }




// Expense methods
static Future<void> addExpense(Expense expense) async {
  await expenseBox.put(expense.id, expense);
}

static Future<void> updateExpense(Expense expense) async {
  await expenseBox.put(expense.id, expense);
}

static Future<void> deleteExpense(String id) async {
  await expenseBox.delete(id);
}

static List<Expense> getExpensesByUserId(String userId) {
  return expenseBox.values.where((e) => e.userId == userId).toList();
}

static Expense? getExpenseById(String id) {
  return expenseBox.get(id);
}

// Budget methods
static Future<void> saveBudget(Budget budget) async {
  await budgetBox.put(budget.userId, budget);
}

static Budget? getBudget(String userId) {
  return budgetBox.get(userId);
}
}
