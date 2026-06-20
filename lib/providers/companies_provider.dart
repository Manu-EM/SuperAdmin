import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/multi_supabase_service.dart';
import '../models/tally_company.dart';
import '../models/client_account.dart';
import 'auth_provider.dart';

final clientAccountsProvider = FutureProvider<List<ClientAccount>>((ref) async {
  final superAdminService = ref.watch(superAdminServiceProvider);
  return await superAdminService.fetchClientAccounts();
});

final multiSupabaseServiceProvider = Provider<MultiSupabaseService>((ref) {
  final accountsAsyncValue = ref.watch(clientAccountsProvider);
  final superAdminService = ref.watch(superAdminServiceProvider);

  // Return an empty service if accounts haven't loaded yet.
  final accounts = accountsAsyncValue.valueOrNull ?? [];
  return MultiSupabaseService(accounts, superAdminService);
});

final companiesProvider = FutureProvider<List<TallyCompany>>((ref) async {
  final service = ref.watch(multiSupabaseServiceProvider);
  // Wait for accounts to load before fetching companies
  await ref.watch(clientAccountsProvider.future);
  
  return await service.fetchAllCompanies();
});
