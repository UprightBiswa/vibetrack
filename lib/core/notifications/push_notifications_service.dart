import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vibetreck/core/logging/app_logger.dart';
import 'package:vibetreck/core/notifications/notification_navigation.dart';
import 'package:vibetreck/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:vibetreck/features/auth/presentation/bloc/auth_state.dart';
import 'package:vibetreck/features/notifications/application/notification_controller.dart';

class PushNotificationsService {
  PushNotificationsService({
    required Dio? apiClient,
    required AuthCubit authCubit,
    required NotificationsCubit notificationsCubit,
    required GlobalKey<NavigatorState> navigatorKey,
  })  : _apiClient = apiClient,
        _authCubit = authCubit,
        _notificationsCubit = notificationsCubit,
        _navigatorKey = navigatorKey;

  final Dio? _apiClient;
  final AuthCubit _authCubit;
  final NotificationsCubit _notificationsCubit;
  final GlobalKey<NavigatorState> _navigatorKey;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  bool _initialized = false;
  String? _lastRegisteredToken;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      AppLogger.info('Push notifications skipped on web');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      AppLogger.info(
        'FCM permission status: ${settings.authorizationStatus.name}',
      );

      final initialToken = await messaging.getToken();
      if (initialToken != null && initialToken.isNotEmpty) {
        AppLogger.info('FCM token acquired');
      } else {
        AppLogger.warning('FCM token not available yet');
      }

      _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
        (token) async {
          AppLogger.info('FCM token refreshed');
          await _registerCurrentToken(token);
        },
        onError: (Object error, StackTrace stackTrace) {
          AppLogger.error(
            'FCM token refresh listener failed',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );

      _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
        AppLogger.info(
          'Foreground FCM message received: ${message.messageId ?? 'unknown'}',
        );
        _notificationsCubit.refresh();
        _showForegroundMessage(message);
      });

      _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        AppLogger.info('FCM message opened app: ${message.messageId ?? 'unknown'}');
        _notificationsCubit.refresh();
        _openMessageTarget(message);
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.info('FCM initial message detected: ${initialMessage.messageId ?? 'unknown'}');
        Future<void>.delayed(const Duration(milliseconds: 400), () {
          _openMessageTarget(initialMessage);
        });
      }

      _authSubscription = _authCubit.stream.listen(_handleAuthStateChanged);
      await _handleAuthStateChanged(_authCubit.state);
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Push notifications initialization skipped or failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> unregisterCurrentDevice() async {
    final token = _lastRegisteredToken ?? await FirebaseMessaging.instance.getToken();
    final authUser = _authCubit.state.user;
    if (token == null || token.isEmpty || _apiClient == null || authUser == null) {
      return;
    }

    try {
      await _apiClient.post(
        '/api/v1/notifications/device-token/delete',
        data: {'token': token},
      );
      AppLogger.info('Removed FCM device token for ${authUser.id}');
      _lastRegisteredToken = null;
      await _notificationsCubit.refresh();
    } on DioException catch (error, stackTrace) {
      AppLogger.error(
        'Failed to delete FCM device token',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _handleAuthStateChanged(AuthState state) async {
    final user = state.user;
    if (user == null) {
      AppLogger.info('FCM token registration skipped because user is signed out');
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      AppLogger.warning('No FCM token available to register for ${user.id}');
      return;
    }

    await _registerCurrentToken(token);
  }

  Future<void> _registerCurrentToken(String token) async {
    if (_apiClient == null) {
      AppLogger.warning('FCM token registration skipped because backend API is unavailable');
      return;
    }

    final authUser = _authCubit.state.user;
    if (authUser == null) {
      AppLogger.info('FCM token registration deferred until user signs in');
      return;
    }

    try {
      await _apiClient.post(
        '/api/v1/notifications/device-token',
        data: {
          'token': token,
          'platform': defaultTargetPlatform.name,
        },
      );
      _lastRegisteredToken = token;
      await _notificationsCubit.refresh();
      AppLogger.info('Registered FCM device token for ${authUser.id}');
    } on DioException catch (error, stackTrace) {
      AppLogger.error(
        'Failed to register FCM device token',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected error while registering FCM device token',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _showForegroundMessage(RemoteMessage message) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final title = message.notification?.title ?? message.data['title'] ?? 'New notification';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(body.isEmpty ? title : '$title\n$body'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => _openMessageTarget(message),
          ),
        ),
      );
  }

  void _openMessageTarget(RemoteMessage message) {
    final notificationId = message.data['notification_id'];
    if (notificationId != null && notificationId.toString().isNotEmpty) {
      Future<void>(() async {
        try {
          await _notificationsCubit.markRead(notificationId.toString());
        } catch (_) {}
      });
    }
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    openNotificationTarget(
      context,
      route: message.data['route'] ?? '',
      entityId: message.data['entity_id'] ?? '',
      payload: message.data,
    );
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _openedAppSubscription?.cancel();
    _authSubscription?.cancel();
  }
}
