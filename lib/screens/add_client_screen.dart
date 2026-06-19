import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase/supabase.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/companies_provider.dart';
import '../models/tally_company.dart';

class AddClientScreen extends ConsumerStatefulWidget {
  const AddClientScreen({super.key});

  @override
  ConsumerState<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends ConsumerState<AddClientScreen> {
  final _urlController = TextEditingController();
  final _labelController = TextEditingController();
  final _anonKeyController = TextEditingController();

  bool _isFetching = false;
  bool _isSaving = false;
  bool _obscureKey = true;

  List<TallyCompany>? _previewCompanies;

  Future<void> _fetchPreview() async {
    final url = _urlController.text.trim();
    final anonKey = _anonKeyController.text.trim();

    if (url.isEmpty || anonKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter URL and Anon Key first')),
      );
      return;
    }

    setState(() {
      _isFetching = true;
      _previewCompanies = null;
    });

    try {
      final tempClient = SupabaseClient(
        url,
        anonKey,
        authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
      );

      final response = await tempClient
          .from('tally_companies')
          .select('id, company_name, is_active, created_at')
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      final companies = data
          .map((row) => TallyCompany.fromJson(row as Map<String, dynamic>, 'preview'))
          .toList();

      if (mounted) {
        setState(() {
          _previewCompanies = companies;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _saveClient() async {
    final url = _urlController.text.trim();
    final anonKey = _anonKeyController.text.trim();
    final label = _labelController.text.trim();

    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account Label is required before saving')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final service = ref.read(superAdminServiceProvider);
      
      final response = await service.client.from('client_accounts').insert({
        'supabase_url': url,
        'anon_key': anonKey,
        'label': label,
        'is_active': true,
      }).select('id').single();
      
      final newAccountId = response['id'] as String;

      if (_previewCompanies != null && _previewCompanies!.isNotEmpty) {
        await service.addCachedCompanies(newAccountId, _previewCompanies!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client added successfully!')),
        );
        ref.invalidate(clientAccountsProvider);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save client: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _labelController.dispose();
    _anonKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy');

    final bgColor = isDark ? const Color(0xFF0F0F0F) : Colors.grey.shade50;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? const Color(0xFF888888) : Colors.grey.shade600;
    final inputFillColor = isDark ? const Color(0xFF222222) : Colors.grey.shade100;

    InputDecoration buildInput(String label, {Widget? suffix, String? hint}) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subtitleColor, fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: inputFillColor,
        suffixIcon: suffix,
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
              'Add Client Account',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 20),
            ),
            const Text(
              'Connect a new Supabase project',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step 1 Card
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
                boxShadow: isDark ? null : [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1)),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Connect to Database',
                        style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _urlController,
                    style: TextStyle(color: textColor, fontSize: 13),
                    decoration: buildInput('Supabase Project URL', hint: 'https://xxxx.supabase.co'),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _anonKeyController,
                    style: TextStyle(color: textColor, fontSize: 13),
                    obscureText: _obscureKey,
                    decoration: buildInput(
                      'Supabase Anon Key',
                      suffix: IconButton(
                        icon: Icon(
                          _obscureKey ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureKey = !_obscureKey),
                      ),
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 46,
                    child: _isFetching
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                              strokeWidth: 2.5,
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _fetchPreview,
                            icon: const Icon(Icons.cloud_sync, size: 18, color: Colors.white),
                            label: const Text(
                              'Verify & Fetch Companies',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // Step 2 — shown after fetch
            if (_previewCompanies != null) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  boxShadow: isDark ? null : [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1)),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Center(
                            child: Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Companies Found',
                          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF052E16) : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xFF14532D) : const Color(0xFFBBF7D0)),
                          ),
                          child: Text(
                            '${_previewCompanies!.length}',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_previewCompanies!.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No companies found in this database.',
                          style: TextStyle(color: subtitleColor, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _previewCompanies!.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                            itemBuilder: (context, index) {
                              final company = _previewCompanies![index];
                              return Container(
                                color: index % 2 == 0
                                    ? (isDark ? const Color(0xFF161616) : Colors.white)
                                    : (isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            company.name,
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            dateFormat.format(company.createdAt),
                                            style: TextStyle(color: subtitleColor, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: company.isActive
                                            ? (isDark ? const Color(0xFF052E16) : const Color(0xFFF0FDF4))
                                            : (isDark ? const Color(0xFF2D0707) : const Color(0xFFFEF2F2)),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: company.isActive
                                              ? (isDark ? const Color(0xFF14532D) : const Color(0xFFBBF7D0))
                                              : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA)),
                                        ),
                                      ),
                                      child: Text(
                                        company.isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          color: company.isActive
                                              ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                                              : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
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
                ),
              ),

              const SizedBox(height: 16),

              // Step 2.5 — Account Label
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  boxShadow: isDark ? null : [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1)),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Center(
                            child: Text('3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Name This Account',
                          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Give this client account a label so you can identify it on the dashboard.',
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _labelController,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: buildInput('Account Label', hint: 'e.g. Al Zahra, Gulf Group'),
                      maxLength: 50,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Step 3 — Save
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  boxShadow: isDark ? null : [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1)),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Center(
                            child: Text('4', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Save Account',
                          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 46,
                      child: _isSaving
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                                strokeWidth: 2.5,
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: _saveClient,
                              icon: const Icon(Icons.save_alt, size: 18, color: Colors.white),
                              label: const Text(
                                'Save Client Account',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                    ),
                  ],
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
