import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase/supabase.dart';
import '../providers/companies_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/audit_provider.dart';
import '../widgets/company_tile.dart';
import 'add_client_screen.dart';
import 'audit_log_screen.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Widget _buildSummaryCard(String title, String count, Color accentColor, IconData icon, bool isDark, bool isDesktop) {
    Widget card = Card(
      margin: EdgeInsets.zero,
      elevation: isDark ? 0 : 2,
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
        side: BorderSide(
          color: accentColor,
          width: isDesktop ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20.0 : 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accentColor, size: isDesktop ? 28 : 20),
            SizedBox(height: isDesktop ? 16 : 8),
            Text(
              count,
              style: TextStyle(
                fontSize: isDesktop ? 36 : 24, 
                fontWeight: FontWeight.w700, 
                color: isDark ? Colors.white : Colors.black87,
                height: 1.1,
              ),
            ),
            SizedBox(height: isDesktop ? 4 : 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isDesktop ? 12 : 10, 
                  fontWeight: FontWeight.w600, 
                  color: Colors.grey, 
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Expanded(child: card);
  }

  void _showUserDetailsDialog() async {
    final superService = ref.read(superAdminServiceProvider);
    final user = superService.client.auth.currentUser;
    final name = superService.getCurrentUserName() ?? 'Unknown';
    final email = user?.email ?? 'Unknown';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: $name', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Email: $email'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Note: Supabase updateUser requires the user to be logged in. 
              // To update password securely, we pass the new password.
              try {
                final superService = ref.read(superAdminServiceProvider);
                await superService.client.auth.updateUser(
                  UserAttributes(password: newPasswordController.text.trim()),
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientAccountsAsync = ref.watch(clientAccountsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final superService = ref.watch(superAdminServiceProvider);
    final adminUserName = superService.getCurrentUserName() ?? 'Admin';
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
            height: 1.0,
          ),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/app_icon.jpg',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tally Super Admin',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87, 
                        fontWeight: FontWeight.w600, 
                        fontSize: 20
                      ),
                    ),
                  ),
                  const Text(
                    'Control Panel',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_business, color: isDark ? Colors.grey : Colors.black54),
            tooltip: 'Add Client Account',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddClientScreen()),
              );
              if (mounted) {
                ref.invalidate(clientAccountsProvider);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.restore_page, color: isDark ? Colors.grey : Colors.black54),
            tooltip: 'Audit Log',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuditLogScreen()),
              );
              if (mounted) {
                ref.invalidate(auditLogProvider);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: isDark ? Colors.grey : Colors.black54),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(clientAccountsProvider);
              ref.invalidate(companiesProvider);
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.settings, color: isDark ? Colors.grey : Colors.black54),
            onSelected: (value) async {
              if (value == 'theme') {
                ref.read(themeModeProvider.notifier).toggleTheme();
              } else if (value == 'details') {
                _showUserDetailsDialog();
              } else if (value == 'password') {
                _showChangePasswordDialog();
              } else if (value == 'logout') {
                final service = ref.read(superAdminServiceProvider);
                await service.client.auth.signOut();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'theme',
                child: ListTile(
                  leading: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
                  title: Text(themeMode == ThemeMode.dark ? 'Switch to Light Mode' : 'Switch to Dark Mode'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'details',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('User Details'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'password',
                child: ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Change Password'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: clientAccountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error fetching accounts: $error', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(clientAccountsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (accounts) {
          final companiesAsyncValue = ref.watch(companiesProvider);
          return companiesAsyncValue.when(
            data: (allCompanies) {
              final isDesktop = MediaQuery.of(context).size.width > 768;
              final activeCount = allCompanies.where((c) => c.isActive).length;
              final inactiveCount = allCompanies.length - activeCount;

              // Build accountId → label lookup from the outer accounts list
              final Map<String, String> accountLabelMap = {
                for (final acc in accounts) acc.id: acc.label,
              };

              // Group colours (deterministic by sorted label index)
              const groupColors = [
                Color(0xFF7C3AED),
                Color(0xFF0891B2),
                Color(0xFFD97706),
                Color(0xFF059669),
                Color(0xFFDC2626),
                Color(0xFFDB2777),
              ];

              // Build grouped map: accountId → companies
              final Map<String, List<dynamic>> grouped = {};
              for (final company in allCompanies) {
                final accountId = company.accountId;
                grouped.putIfAbsent(accountId, () => []).add(company);
              }
              
              final sortedAccountIds = grouped.keys.toList()..sort((a, b) {
                final labelA = accountLabelMap[a] ?? 'Unlabelled';
                final labelB = accountLabelMap[b] ?? 'Unlabelled';
                return labelA.compareTo(labelB);
              });

              // Filter each group by search query; hide empty groups
              final Map<String, List<dynamic>> filteredGrouped = {};
              for (final accountId in sortedAccountIds) {
                final label = accountLabelMap[accountId] ?? 'Unlabelled';
                final rows = (grouped[accountId] ?? []).where((company) {
                  final nameMatch = company.name.toLowerCase().contains(searchQuery.toLowerCase());
                  final labelMatch = label.toLowerCase().contains(searchQuery.toLowerCase());
                  return nameMatch || labelMatch;
                }).toList();
                rows.sort((a, b) => a.name.compareTo(b.name));
                if (rows.isNotEmpty) filteredGrouped[accountId] = rows;
              }
              
              final visibleAccountIds = filteredGrouped.keys.toList()..sort((a, b) {
                final labelA = accountLabelMap[a] ?? 'Unlabelled';
                final labelB = accountLabelMap[b] ?? 'Unlabelled';
                return labelA.compareTo(labelB);
              });

              // Build a flat list of items: 'header' | ('group', label) | ('row', company, index, isLast)
              final List<Map<String, dynamic>> tableItems = [];
              if (isDesktop) {
                tableItems.add({'type': 'header'});
              }
              for (int gi = 0; gi < visibleAccountIds.length; gi++) {
                final accountId = visibleAccountIds[gi];
                final label = accountLabelMap[accountId] ?? 'Unlabelled';
                final rows = filteredGrouped[accountId]!;
                tableItems.add({'type': 'group', 'label': label, 'count': rows.length, 'colorIndex': gi % groupColors.length});
                for (int ri = 0; ri < rows.length; ri++) {
                  final isLastRow = ri == rows.length - 1 && gi == visibleAccountIds.length - 1;
                  tableItems.add({'type': 'row', 'company': rows[ri], 'index': ri + 1, 'isLast': isLastRow});
                }
              }

              final scaffoldBg = isDark ? const Color(0xFF0F0F0F) : Colors.grey.shade50;
              final borderColor = isDark ? const Color(0xFF222222) : const Color(0xFFEBEBEB);
              final tableBg = isDark ? const Color(0xFF161616) : Colors.white;
              final headerBg = isDark ? const Color(0xFF111111) : const Color(0xFFFAFAFA);
              final headerTextStyle = TextStyle(
                color: isDark ? const Color(0xFF444444) : const Color(0xFFAAAAAA),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              );

              // Search bar widget
              final searchBarWidget = Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: TextField(
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search companies...',
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
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  },
                ),
              );

              // Single table header row (inside the card)
              Widget buildTableHeader() => Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: headerBg,
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 32, child: Text('#', style: headerTextStyle)),
                    Expanded(child: Text('COMPANY NAME', style: headerTextStyle)),
                    SizedBox(width: 110, child: Text('CREATED DATE', style: headerTextStyle)),
                    SizedBox(width: 90, child: Text('STATUS', style: headerTextStyle)),
                    SizedBox(width: 68, child: Text('ACTION', style: headerTextStyle)),
                  ],
                ),
              );

              // Group label row
              Widget buildGroupRow(String label, int count, Color dotColor) {
                final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
                final subtextColor = isDark ? const Color(0xFF888888) : const Color(0xFF666666);
                final pillBg = isDark ? const Color(0xFF111111) : const Color(0xFFF0F0F0);
                final pillBorder = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
                final lineColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
                final groupRowBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF9F9F9);
                return Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: groupRowBg,
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: pillBg,
                          border: Border.all(color: pillBorder),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count == 1 ? '1 company' : '$count companies',
                          style: TextStyle(fontSize: 10, color: subtextColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Container(height: 1, color: lineColor)),
                    ],
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  // ── Greeting + Cards: scroll away ──
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getGreeting()}, $adminUserName 👋',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Here is what\'s happening with your clients today.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryCard('TOTAL COMPANIES', allCompanies.length.toString(), const Color(0xFF7C3AED), Icons.business, isDark, isDesktop),
                              const SizedBox(width: 8),
                              _buildSummaryCard('ACTIVE', activeCount.toString(), const Color(0xFF16A34A), Icons.check_circle, isDark, isDesktop),
                              const SizedBox(width: 8),
                              _buildSummaryCard('INACTIVE', inactiveCount.toString(), const Color(0xFFDC2626), Icons.cancel, isDark, isDesktop),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Search bar: always visible, sticks at top ──
                  SliverAppBar(
                    pinned: true,
                    primary: false,
                    automaticallyImplyLeading: false,
                    backgroundColor: scaffoldBg,
                    toolbarHeight: 0,
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(72),
                      child: searchBarWidget,
                    ),
                  ),

                  // ── Grouped table ──
                  if (visibleAccountIds.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No companies found', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            const SizedBox(height: 8),
                            const Text('Try a different search term', style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverToBoxAdapter(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: tableBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              children: List.generate(tableItems.length, (index) {
                                final item = tableItems[index];
                                if (item['type'] == 'header') {
                                  return isDesktop ? buildTableHeader() : const SizedBox.shrink();
                                } else if (item['type'] == 'group') {
                                  final color = groupColors[item['colorIndex'] as int];
                                  return buildGroupRow(item['label'] as String, item['count'] as int, color);
                                } else {
                                  return CompanyTile(
                                    company: item['company'],
                                    index: item['index'] as int,
                                    isLast: item['isLast'] as bool,
                                  );
                                }
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
          );
        },
      ),
    );
  }
}

