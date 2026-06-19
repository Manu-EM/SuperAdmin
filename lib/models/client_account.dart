class ClientAccount {
  final String id;
  final String supabaseUrl;
  final String anonKey;
  final String? serviceRoleKey;
  final String label;
  final bool isActive;
  final DateTime createdAt;

  ClientAccount({
    required this.id,
    required this.supabaseUrl,
    required this.anonKey,
    this.serviceRoleKey,
    required this.label,
    required this.isActive,
    required this.createdAt,
  });

  factory ClientAccount.fromJson(Map<String, dynamic> json) {
    return ClientAccount(
      id: json['id'].toString(),
      supabaseUrl: json['supabase_url'].toString(),
      anonKey: json['anon_key'].toString(),
      serviceRoleKey: json['service_role_key']?.toString(),
      label: json['label']?.toString() ?? 'Unlabelled',
      isActive: json['is_active'] == true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
    );
  }
}
