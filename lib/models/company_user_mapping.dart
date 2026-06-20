class CompanyUserMapping {
  final String id;
  final String companyId;
  final String clientAccountId;
  final String tableName;
  final String idColumn;
  final String? nameColumn;
  final String? roleColumn;
  final String? phoneColumn;
  final String? emailColumn;
  final String? isActiveColumn;

  CompanyUserMapping({
    required this.id,
    required this.companyId,
    required this.clientAccountId,
    required this.tableName,
    this.idColumn = 'id',
    this.nameColumn,
    this.roleColumn,
    this.phoneColumn,
    this.emailColumn,
    this.isActiveColumn,
  });

  factory CompanyUserMapping.fromJson(Map<String, dynamic> json) {
    return CompanyUserMapping(
      id: json['id'].toString(),
      companyId: json['company_id'].toString(),
      clientAccountId: json['client_account_id'].toString(),
      tableName: json['table_name'].toString(),
      idColumn: json['id_column']?.toString() ?? 'id',
      nameColumn: json['name_column']?.toString(),
      roleColumn: json['role_column']?.toString(),
      phoneColumn: json['phone_column']?.toString(),
      emailColumn: json['email_column']?.toString(),
      isActiveColumn: json['is_active_column']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'company_id': companyId,
      'client_account_id': clientAccountId,
      'table_name': tableName,
      'id_column': idColumn,
      'name_column': nameColumn,
      'role_column': roleColumn,
      'phone_column': phoneColumn,
      'email_column': emailColumn,
      'is_active_column': isActiveColumn,
    };
  }
}
