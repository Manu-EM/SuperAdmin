class AuditLogEntry {
  final String id;
  final String companyId;
  final String companyName;
  final String clientAccountId;
  final String action;
  final bool oldValue;
  final bool newValue;
  final DateTime createdAt;
  final String adminName;

  AuditLogEntry({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.clientAccountId,
    required this.action,
    required this.oldValue,
    required this.newValue,
    required this.createdAt,
    required this.adminName,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    // Determine adminName from nested admin_users join or fallback to updated_by_name
    String name = 'Unknown Admin';
    if (json['admin_users'] != null && json['admin_users']['name'] != null) {
      name = json['admin_users']['name'].toString();
    } else if (json['updated_by_name'] != null) {
      name = json['updated_by_name'].toString();
    }

    return AuditLogEntry(
      id: json['id'].toString(),
      companyId: json['company_id'].toString(),
      companyName: json['company_name']?.toString() ?? 'Unknown Company',
      clientAccountId: json['client_account_id'].toString(),
      action: json['action']?.toString() ?? 'toggle',
      oldValue: json['old_value'] == true,
      newValue: json['new_value'] == true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
      adminName: name,
    );
  }
}
