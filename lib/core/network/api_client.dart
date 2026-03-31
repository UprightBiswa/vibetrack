import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibetreck/core/config/app_env.dart';
import 'package:vibetreck/core/network/api_exception.dart';
import 'package:vibetreck/core/network/auth_token_provider.dart';
import 'package:vibetreck/core/network/network_status_provider.dart';

final apiClientProvider = Provider<Dio?>((ref) {
  final env = ref.watch(appEnvProvider);
  if (!env.hasBackendApi) {
    return null;
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: env.backendApiUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final isOnline = ref.read(isOnlineProvider);
        if (!isOnline) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: const ApiException('No internet connection.'),
              type: DioExceptionType.connectionError,
            ),
          );
          return;
        }

        final token = await ref.read(authTokenProvider).getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final response = error.response;
        final detail = response?.data is Map<String, dynamic>
            ? (response?.data['detail']?.toString() ?? response?.statusMessage)
            : response?.statusMessage;
        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: ApiException(
              detail ?? error.message ?? 'Unexpected API error',
              statusCode: response?.statusCode,
            ),
          ),
        );
      },
    ),
  );

  return dio;
});
