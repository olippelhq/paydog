import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/transaction.dart';

class PaymentService {
  final Dio _dio = createPaymentDio();

  Future<Map<String, dynamic>> getBalance() async {
    final res = await _dio.get('/payments/balance');
    return {
      'balance':    (res.data['balance'] as num).toDouble(),
      'account_id': res.data['account_id'] as String,
    };
  }

  Future<String> transfer({
    required String toEmail,
    required double amount,
    String? description,
  }) async {
    final res = await _dio.post('/payments/transfer', data: {
      'to_email':    toEmail,
      'amount':      amount,
      'description': description ?? '',
    });
    return res.data['transaction_id'] as String;
  }

  Future<List<Transaction>> getHistory() async {
    final res = await _dio.get('/payments/history');
    final list = res.data['transactions'] as List<dynamic>;
    return list.map((e) => Transaction.fromJson(e)).toList();
  }
}
