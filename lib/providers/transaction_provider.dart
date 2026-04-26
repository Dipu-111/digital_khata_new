import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_khata_new/database/hive_service.dart';
import 'package:digital_khata_new/models/transaction.dart';
import 'package:digital_khata_new/models/user.dart';
import 'auth_provider.dart';

final transactionProvider = StateNotifierProvider<TransactionNotifier, List<Transaction>>((ref) {
  final user = ref.watch(authProvider);
  return TransactionNotifier(ref, user);
});

class TransactionNotifier extends StateNotifier<List<Transaction>> {
  final Ref _ref;
  final User? currentUser;
  
  TransactionNotifier(this._ref, this.currentUser) : super([]) {
    _loadTransactions();
  }
  
  void _loadTransactions() {
    if (currentUser != null) {
      state = HiveService.getTransactionsByUserId(currentUser!.id);
    }
  }
  
  Future<void> refresh() {
    _loadTransactions();
    return Future.value();
  }
  
  Future<void> addTransaction({
    required String customerId,
    required String type,
    required double amount,
    required String description,
  }) async {
    if (currentUser == null) return;
    
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUser!.id,
      customerId: customerId,
      type: type,
      amount: amount,
      description: description,
      date: DateTime.now(),
    );
    
    await HiveService.addTransaction(transaction);
    _loadTransactions();
  }
  
  // ✅ Edit Transaction
  Future<void> updateTransaction({
    required String id,
    required String customerId,
    required String type,
    required double amount,
    required String description,
  }) async {
    final existingTransaction = HiveService.getTransactionById(id);
    if (existingTransaction == null) return;
    
    final updatedTransaction = Transaction(
      id: existingTransaction.id,
      userId: existingTransaction.userId,
      customerId: customerId,
      type: type,
      amount: amount,
      description: description,
      date: existingTransaction.date,
      updatedAt: DateTime.now(),
    );
    
    await HiveService.updateTransaction(updatedTransaction);
    _loadTransactions();
  }
  
  // ✅ Delete Transaction
  Future<void> deleteTransaction(String id) async {
    await HiveService.deleteTransaction(id);
    _loadTransactions();
  }
  
  List<Transaction> getTransactionsByCustomer(String customerId) {
    return state.where((t) => t.customerId == customerId).toList();
  }
  
  double getCustomerBalance(String customerId) {
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
  
  double getTotalDue() {
    if (currentUser == null) return 0;
    return HiveService.getTotalDue(currentUser!.id);
  }
  Future<void> restoreTransactions(List<Transaction> restoredTransactions) async {
  if (currentUser == null) return;
  
  // Clear existing transactions for this user
  final existingTransactions = HiveService.getTransactionsByUserId(currentUser!.id);
  for (var t in existingTransactions) {
    await HiveService.deleteTransaction(t.id);
  }
  
  // Add restored transactions
  for (var t in restoredTransactions) {
    await HiveService.addTransaction(t);
  }
  
  _loadTransactions();
}
}