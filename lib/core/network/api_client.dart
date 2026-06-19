import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/profile/models/user_address.dart';

class ApiClient {
  ApiClient._() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _accessTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _storage = FlutterSecureStorage();

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8080',
      ),
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  // Address methods
  Future<List<UserAddress>> getMyAddresses() async {
    final response = await dio.get('/users/me/addresses');
    return (response.data as List)
        .map((e) => UserAddress.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserAddress> createAddress(Map<String, dynamic> data) async {
    final response = await dio.post('/users/me/addresses', data: data);
    return UserAddress.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAddress(String id) async {
    await dio.delete('/users/me/addresses/$id');
  }

  Future<void> setDefaultAddress(String id) async {
    await dio.patch('/users/me/addresses/$id/default');
  }

  Future<void> checkout(String addressId) async {
    await dio.post('/orders/checkout', data: {'addressId': addressId});
  }
}
