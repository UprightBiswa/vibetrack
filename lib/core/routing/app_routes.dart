class AppRoutes {
  static const splash = '/';
  static const auth = '/auth';
  static const home = '/home';
  static const feed = '/feed';
  static const zones = '/zones';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const settings = '/settings';
  static const tracking = '/tracking';
  static const feedPostPath = '/feed/post/:postId';
  static const leaderboard = '/leaderboard';

  static const shellTabs = <String>[
    home,
    feed,
    zones,
    profile,
    settings,
  ];

  static String summary(String sessionId) => '/summary/$sessionId';
  static String publicProfile(String profileId) => '/profile/view/$profileId';
  static String feedPost(String postId) => '/feed/post/$postId';
}
