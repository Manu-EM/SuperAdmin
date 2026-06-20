import 'package:supabase/supabase.dart';
import '../models/company_user_mapping.dart';
import '../models/app_user.dart';

class CompanyUsersService {
  final SupabaseClient superAdminClient;

  CompanyUsersService(this.superAdminClient);

  Future<List<AppUser>> fetchUsers(
      CompanyUserMapping mapping, SupabaseClient clientProjectClient) async {
    try {
      final columnsToSelect = <String>[mapping.idColumn];
      if (mapping.nameColumn != null && mapping.nameColumn!.isNotEmpty) {
        columnsToSelect.add(mapping.nameColumn!);
      }
      if (mapping.roleColumn != null && mapping.roleColumn!.isNotEmpty) {
        columnsToSelect.add(mapping.roleColumn!);
      }
      if (mapping.phoneColumn != null && mapping.phoneColumn!.isNotEmpty) {
        columnsToSelect.add(mapping.phoneColumn!);
      }
      if (mapping.emailColumn != null && mapping.emailColumn!.isNotEmpty) {
        columnsToSelect.add(mapping.emailColumn!);
      }
      if (mapping.isActiveColumn != null &&
          mapping.isActiveColumn!.isNotEmpty) {
        columnsToSelect.add(mapping.isActiveColumn!);
      }

      final selectString = columnsToSelect.join(', ');

      final response = await clientProjectClient
          .from(mapping.tableName)
          .select(selectString);

      final List<dynamic> data = response as List<dynamic>;

      final users = data.map((row) {
        return AppUser(
          id: row[mapping.idColumn].toString(),
          name: mapping.nameColumn != null
              ? row[mapping.nameColumn]?.toString()
              : null,
          role: mapping.roleColumn != null
              ? row[mapping.roleColumn]?.toString()
              : null,
          phone: mapping.phoneColumn != null
              ? row[mapping.phoneColumn]?.toString()
              : null,
          email: mapping.emailColumn != null
              ? row[mapping.emailColumn]?.toString()
              : null,
          isActive: mapping.isActiveColumn != null
              ? (row[mapping.isActiveColumn] as bool?)
              : null,
        );
      }).toList();

      if (users.isNotEmpty && mapping.companyId.isNotEmpty) {
        try {
          final payload = users.map((u) => {
            'company_id': mapping.companyId,
            'client_account_id': mapping.clientAccountId,
            'client_user_id': u.id,
            'name': u.name,
            'role': u.role,
            'phone': u.phone,
            'email': u.email,
            'is_active': u.isActive,
            'last_updated_at': DateTime.now().toIso8601String(),
          }).toList();

          await superAdminClient.from('cached_app_users').upsert(
            payload,
            onConflict: 'company_id, client_user_id',
          );
        } catch (e) {
          print('Warning: Failed to sync to cached_app_users: $e');
        }
      }

      return users;
    } catch (e) {
      print('Error fetching company users: $e');
      throw Exception('Could not load users for this company');
    }
  }

  Future<void> toggleUserActive(
    CompanyUserMapping mapping,
    SupabaseClient clientProjectClient,
    String userId,
    bool newValue,
  ) async {
    if (mapping.isActiveColumn == null || mapping.isActiveColumn!.isEmpty) {
      return;
    }

    try {
      final response = await clientProjectClient
          .from(mapping.tableName)
          .update({mapping.isActiveColumn!: newValue})
          .eq(mapping.idColumn, userId)
          .select();

      final data = response as List<dynamic>;
      if (data.isEmpty) {
        throw Exception('0 rows updated. Check database permissions (RLS) or if user exists.');
      }

      if (mapping.companyId.isNotEmpty) {
        try {
          await superAdminClient
              .from('cached_app_users')
              .update({'is_active': newValue, 'last_updated_at': DateTime.now().toIso8601String()})
              .eq('company_id', mapping.companyId)
              .eq('client_user_id', userId);
        } catch (syncError) {
          print('Warning: Failed to sync toggle to cached_app_users: $syncError');
        }
      }
    } catch (e) {
      print('Error toggling user active state: $e');
      throw Exception('Failed to update user status');
    }
  }
}
