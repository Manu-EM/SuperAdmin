import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase/supabase.dart';
import '../models/tally_company.dart';
import '../models/company_user_mapping.dart';
import '../providers/company_user_provider.dart';
import '../providers/companies_provider.dart';

class CompanyUserMappingSetupScreen extends ConsumerStatefulWidget {
  final TallyCompany company;

  const CompanyUserMappingSetupScreen({super.key, required this.company});

  @override
  ConsumerState<CompanyUserMappingSetupScreen> createState() =>
      _CompanyUserMappingSetupScreenState();
}

class _CompanyUserMappingSetupScreenState
    extends ConsumerState<CompanyUserMappingSetupScreen> {
  String _selectedTableOption = 'users';
  final _customTableNameController = TextEditingController();

  final _idColumnController = TextEditingController(text: 'id');
  final _nameColumnController = TextEditingController();
  final _roleColumnController = TextEditingController();
  final _phoneColumnController = TextEditingController();
  final _emailColumnController = TextEditingController();
  final _isActiveColumnController = TextEditingController();

  bool _isTesting = false;
  bool _isSaving = false;
  bool _testSuccess = false;

  List<Map<String, dynamic>>? _previewData;

  @override
  void dispose() {
    _customTableNameController.dispose();
    _idColumnController.dispose();
    _nameColumnController.dispose();
    _roleColumnController.dispose();
    _phoneColumnController.dispose();
    _emailColumnController.dispose();
    _isActiveColumnController.dispose();
    super.dispose();
  }

  String get _currentTableName {
    return _selectedTableOption == 'Custom...'
        ? _customTableNameController.text.trim()
        : _selectedTableOption;
  }

  CompanyUserMapping _buildMapping() {
    return CompanyUserMapping(
      id: '',
      companyId: widget.company.id,
      clientAccountId: widget.company.accountId,
      tableName: _currentTableName,
      idColumn: _idColumnController.text.trim(),
      nameColumn: _nameColumnController.text.trim().isEmpty
          ? null
          : _nameColumnController.text.trim(),
      roleColumn: _roleColumnController.text.trim().isEmpty
          ? null
          : _roleColumnController.text.trim(),
      phoneColumn: _phoneColumnController.text.trim().isEmpty
          ? null
          : _phoneColumnController.text.trim(),
      emailColumn: _emailColumnController.text.trim().isEmpty
          ? null
          : _emailColumnController.text.trim(),
      isActiveColumn: _isActiveColumnController.text.trim().isEmpty
          ? null
          : _isActiveColumnController.text.trim(),
    );
  }

  Future<void> _fetchAndAutoMap() async {
    final tableName = _currentTableName;
    if (tableName.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testSuccess = false;
      _previewData = null;
    });

    try {
      final multiService = ref.read(multiSupabaseServiceProvider);
      final client = multiService.getClientForAccount(widget.company.accountId);

      if (client == null) {
        throw Exception('Supabase client not found for this account.');
      }

      final response = await client.from(tableName).select().limit(5);
      final data = response as List<dynamic>;

      if (mounted) {
        setState(() {
          _testSuccess = true;
          _previewData = data.cast<Map<String, dynamic>>();
        });

        if (data.isNotEmpty) {
          final keys = (data.first as Map<String, dynamic>).keys.toList();
          _autoMapColumns(keys);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully fetched data from $tableName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _testSuccess = false);
        
        String errorMsg = 'Could not fetch data: $e';
        if (e is PostgrestException) {
          if (e.code == 'PGRST205') {
            errorMsg = 'Table "$tableName" does not exist in this database.';
            if (e.hint != null && e.hint!.isNotEmpty) {
               // PostgREST often provides a helpful hint like "Perhaps you meant 'app_users'"
               errorMsg += ' ${e.hint}';
            }
          } else {
            errorMsg = e.message;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  void _autoMapColumns(List<String> keys) {
    String? idCol, nameCol, roleCol, phoneCol, emailCol, activeCol;

    for (final key in keys) {
      final lowerKey = key.toLowerCase();
      
      if (idCol == null && (lowerKey == 'id' || lowerKey.endsWith('_id'))) {
        idCol = key;
      }
      if (nameCol == null && (lowerKey.contains('name') || lowerKey == 'username')) {
        nameCol = key;
      }
      if (roleCol == null && (lowerKey.contains('role') || lowerKey.contains('type'))) {
        roleCol = key;
      }
      if (phoneCol == null && (lowerKey.contains('phone') || lowerKey.contains('mobile') || lowerKey.contains('contact'))) {
        phoneCol = key;
      }
      if (emailCol == null && lowerKey.contains('email')) {
        emailCol = key;
      }
      if (activeCol == null && (lowerKey.contains('active') || lowerKey.contains('status'))) {
        activeCol = key;
      }
    }

    setState(() {
      if (idCol != null) _idColumnController.text = idCol;
      if (nameCol != null) _nameColumnController.text = nameCol;
      if (roleCol != null) _roleColumnController.text = roleCol;
      if (phoneCol != null) _phoneColumnController.text = phoneCol;
      if (emailCol != null) _emailColumnController.text = emailCol;
      if (activeCol != null) _isActiveColumnController.text = activeCol;
    });
  }

  Future<void> _saveMapping() async {
    if (!_testSuccess || _idColumnController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final mappingService = ref.read(companyUserMappingServiceProvider);
      final mapping = _buildMapping();

      await mappingService.saveMapping(mapping, widget.company.name);

      if (mounted) {
        ref.invalidate(companyMappingProvider(widget.company));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mapping saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save mapping: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F0F) : Colors.grey.shade50;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? const Color(0xFF888888) : Colors.grey.shade600;
    final inputFillColor = isDark ? const Color(0xFF222222) : Colors.grey.shade100;

    final isTestEnabled = _currentTableName.isNotEmpty;

    InputDecoration buildInput(String label, {String? hint}) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subtitleColor, fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
        ),
      );
    }

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
              'Set Up Users View',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 20),
            ),
            Text(
              widget.company.name,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Table Selection
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '1. Select Users Table',
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedTableOption,
                    decoration: buildInput('Table Name'),
                    dropdownColor: cardColor,
                    style: TextStyle(color: textColor, fontSize: 13),
                    items: [
                      'users',
                      'app_users',
                      'salesmen',
                      'employees',
                      'profiles',
                      'staff',
                      'accounts',
                      'Custom...'
                    ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedTableOption = val!;
                        _testSuccess = false;
                        _previewData = null;
                      });
                    },
                  ),
                  if (_selectedTableOption == 'Custom...') ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _customTableNameController,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: buildInput('Custom Table Name', hint: 'Type exact table name'),
                      onChanged: (_) => setState(() {
                        _testSuccess = false;
                        _previewData = null;
                      }),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: isTestEnabled && !_isTesting ? _fetchAndAutoMap : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        disabledBackgroundColor: isDark ? const Color(0xFF333333) : Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isTesting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Fetch Data & Auto-Map',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Data Preview (only shown if test success)
            if (_testSuccess && _previewData != null)
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Data Preview',
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Showing up to 5 rows from $_currentTableName',
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    if (_previewData!.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Table is empty.',
                          style: TextStyle(color: subtitleColor),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else ...[
                      Builder(builder: (context) {
                        final ignoredKeys = ['id', 'created_at', 'updated_at', 'password', 'assigned_companies', 'token', 'access_token'];
                        final visibleKeys = _previewData!.first.keys
                            .where((k) => !ignoredKeys.contains(k.toLowerCase()))
                            .toList();

                        if (visibleKeys.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('No relevant columns to preview.', style: TextStyle(color: subtitleColor)),
                          );
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 40,
                            dataRowMinHeight: 40,
                            dataRowMaxHeight: 40,
                            columns: visibleKeys
                                .map((key) => DataColumn(
                                      label: Text(
                                        key,
                                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ))
                                .toList(),
                            rows: _previewData!
                                .map(
                                  (row) => DataRow(
                                    cells: visibleKeys.map((key) {
                                      return DataCell(
                                        Text(
                                          row[key]?.toString() ?? 'null',
                                          style: TextStyle(color: textColor, fontSize: 12),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                )
                                .toList(),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),

            if (_testSuccess) ...[
              const SizedBox(height: 16),
              // 3. Mapping Fields
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '2. Verify Column Mapping',
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'We have auto-filled these where possible. Edit them if needed. Leave blank if not tracked.',
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _idColumnController,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: buildInput('ID Column (Required)', hint: 'e.g. id'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _nameColumnController,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: buildInput('Name Column'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _roleColumnController,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: buildInput('Role Column'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _phoneColumnController,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: buildInput('Phone Column'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _emailColumnController,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: buildInput('Email Column'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _isActiveColumnController,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: buildInput('Active/Inactive Column'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: !_isSaving ? _saveMapping : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    disabledBackgroundColor: isDark ? const Color(0xFF333333) : Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Configuration',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
