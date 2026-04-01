import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibetreck/core/logging/app_logger.dart';
import 'package:vibetreck/core/network/api_client.dart';
import 'package:vibetreck/core/notifications/notification_navigation.dart';
import 'package:vibetreck/core/routing/app_router.dart';
import 'package:vibetreck/features/auth/application/auth_controller.dart';
import 'package:vibetreck/features/notifications/application/notification_controller.dart';
import 'package:vibetreck/shared/models/app_user.dart';

final pushNotificationsServiceProvider = Provider<PushNotificationsService>((ref) {
  final service = PushNotificationsService(ref);
  ref.onDispose(service.dispose);
  return service;
});

class PushNotificationsService {
  PushNotificationsService(this._ref);

  final Ref _ref;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
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
        _ref.read(notificationActionsProvider).refresh();
        _showForegroundMessage(message);
      });

      _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        AppLogger.info('FCM message opened app: ${message.messageId ?? 'unknown'}');
        _ref.read(notificationActionsProvider).refresh();
        _openMessageTarget(message);
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.info('FCM initial message detected: ${initialMessage.messageId ?? 'unknown'}');
        Future<void>.delayed(const Duration(milliseconds: 400), () {
          _openMessageTarget(initialMessage);
        });
      }

      _ref.listen<AsyncValue<AppUser?>>(authUserProvider, (previous, next) async {
        final user = next.asData?.value;
        await _handleAuthUserChanged(user);
      }, fireImmediately: true);
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
    final dio = _ref.read(apiClientProvider);
    final authUser = _ref.read(authUserProvider).asData?.value;
    if (token == null || token.isEmpty || dio == null || authUser == null) {
      return;
    }

    try {
      await dio.post(
        '/api/v1/notifications/device-token/delete',
        data: {'token': token},
      );
      AppLogger.info('Removed FCM device token for ${authUser.id}');
      _lastRegisteredToken = null;
      _ref.read(notificationActionsProvider).refresh();
    } on DioException catch (error, stackTrace) {
      AppLogger.error(
        'Failed to delete FCM device token',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _handleAuthUserChanged(AppUser? user) async {
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
    final dio = _ref.read(apiClientProvider);
    if (dio == null) {
      AppLogger.warning('FCM token registration skipped because backend API is unavailable');
      return;
    }

    final authUser = _ref.read(authUserProvider).asData?.value;
    if (authUser == null) {
      AppLogger.info('FCM token registration deferred until user signs in');
      return;
    }

    try {
      await dio.post(
        '/api/v1/notifications/device-token',
        data: {
          'token': token,
          'platform': defaultTargetPlatform.name,
        },
      );
      _lastRegisteredToken = token;
      _ref.read(notificationActionsProvider).refresh();
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
    final context = _ref.read(navigatorKeyProvider).currentContext;
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
          await _ref.read(notificationActionsProvider).markRead(notificationId.toString());
        } catch (_) {}
      });
    }
    final context = _ref.read(navigatorKeyProvider).currentContext;
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
  }
}
