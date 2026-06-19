class AdminUser {
  final String id;
  final String authUserId;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;

  AdminUser({
    required this.id,
    required this.authUserId,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'].toString(),
      authUserId: json['auth_user_id'].toString(),
      name: json['name'].toString(),
      email: json['email'].toString(),
      role: json['role']?.toString() ?? 'admin',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
    );
  }
}
