class TallyCompany {
  final String id;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final String accountId;

  TallyCompany({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.accountId,
  });

  factory TallyCompany.fromJson(
    Map<String, dynamic> json,
    String accountId,
  ) {
    return TallyCompany(
      id: json['id'].toString(),
      name: json['company_name']?.toString() ?? 'Unknown',
      isActive: json['is_active'] == true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
      accountId: accountId,
    );
  }
}
