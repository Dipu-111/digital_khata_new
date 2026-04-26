import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_khata_new/database/hive_service.dart';
import 'package:digital_khata_new/models/customer.dart';
import 'package:digital_khata_new/models/user.dart';
import 'package:digital_khata_new/providers/transaction_provider.dart';
import 'auth_provider.dart';

final customerProvider = StateNotifierProvider<CustomerNotifier, List<Customer>>((ref) {
  final user = ref.watch(authProvider);
  return CustomerNotifier(ref, user);
});

class CustomerNotifier extends StateNotifier<List<Customer>> {
  final Ref _ref;
  final User? currentUser;
  
  CustomerNotifier(this._ref, this.currentUser) : super([]) {
    _loadCustomers();
  }
  
  void _loadCustomers() {
    if (currentUser != null) {
      state = HiveService.getCustomersByUserId(currentUser!.id);
    }
  }
  
  Future<void> addCustomer({
    required String name,
    required String phone,
    required String address,
  }) async {
    if (currentUser == null) return;
    
    final customer = Customer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUser!.id,
      name: name,
      phone: phone,
      address: address,
      createdAt: DateTime.now(),
    );
    
    await HiveService.addCustomer(customer);
    _loadCustomers();
  }
  
  // ✅ Edit Customer
  Future<void> updateCustomer({
    required String id,
    required String name,
    required String phone,
    required String address,
  }) async {
    final existingCustomer = HiveService.getCustomerById(id);
    if (existingCustomer == null) return;
    
    final updatedCustomer = Customer(
      id: existingCustomer.id,
      userId: existingCustomer.userId,
      name: name,
      phone: phone,
      address: address,
      createdAt: existingCustomer.createdAt,
    );
    
    await HiveService.updateCustomer(updatedCustomer);
    _loadCustomers();
  }
  
  // ✅ Delete Customer (also delete all related transactions)
  Future<void> deleteCustomer(String id) async {
    // Delete all transactions for this customer
    final transactions = HiveService.getTransactionsByCustomer(id);
    for (var t in transactions) {
      await HiveService.deleteTransaction(t.id);
    }
    
    // Delete customer
    await HiveService.deleteCustomer(id);
    
    // Refresh transaction provider
    _ref.read(transactionProvider.notifier).refresh();
    _loadCustomers();
  }
  //backup
  Future<void> restoreCustomers(List<Customer> restoredCustomers) async {
  if (currentUser == null) return;
  
  // Clear existing customers for this user
  final existingCustomers = HiveService.getCustomersByUserId(currentUser!.id);
  for (var c in existingCustomers) {
    await HiveService.deleteCustomer(c.id);
  }
  
  // Add restored customers
  for (var c in restoredCustomers) {
    await HiveService.addCustomer(c);
  }
  
  _loadCustomers();
}
}