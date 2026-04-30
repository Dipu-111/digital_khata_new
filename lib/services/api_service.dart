import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // CHANGE THIS TO YOUR COMPUTER'S IP ADDRESS
  static const String baseUrl = 'http://192.168.1.100:5000';
  
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));
  
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Save token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  // Get token
  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // Clear token
  static Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  // Add token to requests
  static void _addTokenInterceptor() {
    _dio.interceptors.clear();
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // ==================== AUTH APIs ====================

  static Future<Map<String, dynamic>> register({
    required String shopName,
    required String ownerName,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/register',
        data: {
          'shop_name': shopName,
          'owner_name': ownerName,
          'phone': phone,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/login',
        data: {
          'phone': phone,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  // ==================== CUSTOMER APIs ====================

  static Future<List<dynamic>> getCustomers() async {
    _addTokenInterceptor();
    try {
      final response = await _dio.get('/api/customers');
      return response.data['customers'];
    } on DioException catch (e) {
      print('Error: ${e.message}');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addCustomer({
    required String name,
    required String phone,
    required String address,
  }) async {
    _addTokenInterceptor();
    try {
      final response = await _dio.post(
        '/api/customers',
        data: {
          'name': name,
          'phone': phone,
          'address': address,
        },
      );
      return response.data;
    } on DioException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  static Future<Map<String, dynamic>> updateCustomer({
    required String id,
    required String name,
    required String phone,
    required String address,
  }) async {
    _addTokenInterceptor();
    try {
      final response = await _dio.put(
        '/api/customers/$id',
        data: {
          'name': name,
          'phone': phone,
          'address': address,
        },
      );
      return response.data;
    } on DioException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  static Future<Map<String, dynamic>> deleteCustomer(String id) async {
    _addTokenInterceptor();
    try {
      final response = await _dio.delete('/api/customers/$id');
      return response.data;
    } on DioException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  // ==================== TRANSACTION APIs ====================

  static Future<List<dynamic>> getTransactions() async {
    _addTokenInterceptor();
    try {
      final response = await _dio.get('/api/transactions');
      return response.data['transactions'];
    } on DioException catch (e) {
      print('Error: ${e.message}');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addTransaction({
    required String customerId,
    required String type,
    required double amount,
    required String description,
    required String date,
  }) async {
    _addTokenInterceptor();
    try {
      final response = await _dio.post(
        '/api/transactions',
        data: {
          'customer_id': customerId,
          'type': type,
          'amount': amount,
          'description': description,
          'date': date,
        },
      );
      return response.data;
    } on DioException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  static Future<Map<String, dynamic>> deleteTransaction(String id) async {
    _addTokenInterceptor();
    try {
      final response = await _dio.delete('/api/transactions/$id');
      return response.data;
    } on DioException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  // ==================== EXPENSE APIs ====================

  static Future<List<dynamic>> getExpenses() async {
    _addTokenInterceptor();
    try {
      final response = await _dio.get('/api/expenses');
      return response.data['expenses'];
    } on DioException catch (e) {
      print('Error: ${e.message}');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addExpense({
    required double amount,
    required String category,
    required String date,
    required String description,
    required String paymentMethod,
  }) async {
    _addTokenInterceptor();
    try {
      final response = await _dio.post(
        '/api/expenses',
        data: {
          'amount': amount,
          'category': category,
          'date': date,
          'description': description,
          'payment_method': paymentMethod,
        },
      );
      return response.data;
    } on DioException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }
}