import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../core/widgets/app_themes.dart';

class BugReportScreen extends StatefulWidget {
  const BugReportScreen({super.key});
  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _stepsCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String _selectedCategory = 'Scan / Detection';
  String _selectedSeverity = 'Medium';
  bool _isSubmitting = false;
  bool _submitted = false;

  final List<String> _categories = [
    'Scan / Detection',
    'App Crash',
    'UI / Display Issue',
    'Login / Account',
    'History / Data',
    'Weather Feature',
    'Performance',
    'Other',
  ];

  final List<Map<String, dynamic>> _severities = [
    {'label': 'Low', 'color': AppColors.info, 'icon': Icons.info_outline_rounded},
    {'label': 'Medium', 'color': AppColors.warning, 'icon': Icons.warning_amber_rounded},
    {'label': 'High', 'color': AppColors.error, 'icon': Icons.error_outline_rounded},
    {'label': 'Critical', 'color': const Color(0xFFDC2626), 'icon': Icons.dangerous_rounded},
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill email if logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) _emailCtrl.text = user!.email!;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _stepsCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  static const String _formspreeUrl = 'https://formspree.io/f/mdayokly';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final response = await http.post(
        Uri.parse(_formspreeUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'subject': '[AgriGuard Bug] ${_titleCtrl.text.trim()}',
          'title': _titleCtrl.text.trim(),
          'category': _selectedCategory,
          'severity': _selectedSeverity,
          'description': _descCtrl.text.trim(),
          'steps_to_reproduce': _stepsCtrl.text.trim(),
          'email': _emailCtrl.text.trim().isNotEmpty
              ? _emailCtrl.text.trim()
              : (user?.email ?? 'anonymous'),
          'user_id': user?.uid ?? 'anonymous',
          'platform': 'AgriGuard Mobile',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() { _isSubmitting = false; _submitted = true; });
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to submit. Please check your connection and try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F7FF);
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final textSub = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Report a Bug',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
      ),
      body: _submitted ? _buildSuccessState(isDark, textPrimary, textSub) : _buildForm(isDark, surfaceColor, borderColor, textPrimary, textSub),
    );
  }

  Widget _buildSuccessState(bool isDark, Color textPrimary, Color textSub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 24),
            Text('Report Submitted!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textPrimary)),
            const SizedBox(height: 12),
            Text(
              'Thank you for helping us improve AgriGuard. We\'ll review your report and work on a fix.',
              style: TextStyle(fontSize: 14, color: textSub, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Back to Help', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool isDark, Color surfaceColor, Color borderColor, Color textPrimary, Color textSub) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bug_report_rounded, color: AppColors.error, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Found a bug?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),
                        const SizedBox(height: 2),
                        Text('Help us fix it by providing details below.', style: TextStyle(fontSize: 12, color: textSub)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _SectionLabel(label: 'Bug Title *', isDark: isDark),
            const SizedBox(height: 8),
            _FormField(
              controller: _titleCtrl,
              hint: 'e.g. App crashes when scanning in low light',
              isDark: isDark,
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),

            _SectionLabel(label: 'Category', isDark: isDark),
            const SizedBox(height: 8),
            _CategoryPicker(
              categories: _categories,
              selected: _selectedCategory,
              isDark: isDark,
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 16),

            _SectionLabel(label: 'Severity', isDark: isDark),
            const SizedBox(height: 8),
            _SeverityPicker(
              severities: _severities,
              selected: _selectedSeverity,
              isDark: isDark,
              onChanged: (v) => setState(() => _selectedSeverity = v),
            ),
            const SizedBox(height: 16),

            _SectionLabel(label: 'Description *', isDark: isDark),
            const SizedBox(height: 8),
            _FormField(
              controller: _descCtrl,
              hint: 'Describe what happened and what you expected to happen...',
              isDark: isDark,
              maxLines: 4,
              validator: (v) => v == null || v.trim().length < 10 ? 'Please provide more detail (min 10 chars)' : null,
            ),
            const SizedBox(height: 16),

            _SectionLabel(label: 'Steps to Reproduce', isDark: isDark),
            const SizedBox(height: 8),
            _FormField(
              controller: _stepsCtrl,
              hint: '1. Open the app\n2. Tap Scan\n3. ...',
              isDark: isDark,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            _SectionLabel(label: 'Your Email (optional)', isDark: isDark),
            const SizedBox(height: 8),
            _FormField(
              controller: _emailCtrl,
              hint: 'your@email.com',
              isDark: isDark,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Submit Bug Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});
  @override
  Widget build(BuildContext context) => Text(label,
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext));
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({required this.controller, required this.hint, required this.isDark,
    this.maxLines = 1, this.keyboardType, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? AppColors.darkCaption : AppColors.lightCaption, fontSize: 13),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final bool isDark;
  final void Function(String) onChanged;
  const _CategoryPicker({required this.categories, required this.selected, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: categories.map((c) {
        final isSelected = c == selected;
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onChanged(c); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCard : AppColors.lightCard),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: isSelected ? 0 : 1,
              ),
            ),
            child: Text(c, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            )),
          ),
        );
      }).toList(),
    );
  }
}

class _SeverityPicker extends StatelessWidget {
  final List<Map<String, dynamic>> severities;
  final String selected;
  final bool isDark;
  final void Function(String) onChanged;
  const _SeverityPicker({required this.severities, required this.selected, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: severities.map((s) {
        final isSelected = s['label'] == selected;
        final color = s['color'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onChanged(s['label']); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: s == severities.last ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.15) : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isSelected ? 2 : 1),
              ),
              child: Column(
                children: [
                  Icon(s['icon'] as IconData, color: isSelected ? color : (isDark ? AppColors.darkCaption : AppColors.lightCaption), size: 18),
                  const SizedBox(height: 4),
                  Text(s['label'], style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: isSelected ? color : (isDark ? AppColors.darkCaption : AppColors.lightCaption),
                  )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
