import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service = PaymentService();

  double? _balance;
  String? _accountId;
  List<Transaction> _history = [];
  bool _loading = false;
  bool _transferring = false;
  String? _transferError;
  String? _transferSuccess;
  Timer? _refreshTimer;

  double?          get balance         => _balance;
  String?          get accountId       => _accountId;
  List<Transaction> get history        => _history;
  bool             get loading         => _loading;
  bool             get transferring    => _transferring;
  String?          get transferError   => _transferError;
  String?          get transferSuccess => _transferSuccess;

  Future<void> loadData() async {
    _loading = true;
    notifyListeners();
    try {
      await Future.wait([_fetchBalance(), _fetchHistory()]);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchBalance() async {
    final data = await _service.getBalance();
    _balance   = data['balance'];
    _accountId = data['account_id'];
  }

  Future<void> _fetchHistory() async {
    _history = await _service.getHistory();
  }

  Future<void> refresh() async {
    try {
      await Future.wait([_fetchBalance(), _fetchHistory()]);
      notifyListeners();
    } catch (_) {}
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => refresh());
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<bool> transfer({
    required String toEmail,
    required double amount,
    String? description,
  }) async {
    _transferring = true;
    _transferError = null;
    _transferSuccess = null;
    notifyListeners();
    try {
      final txId = await _service.transfer(
        toEmail: toEmail,
        amount: amount,
        description: description,
      );
      _transferSuccess = 'Transferência #${txId.substring(0, 8)} em processamento!';
      // Refresh data after 1.5s to catch completed status
      Future.delayed(const Duration(milliseconds: 1500), refresh);
      return true;
    } catch (e) {
      _transferError = _parseError(e);
      return false;
    } finally {
      _transferring = false;
      notifyListeners();
    }
  }

  void clearTransferFeedback() {
    _transferError = null;
    _transferSuccess = null;
  }

  void reset() {
    _balance = null;
    _accountId = null;
    _history = [];
    _transferError = null;
    _transferSuccess = null;
    stopAutoRefresh();
    notifyListeners();
  }

  String _parseError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('insufficient')) return 'Saldo insuficiente';
    if (msg.contains('not found'))    return 'Destinatário não encontrado';
    if (msg.contains('yourself'))     return 'Não pode transferir para si mesmo';
    return 'Erro ao processar transferência';
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
