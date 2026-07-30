import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'token_storage.dart';

/// Thrown when refresh also fails — the app should treat this as a hard
/// logout and route to the login screen, clearing all role-bound state.
class SessionExpiredException implements Exception {}

/// Single Dio client for the whole app. Attaches the access token to every
/// request and transparently refreshes on a 401, retrying the original
/// request exactly once. All API calls in every feature go through this —
/// never construct Dio ad hoc in a screen or repository.
class ApiClient {
  ApiClient(this._tokenStorage) : _dio = Dio(BaseOptions(baseUrl: ApiConfig.apiBase)) {
    // Separate, interceptor-free client for the refresh call itself, so the
    // refresh request can never recursively trigger another refresh.
    _refreshDio = Dio(BaseOptions(baseUrl: ApiConfig.authBase));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final access = await _tokenStorage.accessToken;
          if (access != null) {
            options.headers['Authorization'] = 'Bearer $access';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final alreadyRetried = error.requestOptions.extra['retried'] == true;

          if (isUnauthorized && !alreadyRetried) {
            try {
              final newAccess = await _refreshAccessToken();
              final retryOptions = error.requestOptions
                ..headers['Authorization'] = 'Bearer $newAccess'
                ..extra['retried'] = true;
              final response = await _dio.fetch(retryOptions);
              return handler.resolve(response);
            } catch (_) {
              await _tokenStorage.clear();
              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  error: SessionExpiredException(),
                  type: DioExceptionType.unknown,
                ),
              );
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  late final Dio _refreshDio;
  final TokenStorage _tokenStorage;

  Dio get dio => _dio;

  Future<String> _refreshAccessToken() async {
    final refresh = await _tokenStorage.refreshToken;
    if (refresh == null) throw SessionExpiredException();

    final response = await _refreshDio.post('/refresh', data: {'refresh': refresh});
    final newAccess = response.data['access'] as String;
    await _tokenStorage.updateAccessToken(newAccess);
    return newAccess;
  }
}
