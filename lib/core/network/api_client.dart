import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibetreck/core/config/app_env.dart';
import 'package:vibetreck/core/logging/app_logger.dart';
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
      baseUrl: env.effectiveBackendApiUrl,
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
          AppLogger.info('Attached bearer token for ${options.path}');
        } else {
          AppLogger.warning('No bearer token available for ${options.path}');
        }

        AppLogger.info('API request ${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.info(
          'API response ${response.statusCode} ${response.requestOptions.uri}',
        );
        handler.next(response);
      },
      onError: (error, handler) {
        final response = error.response;
        final responseDetail = response?.data is Map<String, dynamic>
            ? (response?.data['detail']?.toString() ?? response?.statusMessage)
            : response?.statusMessage;

        final message = switch (error.type) {
          DioExceptionType.connectionError => _buildConnectionErrorMessage(env),
          DioExceptionType.connectionTimeout =>
            'Connection timed out while contacting the backend API.',
          DioExceptionType.receiveTimeout =>
            'The backend API took too long to respond.',
          DioExceptionType.badCertificate => 'The backend SSL certificate is invalid.',
          DioExceptionType.badResponse =>
            responseDetail ?? 'The backend returned an unexpected response.',
          DioExceptionType.cancel => 'The request was cancelled.',
          DioExceptionType.sendTimeout => 'Sending data to the backend timed out.',
          DioExceptionType.unknown =>
            responseDetail ?? error.message ?? 'Unexpected API error',
        };

        AppLogger.error(
          'API error ${response?.statusCode ?? 'n/a'} ${error.requestOptions.uri}',
          error: error,
          stackTrace: error.stackTrace,
        );

        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: ApiException(
              message,
              statusCode: response?.statusCode,
            ),
          ),
        );
      },
    ),
  );

  return dio;
});

String _buildConnectionErrorMessage(AppEnv env) {
  final hint = env.backendSetupHint;
  if (hint != null) {
    return 'Unable to reach the backend API at ${env.effectiveBackendApiUrl}. $hint';
  }
  return 'Unable to reach the backend API at ${env.effectiveBackendApiUrl}. Make sure the FastAPI server is running and reachable from the device.';
}

