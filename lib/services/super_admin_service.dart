import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import '../config/super_admin_config.dart';
import '../models/client_account.dart';
import '../models/admin_user.dart';
import '../models/tally_company.dart';
import '../models/audit_log_entry.dart';
import '../utils/my_auth_storage.dart';

class SuperAdminService {
  late final SupabaseClient client;

  SuperAdminService() {
    if (kSuperAdminUrl.isNotEmpty && kSuperAdminAnonKey.isNotEmpty) {
      client = SupabaseClient(
        kSuperAdminUrl, 
        kSuperAdminAnonKey,
        authOptions: AuthClientOptions(pkceAsyncStorage: MyAuthStorage()),
      );
    } else {
      // Initialize with dummy values so the app doesn't crash before keys are set,
      // but it will fail on any network requests.
      client = SupabaseClient(
        'https://dummy.supabase.co', 
        'dummy',
        authOptions: AuthClientOptions(pkceAsyncStorage: MyAuthStorage()),
      );
    }

    // Persist the session whenever it changes
    client.auth.onAuthStateChange.listen((data) async {
      final prefs = await SharedPreferences.getInstance();
      if (data.session != null) {
        prefs.setString('super_admin_session', jsonEncode(data.session!.toJson()));
      } else if (data.event == AuthChangeEvent.signedOut) {
        prefs.remove('super_admin_session');
      }
    });
  }

  Future<void> initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionStr = prefs.getString('super_admin_session');
    if (sessionStr != null) {
      try {
        await client.auth.recoverSession(sessionStr);
      } catch (e) {
        debugPrint('Failed to recover session: $e');
        await prefs.remove('super_admin_session');
      }
    }
  }

  Future<List<ClientAccount>> fetchClientAccounts() async {
    final response = await client
        .from('client_accounts')
        .select('*')
        .order('created_at', ascending: true);

    final data = response as List<dynamic>;
    return data
        .map((row) => ClientAccount.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Returns the current user's display name directly from the auth session.
  /// This never fails due to RLS since it reads local session data only.
  String? getCurrentUserName() {
    final user = client.auth.currentUser;
    if (user == null) return null;
    return user.userMetadata?['name']?.toString() 
        ?? user.email?.split('@').first 
        ?? 'Unknown';
  }

  Future<AdminUser?> fetchCurrentAdminUser() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await client
          .from('admin_users')
          .select('*')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (response != null) {
        return AdminUser.fromJson(response as Map<String, dynamic>);
      }

      // Not found in DB — auto-create the record
      final name = user.userMetadata?['name']?.toString() 
          ?? user.email?.split('@').first 
          ?? 'Unknown';
      final insertResponse = await client.from('admin_users').insert({
        'auth_user_id': user.id,
        'name': name,
        'email': user.email ?? '',
        'role': 'admin',
      }).select().single();

      return AdminUser.fromJson(insertResponse as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching/creating admin user: $e');
    }
    return null;
  }

  Future<void> writeAuditLog({
    required String? adminUserId,
    required String? adminUserName,
    required String clientAccountId,
    required String companyId,
    required String companyName,
    required String action,
    required bool oldValue,
    required bool newValue,
  }) async {
    await client.from('audit_log').insert({
      // Omit admin_user_id to avoid FK constraint violations when admin record is missing.
      // Use updated_by_name (text) as the human-readable identifier instead.
      if (adminUserName != null) 'updated_by_name': adminUserName,
      'client_account_id': clientAccountId,
      'company_id': companyId,
      'company_name': companyName,
      'action': action,
      'old_value': oldValue,
      'new_value': newValue,
    });
  }

  Future<String> addClientAccount({
    required String supabaseUrl,
    required String anonKey,
  }) async {
    final response = await client.from('client_accounts').insert({
      'supabase_url': supabaseUrl,
      'anon_key': anonKey,
      'is_active': true,
    }).select('id').single();
    
    return response['id'] as String;
  }

  Future<void> addCachedCompanies(String clientAccountId, List<TallyCompany> companies) async {
    if (companies.isEmpty) return;
    
    final payload = companies.map((c) => {
      'client_account_id': clientAccountId,
      'company_name': c.name,
      'is_active': c.isActive,
      'created_at': c.createdAt.toIso8601String(),
      'last_updated_at': DateTime.now().toIso8601String(),
    }).toList();
    
    await client.from('cached_companies').insert(payload);
  }

  Future<void> updateCachedCompanyStatus({
    required String clientAccountId,
    required String companyName,
    required bool isActive,
    String? adminUserId,
    String? updatedBy,
  }) async {
    await client
        .from('cached_companies')
        .update({
          'is_active': isActive,
          'last_updated_at': DateTime.now().toIso8601String(),
          if (updatedBy != null) 'updated_by': updatedBy,
        })
        .eq('client_account_id', clientAccountId)
        .eq('company_name', companyName);
  }

  /// Upserts all companies from a given client account into `cached_companies`.
  /// Called every time the Super Admin app fetches live companies, so the cache
  /// stays in sync automatically when clients add / rename companies.
  Future<void> syncCachedCompanies(
      String clientAccountId, List<TallyCompany> companies) async {
    if (companies.isEmpty) return;

    try {
      final payload = companies.map((c) => {
        'client_account_id': clientAccountId,
        'company_name': c.name,
        'is_active': c.isActive,
        'created_at': c.createdAt.toIso8601String(),
        'last_updated_at': DateTime.now().toIso8601String(),
      }).toList();

      // onConflict uses the unique constraint on (client_account_id, company_name)
      await client.from('cached_companies').upsert(
        payload,
        onConflict: 'client_account_id, company_name',
      );
    } catch (e) {
      // Non-fatal: just log — the live UI data is still correct
      print('Warning: failed to sync cached_companies: $e');
    }
  }

  Future<List<AuditLogEntry>> fetchAuditLog() async {
    final response = await client
        .from('audit_log')
        .select('*')
        .order('created_at', ascending: false)
        .limit(200);

    final data = response as List<dynamic>;
    return data
        .map((row) => AuditLogEntry.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
