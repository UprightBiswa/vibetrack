class AppRoutes {
  static const splash = '/';
  static const auth = '/auth';
  static const home = '/home';
  static const feed = '/feed';
  static const zones = '/zones';
  static const profile = '/profile';
  static const settings = '/settings';
  static const tracking = '/tracking';

  static const shellTabs = <String>[
    home,
    feed,
    zones,
    profile,
    settings,
  ];

  static String summary(String sessionId) => '/summary/$sessionId';
}
