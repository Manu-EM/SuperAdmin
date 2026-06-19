import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/tally_company.dart';
import '../providers/companies_provider.dart';
import '../providers/auth_provider.dart';

class CompanyTile extends ConsumerStatefulWidget {
  final TallyCompany company;
  final int index;
  final bool isLast;

  const CompanyTile({super.key, required this.company, required this.index, this.isLast = false});

  @override
  ConsumerState<CompanyTile> createState() => _CompanyTileState();
}

class _CompanyTileState extends ConsumerState<CompanyTile> {
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy');

    final bgColor = Colors.transparent;
    final hoverColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F5FF);
    final borderColor = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF2F2F2);

    final indexColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFCCCCCC);
    final nameColor = isDark ? const Color(0xFFEFEFEF) : const Color(0xFF1A1A1A);
    final dateColor = isDark ? const Color(0xFF4A4A4A) : const Color(0xFFAAAAAA);

    final actionWidget = _isToggling 
        ? const SizedBox(
            width: 20, 
            height: 20, 
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF7C3AED),
            )
          )
        : CupertinoSwitch(
            activeColor: const Color(0xFF7C3AED),
            trackColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
            value: widget.company.isActive,
            onChanged: (newValue) async {
              setState(() => _isToggling = true);
              final multiService = ref.read(multiSupabaseServiceProvider);
              final superService = ref.read(superAdminServiceProvider);
              
              try {
                // Update the remote client DB
                await multiService.toggleIsActive(
                  widget.company.accountId,
                  widget.company.id,
                  newValue,
                );

                final adminUserName = superService.getCurrentUserName();
                final adminUser = await superService.fetchCurrentAdminUser();

                try {
                  await superService.updateCachedCompanyStatus(
                    clientAccountId: widget.company.accountId,
                    companyName: widget.company.name,
                    isActive: newValue,
                    adminUserId: adminUser?.id,
                    updatedBy: adminUserName,
                  );
                } catch (e) {
                  debugPrint('Failed to update cached_companies: $e');
                }

                try {
                  await superService.writeAuditLog(
                    adminUserId: adminUser?.id,
                    adminUserName: adminUserName,
                    clientAccountId: widget.company.accountId,
                    companyId: widget.company.id,
                    companyName: widget.company.name,
                    action: 'toggle_is_active',
                    oldValue: widget.company.isActive,
                    newValue: newValue,
                  );
                } catch (e) {
                  debugPrint('Failed to write audit log: $e');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to toggle status: $e')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isToggling = false);
                }
                // Refresh UI
                ref.invalidate(companiesProvider);
              }
            },
          );

    final isDesktop = MediaQuery.of(context).size.width > 768;

    if (!isDesktop) {
      return Material(
        color: bgColor,
        child: InkWell(
          onTap: () {},
          hoverColor: hoverColor,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: widget.isLast ? null : Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${widget.index}',
                    style: TextStyle(color: indexColor, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.company.name,
                        style: TextStyle(color: nameColor, fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildStatusBadge(widget.company.isActive, isDark),
                          const SizedBox(width: 8),
                          Text(
                            dateFormat.format(widget.company.createdAt),
                            style: TextStyle(color: dateColor, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                actionWidget,
              ],
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: Material(
        color: bgColor,
        child: InkWell(
          onTap: () {}, // For hover effect
          hoverColor: hoverColor,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: widget.isLast ? null : Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                // # column
                SizedBox(
                  width: 32,
                  child: Text(
                    '${widget.index}',
                    style: TextStyle(color: indexColor, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
                // Company Name
                Expanded(
                  child: Text(
                    widget.company.name,
                    style: TextStyle(color: nameColor, fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Created Date
                SizedBox(
                  width: 110,
                  child: Text(
                    dateFormat.format(widget.company.createdAt),
                    style: TextStyle(color: dateColor, fontSize: 11),
                  ),
                ),
                // Status
                SizedBox(
                  width: 90,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildStatusBadge(widget.company.isActive, isDark),
                  ),
                ),
                // Action
                SizedBox(
                  width: 68,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: actionWidget,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
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
}
