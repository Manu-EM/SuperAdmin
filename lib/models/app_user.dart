class AppUser {
  final String id;
  final String? name;
  final String? role;
  final String? phone;
  final String? email;
  final bool? isActive;

  AppUser({
    required this.id,
    this.name,
    this.role,
    this.phone,
    this.email,
    this.isActive,
  });
}
