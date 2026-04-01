import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibetreck/core/config/app_env.dart';
import 'package:vibetreck/core/network/api_client.dart';
import 'package:vibetreck/core/network/auth_token_provider.dart';
import 'package:vibetreck/features/auth/data/auth_repository.dart';
import 'package:vibetreck/features/feed/data/feed_repository.dart';
import 'package:vibetreck/features/notifications/data/notification_repository.dart';
import 'package:vibetreck/features/profile/data/profile_repository.dart';
import 'package:vibetreck/features/tracking/data/session_repository.dart';
import 'package:vibetreck/features/zones/data/zone_repository.dart';
import 'package:vibetreck/shared/services/media_upload_service.dart';

class AppServices {
  AppServices._({
    required this.env,
    required this.supabaseClient,
    required this.authRepository,
    required this.profileRepository,
    required this.sessionRepository,
    required this.feedRepository,
    required this.zoneRepository,
    required this.notificationRepository,
    required this.mediaUploadService,
    required this.authTokenProvider,
    required this.apiClient,
  });

  factory AppServices.fromEnv(AppEnv env) {
    final supabaseClient = env.hasSupabase ? Supabase.instance.client : null;
    final authRepository = supabaseClient == null
        ? LocalAuthRepository()
        : SupabaseAuthRepository(
            supabaseClient,
            redirectTo: env.supabaseRedirectUrl,
          );
    final authTokenProvider = SupabaseAuthTokenProvider(enabled: env.hasSupabase);
    final apiClient = createApiClient(
      env: env,
      authTokenProvider: authTokenProvider,
    );

    final profileRepository = apiClient != null
        ? ApiProfileRepository(apiClient)
        : (supabaseClient == null
              ? LocalProfileRepository()
              : SupabaseProfileRepository(supabaseClient));
    final sessionRepository = apiClient != null
        ? ApiSessionRepository(apiClient)
        : (supabaseClient == null
              ? LocalSessionRepository()
              : SupabaseSessionRepository(supabaseClient));
    final feedRepository = apiClient != null
        ? ApiFeedRepository(apiClient)
        : (supabaseClient == null
              ? LocalFeedRepository()
              : SupabaseFeedRepository(supabaseClient));
    final zoneRepository = apiClient != null
        ? ApiZoneRepository(apiClient)
        : (supabaseClient == null
              ? LocalZoneRepository()
              : SupabaseZoneRepository(supabaseClient));
    final notificationRepository = apiClient != null
        ? ApiNotificationRepository(apiClient)
        : LocalNotificationRepository();
    final mediaUploadService = supabaseClient == null
        ? LocalMediaUploadService()
        : SupabaseMediaUploadService(supabaseClient);

    return AppServices._(
      env: env,
      supabaseClient: supabaseClient,
      authRepository: authRepository,
      profileRepository: profileRepository,
      sessionRepository: sessionRepository,
      feedRepository: feedRepository,
      zoneRepository: zoneRepository,
      notificationRepository: notificationRepository,
      mediaUploadService: mediaUploadService,
      authTokenProvider: authTokenProvider,
      apiClient: apiClient,
    );
  }

  final AppEnv env;
  final SupabaseClient? supabaseClient;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final SessionRepository sessionRepository;
  final FeedRepository feedRepository;
  final ZoneRepository zoneRepository;
  final NotificationRepository notificationRepository;
  final MediaUploadService mediaUploadService;
  final AuthTokenProvider authTokenProvider;
  final Dio? apiClient;
}
