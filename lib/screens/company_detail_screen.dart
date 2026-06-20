import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/tally_company.dart';
import '../providers/company_user_provider.dart';
import '../providers/companies_provider.dart';
import '../providers/auth_provider.dart';
import 'company_user_mapping_setup_screen.dart';

class CompanyDetailScreen extends ConsumerStatefulWidget {
  final TallyCompany company;

  const CompanyDetailScreen({super.key, required this.company});

  @override
  ConsumerState<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends ConsumerState<CompanyDetailScreen> {
  String _searchQuery = '';

  TallyCompany get company => widget.company;

  Widget _buildStatusBadge(bool isActive, bool isDark) {
    Color bg, border, dot, text;
    String label;

    if (isActive) {
      bg = isDark ? const Color(0xFF052E16) : const Color(0xFFF0FDF4);
      border = isDark ? const Color(0xFF14532D) : const Color(0xFFBBF7D0);
      dot = isDark ? const Color(0xFF4ADE80) : const Color(0xFF22C55E);
      text = isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
      label = 'Active';
    } else {
      bg = isDark ? const Color(0xFF2D0707) : const Color(0xFFFEF2F2);
      border = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA);
      dot = isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
      text = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
      label = 'Inactive';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F0F) : Colors.grey.shade50;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dateFormat = DateFormat('dd MMM yyyy');

    final accounts = ref.watch(clientAccountsProvider).valueOrNull ?? [];
    final accountLabel = accounts
        .where((a) => a.id == company.accountId)
        .firstOrNull
        ?.label ??
        'Unknown Account';

    final mappingAsync = ref.watch(companyMappingProvider(company));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: borderColor, height: 1.0),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              company.name,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 20),
            ),
            Text(
              accountLabel,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Top Info Card (scrolls away) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  boxShadow: isDark ? null : [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1)),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _buildStatusBadge(company.isActive, isDark),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Created On', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(company.createdAt),
                          style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Users Section header (scrolls away) ──
          SliverToBoxAdapter(
            child: mappingAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
              ),
              error: (err, stack) => Center(child: Text('Error loading mapping: $err')),
              data: (mapping) {
                if (mapping == null) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: _buildSetupEmptyState(context, isDark, cardColor, borderColor, textColor),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // ── Sticky Search Bar ──
          if (mappingAsync.valueOrNull != null)
            SliverAppBar(
              pinned: true,
              primary: false,
              automaticallyImplyLeading: false,
              backgroundColor: bgColor,
              toolbarHeight: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(68),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: bgColor,
                  child: TextField(
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search by name or role...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
              ),
            ),

          // ── Users List ──
          if (mappingAsync.valueOrNull != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverToBoxAdapter(
                child: _buildUsersList(context, isDark, borderColor, textColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSetupEmptyState(
    BuildContext context, bool isDark, Color cardColor, Color borderColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.settings_outlined, size: 40, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Users view not set up for this company',
            style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure where to find user data',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompanyUserMappingSetupScreen(company: company),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Set Up Users View', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(
    BuildContext context, bool isDark, Color borderColor, Color textColor) {
    final usersAsync = ref.watch(companyUsersProvider(company));
    final mapping = ref.read(companyMappingProvider(company)).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        usersAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            ),
          ),
          error: (err, stack) => Center(
            child: Column(
              children: [
                Text('Error: $err', style: const TextStyle(color: Colors.red)),
                TextButton(
                  onPressed: () => ref.invalidate(companyUsersProvider(company)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (users) {
            // Apply search filter
            final filtered = _searchQuery.isEmpty
                ? users
                : users.where((u) {
                    final q = _searchQuery.toLowerCase();
                    return (u.name?.toLowerCase().contains(q) ?? false) ||
                        (u.role?.toLowerCase().contains(q) ?? false);
                  }).toList();

            // Sort: active users first, then inactive/null
            filtered.sort((a, b) {
              final aActive = a.isActive ?? false;
              final bActive = b.isActive ?? false;
              if (aActive && !bActive) return -1;
              if (!aActive && bActive) return 1;
              return (a.name ?? '').compareTo(b.name ?? '');
            });

            if (filtered.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.search_off, size: 40, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No users found for this company'
                          : 'No users match "$_searchQuery"',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            final isDesktop = MediaQuery.of(context).size.width > 768;
            final headerTextColor = isDark ? Colors.white : const Color(0xFF555555);
            final greyText = isDark ? const Color(0xFF9CA3AF) : const Color(0xFFAAAAAA);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Users count header
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('Users', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${filtered.length}${filtered.length != users.length ? ' of ${users.length}' : ''}',
                          style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Container(height: 1, color: borderColor)),
                    ],
                  ),
                ),
                if (isDesktop)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F5FF),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text('NAME', style: TextStyle(color: headerTextColor, fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(flex: 1, child: Text('ROLE', style: TextStyle(color: headerTextColor, fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('EMAIL', style: TextStyle(color: headerTextColor, fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(flex: 1, child: Text('PHONE', style: TextStyle(color: headerTextColor, fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(flex: 1, child: Text('STATUS', style: TextStyle(color: headerTextColor, fontSize: 11, fontWeight: FontWeight.bold))),
                        SizedBox(width: 60, child: Text('ACTION', style: TextStyle(color: headerTextColor, fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    border: isDesktop
                        ? Border(
                            left: BorderSide(color: borderColor),
                            right: BorderSide(color: borderColor),
                            bottom: BorderSide(color: borderColor),
                          )
                        : Border.all(color: borderColor),
                    borderRadius: isDesktop
                        ? const BorderRadius.vertical(bottom: Radius.circular(8))
                        : BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: isDesktop
                        ? const BorderRadius.vertical(bottom: Radius.circular(8))
                        : BorderRadius.circular(8),
                    child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    final rowBgColor = index % 2 == 0
                        ? (isDark ? const Color(0xFF161616) : Colors.white)
                        : (isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50);

                    final nameColor = isDark ? const Color(0xFFEFEFEF) : const Color(0xFF1A1A1A);

                    Widget buildRoleChip(String? role) {
                      if (role == null) return Text('—', style: TextStyle(color: greyText));
                      return Text(
                        role,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }

                    Widget buildActionToggle() {
                      if (mapping?.isActiveColumn == null) {
                        return Text('—', style: TextStyle(color: greyText));
                      }
                      return _UserToggleSwitch(
                        company: company,
                        userId: user.id,
                        userName: user.name,
                        isActive: user.isActive ?? false,
                        isDark: isDark,
                      );
                    }

                    if (!isDesktop) {
                      return Container(
                        color: rowBgColor,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    user.name ?? '—',
                                    style: TextStyle(color: user.name == null ? greyText : nameColor, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                buildRoleChip(user.role),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(user.email ?? '—', style: TextStyle(color: greyText, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(user.phone ?? '—', style: TextStyle(color: greyText, fontSize: 12)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                user.isActive == null
                                    ? Text('—', style: TextStyle(color: greyText))
                                    : _buildStatusBadge(user.isActive!, isDark),
                                buildActionToggle(),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      height: 52,
                      color: rowBgColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              user.name ?? '—',
                              style: TextStyle(color: user.name == null ? greyText : nameColor, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: buildRoleChip(user.role),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              user.email ?? '—',
                              style: TextStyle(color: greyText, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              user.phone ?? '—',
                              style: TextStyle(color: greyText, fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: user.isActive == null
                                  ? Text('—', style: TextStyle(color: greyText))
                                  : _buildStatusBadge(user.isActive!, isDark),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: buildActionToggle(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    ),
      ],
    );
  }
}

class _UserToggleSwitch extends ConsumerStatefulWidget {
  final TallyCompany company;
  final String userId;
  final String? userName;
  final bool isActive;
  final bool isDark;

  const _UserToggleSwitch({
    required this.company,
    required this.userId,
    this.userName,
    required this.isActive,
    required this.isDark,
  });

  @override
  ConsumerState<_UserToggleSwitch> createState() => _UserToggleSwitchState();
}

class _UserToggleSwitchState extends ConsumerState<_UserToggleSwitch> {
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    if (_isToggling) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF7C3AED),
        ),
      );
    }

    return CupertinoSwitch(
      activeColor: const Color(0xFF7C3AED),
      trackColor: widget.isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
      value: widget.isActive,
      onChanged: (newValue) async {
        setState(() => _isToggling = true);

        try {
          final mapping = await ref.read(companyMappingProvider(widget.company).future);
          if (mapping == null) return;

          final multiService = ref.read(multiSupabaseServiceProvider);
          final client = multiService.getClientForAccount(widget.company.accountId);

          if (client == null) throw Exception('Client not found');

          final usersService = ref.read(companyUsersServiceProvider);
          await usersService.toggleUserActive(mapping, client, widget.userId, newValue);

          final superAdminService = ref.read(superAdminServiceProvider);
          final currentAdmin = await superAdminService.fetchCurrentAdminUser();
          final adminName = currentAdmin?.name ?? superAdminService.getCurrentUserName() ?? 'Unknown Admin';
          final adminId = currentAdmin?.id;

          await superAdminService.writeAuditLog(
            adminUserId: adminId,
            adminUserName: adminName,
            clientAccountId: widget.company.accountId,
            companyId: widget.company.id,
            companyName: widget.company.name,
            action: 'toggle_app_user_active (${widget.userName ?? widget.userId})',
            oldValue: widget.isActive,
            newValue: newValue,
          );

          ref.invalidate(companyUsersProvider(widget.company));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.userName ?? 'User'} is now ${newValue ? 'Active' : 'Inactive'}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to toggle status: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isToggling = false);
          }
        }
      },
    );
  }
}
