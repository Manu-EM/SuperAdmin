import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/audit_log_entry.dart';
import '../providers/audit_provider.dart';
import '../providers/theme_provider.dart';

enum AuditFilter { all, active, inactive }
enum AuditSort { dateDesc, userName }

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  AuditFilter _currentFilter = AuditFilter.all;
  AuditSort _currentSort = AuditSort.dateDesc;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final auditLogAsync = ref.watch(auditLogProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F0F0F) : Colors.grey.shade50;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputFillColor = isDark ? const Color(0xFF222222) : Colors.grey.shade100;

    final dateFormat = DateFormat('dd MMM yyyy  HH:mm');
    final today = DateTime.now();

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
          child: Container(
            color: borderColor,
            height: 1.0,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audit Log',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 20),
            ),
            const Text(
              'Activity history',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isDark ? Colors.grey : Colors.black54),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(auditLogProvider);
            },
          ),
        ],
      ),
      body: auditLogAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error', style: TextStyle(color: textColor)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                onPressed: () => ref.invalidate(auditLogProvider),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        data: (allEntries) {
          final totalCount = allEntries.length;
          final todayCount = allEntries.where((e) => 
            e.createdAt.year == today.year && 
            e.createdAt.month == today.month && 
            e.createdAt.day == today.day
          ).length;

          var filteredEntries = allEntries.where((entry) {
            if (_currentFilter == AuditFilter.active) return entry.newValue == true;
            if (_currentFilter == AuditFilter.inactive) return entry.newValue == false;
            return true;
          }).where((entry) {
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase();
            return entry.companyName.toLowerCase().contains(query) ||
                   entry.adminName.toLowerCase().contains(query);
          }).toList();

          filteredEntries.sort((a, b) {
            if (_currentSort == AuditSort.userName) {
              int cmp = a.adminName.toLowerCase().compareTo(b.adminName.toLowerCase());
              if (cmp == 0) {
                return b.createdAt.compareTo(a.createdAt);
              }
              return cmp;
            } else {
              return b.createdAt.compareTo(a.createdAt);
            }
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _buildSummaryChip('TOTAL ACTIONS', totalCount.toString(), cardColor, borderColor, textColor),
                    const SizedBox(width: 12),
                    _buildSummaryChip('TODAY', todayCount.toString(), cardColor, borderColor, textColor),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          style: TextStyle(color: textColor, fontSize: 13),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search company or Users...',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                            filled: true,
                            fillColor: inputFillColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                            ),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: inputFillColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: PopupMenuButton<AuditSort>(
                        icon: const Icon(Icons.sort, color: Colors.grey, size: 20),
                        tooltip: 'Sort By',
                        color: cardColor,
                        onSelected: (AuditSort sort) {
                          setState(() {
                            _currentSort = sort;
                          });
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<AuditSort>>[
                          PopupMenuItem<AuditSort>(
                            value: AuditSort.dateDesc,
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: _currentSort == AuditSort.dateDesc ? const Color(0xFF7C3AED) : Colors.grey),
                                const SizedBox(width: 8),
                                Text('Date (Newest)', style: TextStyle(color: textColor, fontSize: 13)),
                              ],
                            ),
                          ),
                          PopupMenuItem<AuditSort>(
                            value: AuditSort.userName,
                            child: Row(
                              children: [
                                Icon(Icons.person, size: 16, color: _currentSort == AuditSort.userName ? const Color(0xFF7C3AED) : Colors.grey),
                                const SizedBox(width: 8),
                                Text('Admin Name', style: TextStyle(color: textColor, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', AuditFilter.all, cardColor, borderColor, isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active', AuditFilter.active, cardColor, borderColor, isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('Inactive', AuditFilter.inactive, cardColor, borderColor, isDark),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: filteredEntries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history_toggle_off, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No activity yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Toggle actions will appear here',
                            style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF7C3AED),
                      backgroundColor: cardColor,
                      onRefresh: () async {
                        ref.invalidate(auditLogProvider);
                        try {
                          await ref.read(auditLogProvider.future);
                        } catch (_) {}
                      },
                      child: ListView.builder(
                        itemCount: filteredEntries.length,
                        itemBuilder: (context, index) {
                          final entry = filteredEntries[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6, left: 16, right: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: cardColor,
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Row 1: Company name + Date
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.companyName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      dateFormat.format(entry.createdAt),
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                // Row 2: Status change
                                Row(
                                  children: [
                                    if (entry.newValue == true) ...[
                                      const Text('Inactive', style: TextStyle(color: Color(0xFFF87171), fontSize: 11, fontWeight: FontWeight.w500)),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 5),
                                        child: Icon(Icons.arrow_forward, size: 11, color: Colors.grey),
                                      ),
                                      const Text('Active', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 11, fontWeight: FontWeight.w500)),
                                    ] else ...[
                                      const Text('Active', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 11, fontWeight: FontWeight.w500)),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 5),
                                        child: Icon(Icons.arrow_forward, size: 11, color: Colors.grey),
                                      ),
                                      const Text('Inactive', style: TextStyle(color: Color(0xFFF87171), fontSize: 11, fontWeight: FontWeight.w500)),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Row 3: Centered username
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                                      const SizedBox(width: 3),
                                      Text(
                                        'by ${entry.adminName}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
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
    );
  }

  Widget _buildSummaryChip(String label, String value, Color cardColor, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, AuditFilter filter, Color cardColor, Color borderColor, bool isDark) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4C1D95) : cardColor,
          border: Border.all(color: isSelected ? const Color(0xFF7C3AED) : borderColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.grey : Colors.black87),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
