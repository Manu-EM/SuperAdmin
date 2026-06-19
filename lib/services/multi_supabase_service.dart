import 'package:supabase/supabase.dart';
import '../models/client_account.dart';
import '../models/tally_company.dart';

class MultiSupabaseService {
  final List<ClientAccount> accounts;
  final Map<String, SupabaseClient> _clients = {};

  MultiSupabaseService(this.accounts) {
    for (final account in accounts) {
      if (account.supabaseUrl.isNotEmpty && account.anonKey.isNotEmpty) {
        _clients[account.id] = SupabaseClient(
          account.supabaseUrl, 
          account.anonKey,
          authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
        );
      }
    }
  }

  Future<List<TallyCompany>> fetchAllCompanies() async {
    final futures = accounts.map((account) async {
      final client = _clients[account.id];
      if (client == null) {
        return <TallyCompany>[];
      }

      try {
        final response = await client
            .from('tally_companies')
            .select('id, company_name, is_active, created_at')
            .order('created_at', ascending: false);

        final data = response as List<dynamic>;
        return data
            .map((row) => TallyCompany.fromJson(
                row as Map<String, dynamic>, account.id))
            .toList();
      } catch (e) {
        // Handle gracefully, log if needed, but return empty list for this account
        print('Error fetching from ${account.id}: $e');
        return <TallyCompany>[];
      }
    });

    final results = await Future.wait(futures);
    final allCompanies = results.expand((element) => element).toList();
    
    // Global sort by created_at descending
    allCompanies.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return allCompanies;
  }

  Future<void> toggleIsActive(
      String accountId, String companyId, bool newValue) async {
    final client = _clients[accountId];
    if (client == null) return;

    await client
        .from('tally_companies')
        .update({'is_active': newValue})
        .eq('id', companyId);
  }
}
