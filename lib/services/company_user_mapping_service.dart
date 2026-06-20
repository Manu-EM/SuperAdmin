import 'package:supabase/supabase.dart';
import '../models/company_user_mapping.dart';

class CompanyUserMappingService {
  final SupabaseClient superAdminClient;

  CompanyUserMappingService(this.superAdminClient);

  Future<CompanyUserMapping?> fetchMapping(String accountId, String companyName) async {
    try {
      final cachedCompany = await superAdminClient
          .from('cached_companies')
          .select('id')
          .eq('client_account_id', accountId)
          .eq('company_name', companyName)
          .maybeSingle();

      if (cachedCompany == null) return null;

      final realCompanyId = cachedCompany['id'].toString();

      final response = await superAdminClient
          .from('company_user_mapping')
          .select()
          .eq('company_id', realCompanyId)
          .maybeSingle();

      if (response != null) {
        return CompanyUserMapping.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching mapping for company $companyName: $e');
      return null;
    }
  }

  Future<void> saveMapping(CompanyUserMapping mapping, String companyName) async {
    final cachedCompany = await superAdminClient
        .from('cached_companies')
        .select('id')
        .eq('client_account_id', mapping.clientAccountId)
        .eq('company_name', companyName)
        .maybeSingle();

    if (cachedCompany == null) {
      throw Exception('Company not found in Super Admin cache.');
    }

    final realCompanyId = cachedCompany['id'].toString();
    final payload = mapping.toJson();
    payload['company_id'] = realCompanyId; // Ensure we use the foreign key ID

    await superAdminClient.from('company_user_mapping').upsert(
          payload,
          onConflict: 'company_id',
        );
  }

  Future<bool> testMapping(
      CompanyUserMapping mapping, SupabaseClient clientProjectClient) async {
    try {
      await clientProjectClient
          .from(mapping.tableName)
          .select(mapping.idColumn)
          .limit(1);
      return true;
    } catch (e) {
      print('Test mapping failed: $e');
      return false;
    }
  }
}
