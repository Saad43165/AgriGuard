import 'package:agriguard_fyp/core/widgets/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/translation_service.dart';
import '../../../advance_search_screen/service/advanced_search_service.dart';
import '../../../advance_search_screen/service/groq_service.dart';
import '../../../advance_search_screen/service/plant_id_api_service.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  bool _isTesting = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _runTests() async {
    if (_isTesting) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _isTesting = true;
      _result = null;
      _error = null;
    });

    try {
      final service = AdvancedSearchService();
      final r = await service.testAllApis();
      if (!mounted) return;
      setState(() => _result = r);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);

    final groq = GroqService();
    final plantId = PlantIdService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle(title: 'API Setup'),
          const SizedBox(height: 10),


          _StatusTile(
            title: 'Groq API key',
            subtitle: 'Used for agronomy advice text',
            isOk: groq.hasApiKey(),
          ),
          _StatusTile(
            title: 'Plant.id key',
            subtitle: 'Fallback cloud vision (credits required)',
            isOk: plantId.hasApiKey(),
          ),

          const SizedBox(height: 16),
          const _SectionTitle(title: 'Connectivity test'),
          const SizedBox(height: 10),

          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isTesting ? null : _runTests,
              icon: _isTesting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(_isTesting ? t.get('analyzing') : 'Run API tests'),
            ),
          ),

          const SizedBox(height: 12),

          if (_error != null)
            _InfoBox(
              color: theme.colorScheme.errorContainer,
              textColor: theme.colorScheme.onErrorContainer,
              icon: Icons.error_outline_rounded,
              title: 'Test failed',
              body: _error!,
            ),

          if (_result != null)
            _InfoBox(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              textColor: theme.colorScheme.onSurface,
              icon: Icons.verified_rounded,
              title: 'Results',
              body: _prettyResult(_result!),
            ),
        ],
      ),
    );
  }

  String _prettyResult(Map<String, dynamic> r) {
    final plantHealth = r['plantHealth'] as Map<String, dynamic>?;
    final groq = r['groq'] as Map<String, dynamic>?;
    final plant = r['plantId'] as Map<String, dynamic>?;

    String ok(bool v) => v ? '✅' : '❌';

    final plantHealthOk = plantHealth?['available'] == true;
    final groqOk = groq?['available'] == true;
    final plantOk = plant?['available'] == true;

    return [
      'PlantHealth: ${ok(plantHealthOk)}',
      'Groq: ${ok(groqOk)}',
      'Plant.id: ${ok(plantOk)}',
      '',
      'PlantHealth status: ${plantHealth?['status'] ?? 'N/A'}',
      'Groq status: ${groq?['status'] ?? 'N/A'}',
      'Plant.id status: ${plant?['status'] ?? 'N/A'}',
      '',
      'Message: ${r['message'] ?? 'N/A'}',
      'Timestamp: ${r['timestamp'] ?? 'N/A'}',
    ].join('\n');
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isOk;

  const _StatusTile({
    required this.title,
    required this.subtitle,
    required this.isOk,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: (isOk ? AppColors.emerald : AppColors.error)
                  .withValues(alpha: 0.12),
            ),
            child: Icon(
              isOk ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isOk ? AppColors.emerald : AppColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isOk ? 'Ready' : 'Missing',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: isOk ? AppColors.emerald : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final Color color;
  final Color textColor;
  final IconData icon;
  final String title;
  final String body;

  const _InfoBox({
    required this.color,
    required this.textColor,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  body,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.90),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}