import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase/supabase.dart';
import '../services/super_admin_service.dart';

final superAdminServiceProvider = Provider<SuperAdminService>((ref) {
  return SuperAdminService();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final service = ref.watch(superAdminServiceProvider);
  return service.client.auth.onAuthStateChange;
});
