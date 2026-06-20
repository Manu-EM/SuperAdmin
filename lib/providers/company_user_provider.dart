import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/company_user_mapping_service.dart';
import '../services/company_users_service.dart';
import '../models/company_user_mapping.dart';
import '../models/app_user.dart';
import '../models/tally_company.dart';
import 'auth_provider.dart';
import 'companies_provider.dart';

final companyUserMappingServiceProvider =
    Provider<CompanyUserMappingService>((ref) {
  final superAdminClient = ref.watch(superAdminServiceProvider).client;
  return CompanyUserMappingService(superAdminClient);
});

final companyUsersServiceProvider = Provider<CompanyUsersService>((ref) {
  final superAdminClient = ref.watch(superAdminServiceProvider).client;
  return CompanyUsersService(superAdminClient);
});

final companyMappingProvider = FutureProvider.family<CompanyUserMapping?, TallyCompany>(
    (ref, company) async {
  final service = ref.watch(companyUserMappingServiceProvider);
  return await service.fetchMapping(company.accountId, company.name);
});

final companyUsersProvider = FutureProvider.family<List<AppUser>, TallyCompany>(
    (ref, company) async {
  final mapping = await ref.watch(companyMappingProvider(company).future);

  if (mapping == null) {
    return [];
  }

  final multiService = ref.watch(multiSupabaseServiceProvider);
  final client = multiService.getClientForAccount(company.accountId);

  if (client == null) {
    throw Exception('Supabase client not found for this account.');
  }

  final usersService = ref.watch(companyUsersServiceProvider);
  return await usersService.fetchUsers(mapping, client);
});
