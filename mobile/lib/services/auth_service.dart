import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';
import '../models/user.dart';

class AuthService {
  final Dio _dio = createAuthDio();
  final _storage = const FlutterSecureStorage();

  Future<User> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _saveTokens(res.data);
    return User.fromJson(res.data['user']);
  }

  Future<User> register(String name, String email, String password) async {
    final res = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    await _saveTokens(res.data);
    return User.fromJson(res.data['user']);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    await _storage.write(key: 'access_token',  value: data['access_token']);
    await _storage.write(key: 'refresh_token', value: data['refresh_token']);
  }
}
