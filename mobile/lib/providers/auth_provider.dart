import 'package:flutter/foundation.dart';
import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _error;
  bool _loading = false;

  AuthStatus get status  => _status;
  User?       get user   => _user;
  String?     get error  => _error;
  bool        get loading => _loading;

  Future<void> checkAuth() async {
    final loggedIn = await _service.isLoggedIn();
    _status = loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final sw = Stopwatch()..start();
    try {
      _user = await _service.login(email, password);
      _status = AuthStatus.authenticated;
      DatadogSdk.instance.setUserInfo(id: _user!.id, email: _user!.email, name: _user!.name);
      DatadogSdk.instance.rum?.addAction(
        RumActionType.custom,
        'login',
        {'success': true, 'user_id': _user!.id, 'duration_ms': sw.elapsedMilliseconds},
      );
      return true;
    } catch (e) {
      _error = _parseError(e);
      DatadogSdk.instance.rum?.addAction(
        RumActionType.custom,
        'login',
        {'success': false, 'error': _error, 'duration_ms': sw.elapsedMilliseconds},
      );
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _service.register(name, email, password);
      _status = AuthStatus.authenticated;
      DatadogSdk.instance.setUserInfo(id: _user!.id, email: _user!.email, name: _user!.name);
      return true;
    } catch (e) {
      _error = _parseError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    DatadogSdk.instance.clearUserInfo();
    notifyListeners();
  }

  String _parseError(dynamic e) {
    if (e is Exception) {
      final msg = e.toString();
      if (msg.contains('401') || msg.contains('invalid credentials')) {
        return 'Email ou senha incorretos';
      }
      if (msg.contains('409') || msg.contains('already')) {
        return 'Email já cadastrado';
      }
    }
    return 'Erro ao conectar ao servidor';
  }
}
