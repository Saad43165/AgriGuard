import 'package:agriguard_fyp/core/services/api_gateway.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:agriguard_fyp/core/services/translation_service.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';
import '../disease_data.dart';

class DiseaseDetailSheet extends StatefulWidget {
  final DiseaseEntry entry;
  final bool isDark;
  final TranslationService t;
  const DiseaseDetailSheet({super.key, required this.entry, required this.isDark, required this.t});
  @override
  State<DiseaseDetailSheet> createState() => _DiseaseDetailSheetState();
}

class _DiseaseDetailSheetState extends State<DiseaseDetailSheet> {
  bool _loadingLive = false;
  String? _liveInfo;
  bool _liveLoaded = false;

  static String _translateSeverityBadge(String s, TranslationService t) {
    if (!t.isUrdu) return s;
    switch (s.toLowerCase()) {
      case 'high': return 'زیادہ';
      case 'medium': return 'درمیانہ';
      case 'low': return 'کم';
      case 'critical': return 'انتہائی';
      case 'fast': return 'تیز';
      case 'moderate': return 'درمیانہ';
      case 'slow': return 'سست';
      case 'none': return 'کوئی نہیں';
      default: return s;
    }
  }

  Future<void> _fetchLiveInfo() async {
    if (_liveLoaded || _loadingLive) return;
    setState(() => _loadingLive = true);
    try {
      if (!ApiGateway.groqAvailable) { setState(() { _loadingLive = false; _liveLoaded = true; }); return; }
      final isUrdu = widget.t.isUrdu;
      final langPrompt = isUrdu ? " Respond entirely in Urdu (اردو)." : "";
      final prompt =
          'In 2-3 sentences, describe ${widget.entry.condition} on ${widget.entry.plant}: main cause, key symptom, best treatment. Be concise.$langPrompt';
      final resp = await http.post(
        Uri.parse(ApiGateway.groqUrl),
        headers: {'Authorization': await ApiGateway.groqAuth(), 'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [{'role': 'user', 'content': prompt}],
          'max_tokens': 250,
        }),
      ).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        _liveInfo = data['choices'][0]['message']['content']?.toString().trim();
      }
    } catch (_) {}
    if (mounted) setState(() { _loadingLive = false; _liveLoaded = true; });
  }

  @override
  void initState() { super.initState(); _fetchLiveInfo(); }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final isDark = widget.isDark;
    final t = widget.t;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return DraggableScrollableSheet(
      initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 10), width: 36, height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2))),

          Expanded(child: SingleChildScrollView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: e.isHealthy
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: e.isHealthy
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.error.withValues(alpha: 0.2))),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: e.networkImage != null
                      ? CachedNetworkImage(
                          imageUrl: e.networkImage!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(e.imageAsset, fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    Icon(Icons.eco_rounded, color: AppColors.primary, size: 28))),
                          errorWidget: (_, __, ___) => Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(e.imageAsset, fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    Icon(Icons.eco_rounded, color: AppColors.primary, size: 28))),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(e.imageAsset, fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  Icon(Icons.eco_rounded, color: AppColors.primary, size: 28))))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text(t.translatePlant(e.plant).toUpperCase(), style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w800,
                      color: AppColors.primary, letterSpacing: 1))),
                  const SizedBox(height: 5),
                  Text(t.translateDisease(e.condition), style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800,
                    color: textColor, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, children: [
                    _Badge(
                      label: e.isHealthy
                          ? (t.get('ui_healthy'))
                          : _translateSeverityBadge(e.severity, t),
                      color: e.isHealthy ? AppColors.primary : AppColors.error),
                    if (!e.isHealthy)
                      _Badge(
                        label: '${_translateSeverityBadge(e.spreadRate, t)} ${t.get('ui_spread')}',
                        color: AppColors.warning),
                  ]),
                ])),
              ]),

              const SizedBox(height: 16),

              if (_loadingLive)
                _AiCard(child: Row(children: [
                  const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                  const SizedBox(width: 10),
                  Text(t.get('ui_getting_ai_insights'),
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkCaption : AppColors.lightCaption)),
                ]))
              else if (_liveInfo != null)
                _AiCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(t.get('ui_live_ai_insight'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 6),
                  Text(_liveInfo!, style: TextStyle(fontSize: 12, color: subtext, height: 1.5)),
                ])),

              if (_loadingLive || _liveInfo != null) const SizedBox(height: 14),

              _Section(icon: Icons.info_outline_rounded,
                title: t.get('ui_about'),
                content: t.isUrdu ? e.descriptionUr : e.description, isDark: isDark),
              const SizedBox(height: 12),

              if (!e.isHealthy) ...[
                _Section(icon: Icons.warning_amber_rounded,
                  title: t.get('ui_symptoms'),
                  content: t.isUrdu ? e.symptomsUr : e.symptoms, isDark: isDark),
                const SizedBox(height: 12),
              ],

              _Section(icon: Icons.biotech_rounded,
                title: t.get('ui_causes'),
                content: e.causes, isDark: isDark),
              const SizedBox(height: 12),

              _Section(icon: Icons.healing_rounded,
                title: t.get('ui_treatment'),
                content: t.isUrdu ? e.treatmentUr : e.treatment, isDark: isDark),
              const SizedBox(height: 12),

              _Section(icon: Icons.shield_outlined,
                title: t.get('ui_prevention'),
                content: t.isUrdu ? e.preventionUr : e.prevention, isDark: isDark),
              const SizedBox(height: 12),

              _Section(icon: Icons.cloud_outlined,
                title: t.get('ui_weather_conditions'),
                content: e.weatherConditions, isDark: isDark),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/capture');
                  },
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: Text(t.get('ui_scan_a_plant')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                )),
            ]),
          )),
        ]),
      ),
    );
  }
}

class _AiCard extends StatelessWidget {
  final Widget child;
  const _AiCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15))),
    child: child);
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(
      fontSize: 10, fontWeight: FontWeight.w700, color: color)));
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title, content;
  final bool isDark;
  const _Section({required this.icon, required this.title, required this.content, required this.isDark});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Icon(icon, color: AppColors.primary, size: 15),
      const SizedBox(width: 6),
      Text(title, style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
    ]),
    const SizedBox(height: 6),
    Text(content, style: TextStyle(
      fontSize: 13,
      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
      height: 1.5)),
  ]);
}
