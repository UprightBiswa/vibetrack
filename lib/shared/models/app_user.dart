class AppUser {
  const AppUser({required this.id, required this.email, this.isGuest = false});

  final String id;
  final String email;
  final bool isGuest;
}
