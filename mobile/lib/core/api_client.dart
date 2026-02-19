import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// On Android emulator use 10.0.2.2; on iOS simulator or device use your machine's IP
const String _authBaseUrl    = 'http://localhost:8001';
const String _paymentBaseUrl = 'http://localhost:8002';

final _storage = FlutterSecureStorage();

Dio createAuthDio() => _buildDio(_authBaseUrl);
Dio createPaymentDio() => _buildDio(_paymentBaseUrl);

Dio _buildDio(String baseUrl) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  // Inject JWT
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _storage.read(key: 'access_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          // Retry original request with new token
          final token = await _storage.read(key: 'access_token');
          final opts = error.requestOptions;
          opts.headers['Authorization'] = 'Bearer $token';
          try {
            final response = await dio.fetch(opts);
            return handler.resolve(response);
          } catch (e) {
            return handler.next(error);
          }
        }
      }
      handler.next(error);
    },
  ));

  return dio;
}

Future<bool> _tryRefreshToken() async {
  final refreshToken = await _storage.read(key: 'refresh_token');
  if (refreshToken == null) return false;

  try {
    final dio = Dio(BaseOptions(baseUrl: _authBaseUrl));
    final res = await dio.post('/auth/refresh', data: {'refresh_token': refreshToken});
    await _storage.write(key: 'access_token',  value: res.data['access_token']);
    await _storage.write(key: 'refresh_token', value: res.data['refresh_token']);
    return true;
  } catch (_) {
    await _storage.deleteAll();
    return false;
  }
}
