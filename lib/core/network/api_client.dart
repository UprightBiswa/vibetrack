import 'package:dio/dio.dart';
import 'package:vibetreck/core/config/app_env.dart';
import 'package:vibetreck/core/logging/app_logger.dart';
import 'package:vibetreck/core/network/api_exception.dart';
import 'package:vibetreck/core/network/auth_token_provider.dart';

Dio? createApiClient({
  required AppEnv env,
  required AuthTokenProvider authTokenProvider,
  bool Function()? isOnline,
}) {
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
        final online = isOnline?.call() ?? true;
        if (!online) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: const ApiException('No internet connection.'),
              type: DioExceptionType.connectionError,
            ),
          );
          return;
        }

        final token = await authTokenProvider.getAccessToken();
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
      onError: (error, handler) async {
        if (_shouldRetryWithFallback(error, env)) {
          final fallbackOptions = error.requestOptions.copyWith(
            baseUrl: env.effectiveBackendApiFallbackUrl,
            extra: {
              ...error.requestOptions.extra,
              'backendFallbackAttempted': true,
            },
          );
          AppLogger.warning(
            'Backend primary failed; retrying ${fallbackOptions.path} '
            'against ${env.effectiveBackendApiFallbackUrl}',
            error: error,
            stackTrace: error.stackTrace,
          );
          try {
            final fallbackResponse = await dio.fetch<dynamic>(fallbackOptions);
            handler.resolve(fallbackResponse);
            return;
          } on DioException catch (fallbackError) {
            AppLogger.error(
              'Backend fallback failed ${fallbackError.requestOptions.uri}',
              error: fallbackError,
              stackTrace: fallbackError.stackTrace,
            );
            error = fallbackError;
          }
        }

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
          DioExceptionType.badCertificate =>
            'The backend SSL certificate is invalid.',
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
}

bool _shouldRetryWithFallback(DioException error, AppEnv env) {
  if (!env.hasBackendApiFallback) {
    return false;
  }
  if (error.requestOptions.extra['backendFallbackAttempted'] == true) {
    return false;
  }
  return error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.unknown;
}

String _buildConnectionErrorMessage(AppEnv env) {
  if (env.hasBackendApiFallback) {
    return 'Unable to reach the primary backend API at '
        '${env.effectiveBackendApiUrl}. The app also tried the fallback API at '
        '${env.effectiveBackendApiFallbackUrl}.';
  }
  final hint = env.backendSetupHint;
  if (hint != null) {
    return 'Unable to reach the backend API at ${env.effectiveBackendApiUrl}. $hint';
  }
  return 'Unable to reach the backend API at ${env.effectiveBackendApiUrl}. '
      'Make sure the FastAPI server is running and reachable from the device.';
}
