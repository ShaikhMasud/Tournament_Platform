import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';
import '../models/session.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// All auth HTTP calls live here — screens never call Dio directly. Talks to
/// the accounts app endpoints built earlier: /auth/signup, /auth/login,
/// /auth/refresh, /auth/logout, /auth/session.
class AuthRepository {
  AuthRepository(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<Session> signup({
    required String email,
    required String username,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _apiClient.dio.post('/auth/signup', data: {
        'email': email,
        'username': username,
        'password': password,
        'display_name': displayName,
      });
      await _tokenStorage.saveTokens(
        access: response.data['access'] as String,
        refresh: response.data['refresh'] as String,
      );
      return Session.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(_extractError(e));
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      await _tokenStorage.saveTokens(
        access: response.data['access'] as String,
        refresh: response.data['refresh'] as String,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException('Incorrect email or password');
      }
      throw AuthException(_extractError(e));
    }
  }

  Future<Session> fetchSession() async {
    try {
      final response = await _apiClient.dio.get('/auth/session');
      return Session.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(_extractError(e));
    }
  }

  /// Clears tokens AND is where any role/tournament-bound client-side cache
  /// (Riverpod providers, in-memory stores) must be invalidated too — see
  /// AuthProviders.logout() for the state-clearing side of this.
  Future<void> logout() async {
    final refresh = await _tokenStorage.refreshToken;
    try {
      if (refresh != null) {
        await _apiClient.dio.post('/auth/logout', data: {'refresh': refresh});
      }
    } on DioException {
      // Best-effort server-side blacklist; clear local tokens regardless so
      // the device is logged out even if the network call fails.
    } finally {
      await _tokenStorage.clear();
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data.isNotEmpty) {
      final firstValue = data.values.first;
      if (firstValue is List && firstValue.isNotEmpty) return firstValue.first.toString();
      return firstValue.toString();
    }
    return 'Something went wrong. Please check your connection and try again.';
  }
}
