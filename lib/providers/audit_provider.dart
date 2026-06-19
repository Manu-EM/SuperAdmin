import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_log_entry.dart';
import 'auth_provider.dart';

final auditLogProvider = FutureProvider<List<AuditLogEntry>>((ref) async {
  final service = ref.watch(superAdminServiceProvider);
  return await service.fetchAuditLog();
});
