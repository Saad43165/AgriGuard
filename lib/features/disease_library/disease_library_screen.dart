import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/services/translation_service.dart';
import '../../core/widgets/app_themes.dart';
import 'disease_data.dart';

class DiseaseLibraryScreen extends StatefulWidget {
  const DiseaseLibraryScreen({super.key});
  @override
  State<DiseaseLibraryScreen> createState() => _DiseaseLibraryScreenState();
}

class _DiseaseLibraryScreenState extends State<DiseaseLibraryScreen> {
  String _filter = 'all';
  String _search = '';
  String? _selectedPlant;
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();

  List<DiseaseEntry> get _filtered {
    var list = DiseaseLibrary.all;
    if (_selectedPlant != null) list = list.where((e) => e.plant == _selectedPlant).toList();
    if (_filter == 'healthy') list = list.where((e) => e.isHealthy).toList();
    if (_filter == 'diseased') list = list.where((e) => !e.isHealthy).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((e) =>
        e.plant.toLowerCase().contains(q) ||
        e.condition.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  List<String> get _plants =>
      DiseaseLibrary.all.map((e) => e.plant).toSet().toList()..sort();

  // Translate plant name for display
  String _translatePlant(String plant, TranslationService t) =>
      t.translatePlant(plant);

  // Translate severity for display
  String _translateSeverity(String severity, TranslationService t) {
    if (!t.isUrdu) return severity;
    switch (severity.toLowerCase()) {
      case 'high': return 'زیادہ';
      case 'medium': return 'درمیانہ';
      case 'low': return 'کم';
      case 'critical': return 'انتہائی';
      case 'fast': return 'تیز';
      case 'moderate': return 'درمیانہ';
      case 'slow': return 'سست';
      case 'none': return 'کوئی نہیں';
      default: return severity;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E);
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: cardBg, shape: BoxShape.circle,
                      border: Border.all(color: borderColor)),
                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: textColor)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(
                  t.isUrdu ? 'بیماری لائبریری' : 'Disease Library',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: textColor, letterSpacing: -0.3))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text('${_filtered.length}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.primary))),
              ]),
            ),

            // Search bar — uses Material widget directly to avoid theme conflicts
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Material(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor)),
                  child: Row(children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search_rounded, size: 18, color: captionColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: EditableText(
                        controller: _searchCtrl,
                        focusNode: _focusNode,
                        onChanged: (v) => setState(() => _search = v),
                        style: TextStyle(fontSize: 14, color: textColor),
                        cursorColor: AppColors.primary,
                        backgroundCursorColor: Colors.transparent,
                        selectionColor: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    if (_search.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          t.isUrdu ? 'تلاش کریں...' : 'Search...',
                          style: TextStyle(fontSize: 13, color: captionColor),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                          _focusNode.unfocus();
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(Icons.close_rounded, size: 16, color: captionColor))),
                  ]),
                ),
              ),
            ),

            // Filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 0, 0),
              child: SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 16),
                  children: [
                    _Chip(label: t.isUrdu ? 'سب' : 'All', selected: _filter == 'all',
                        isDark: isDark, onTap: () => setState(() { _filter = 'all'; _selectedPlant = null; })),
                    const SizedBox(width: 8),
                    _Chip(label: t.isUrdu ? 'صحت مند' : 'Healthy', selected: _filter == 'healthy',
                        isDark: isDark, onTap: () => setState(() { _filter = 'healthy'; _selectedPlant = null; })),
                    const SizedBox(width: 8),
                    _Chip(label: t.isUrdu ? 'بیمار' : 'Diseased', selected: _filter == 'diseased',
                        isDark: isDark, onTap: () => setState(() { _filter = 'diseased'; _selectedPlant = null; })),
                    const SizedBox(width: 8),
                    ..._plants.map((p) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _Chip(
                        label: _translatePlant(p, t),
                        selected: _selectedPlant == p,
                        isDark: isDark,
                        onTap: () => setState(() {
                          _selectedPlant = _selectedPlant == p ? null : p;
                          _filter = 'all';
                        }),
                      ),
                    )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Grid
            Expanded(
              child: _filtered.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.search_off_rounded, size: 48, color: captionColor),
                    const SizedBox(height: 12),
                    Text(t.isUrdu ? 'کوئی نتیجہ نہیں' : 'No results found',
                      style: TextStyle(fontSize: 16, color: captionColor)),
                  ]))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) => _DiseaseCard(
                      entry: _filtered[i],
                      isDark: isDark,
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _showDetail(ctx, _filtered[i], t, isDark);
                      }),
                  ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, DiseaseEntry entry, TranslationService t, bool isDark) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DiseaseDetailSheet(entry: entry, isDark: isDark, t: t),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final bool selected, isDark;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder))),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext))),
      ),
    );
  }
}

// ── Disease card ──────────────────────────────────────────────────────────────
class _DiseaseCard extends StatelessWidget {
  final DiseaseEntry entry;
  final bool isDark;
  final VoidCallback onTap;
  const _DiseaseCard({required this.entry, required this.isDark, required this.onTap});

  Color get _severityColor {
    switch (entry.severity) {
      case 'Critical': return const Color(0xFF9B1C1C);
      case 'High': return AppColors.error;
      case 'Medium': return AppColors.warning;
      case 'Low': return AppColors.secondary;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E);
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final t = Provider.of<TranslationService>(context, listen: false);
    final displayPlant = t.translatePlant(entry.plant);
    final displayCondition = entry.isHealthy
        ? (t.isUrdu ? 'صحت مند' : entry.condition)
        : t.translateDisease(entry.condition);
    final displaySeverity = entry.isHealthy
        ? (t.isUrdu ? 'صحت مند' : '✓')
        : _translateSeverityStatic(entry.severity, t);
    final displaySpread = _translateSeverityStatic(entry.spreadRate, t);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image area
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Container(
              height: 100, width: double.infinity,
              color: entry.isHealthy
                  ? AppColors.primary.withValues(alpha: 0.07)
                  : _severityColor.withValues(alpha: 0.07),
              child: Stack(fit: StackFit.expand, children: [
                if (entry.networkImage != null)
                  CachedNetworkImage(
                    imageUrl: entry.networkImage!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Padding(
                      padding: const EdgeInsets.all(14),
                      child: Image.asset(entry.imageAsset, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(Icons.eco_rounded,
                              size: 44, color: entry.isHealthy ? AppColors.primary : _severityColor))),
                    errorWidget: (_, __, ___) => Padding(
                      padding: const EdgeInsets.all(14),
                      child: Image.asset(entry.imageAsset, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(Icons.eco_rounded,
                              size: 44, color: entry.isHealthy ? AppColors.primary : _severityColor))),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Image.asset(entry.imageAsset, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(Icons.eco_rounded,
                            size: 44, color: entry.isHealthy ? AppColors.primary : _severityColor))),
                Positioned(
                  top: 7, right: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: entry.isHealthy ? AppColors.primary : _severityColor,
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      entry.isHealthy ? '✓' : displaySeverity,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)))),
              ]),
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(displayPlant,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  const SizedBox(height: 2),
                  Text(displayCondition,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                ]),
                Row(children: [
                  Icon(Icons.speed_rounded, size: 10, color: captionColor),
                  const SizedBox(width: 3),
                  Text(displaySpread,
                    style: TextStyle(fontSize: 10, color: captionColor)),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  static String _translateSeverityStatic(String s, TranslationService t) {
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
}

// ── Detail sheet ──────────────────────────────────────────────────────────────
class _DiseaseDetailSheet extends StatefulWidget {
  final DiseaseEntry entry;
  final bool isDark;
  final TranslationService t;
  const _DiseaseDetailSheet({required this.entry, required this.isDark, required this.t});
  @override
  State<_DiseaseDetailSheet> createState() => _DiseaseDetailSheetState();
}

class _DiseaseDetailSheetState extends State<_DiseaseDetailSheet> {
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
      final apiKey = dotenv.env['GROQ_API_KEY']?.trim() ?? '';
      if (apiKey.isEmpty) { setState(() { _loadingLive = false; _liveLoaded = true; }); return; }
      final prompt =
          'In 2-3 sentences, describe ${widget.entry.condition} on ${widget.entry.plant}: main cause, key symptom, best treatment. Be concise.';
      final resp = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [{'role': 'user', 'content': prompt}],
          'max_tokens': 120,
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
    final textColor = isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E);
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final subtext = isDark ? AppColors.darkSubtext : const Color(0xFF4A5568);

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
              // Header row
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
                    child: Text(e.plant.toUpperCase(), style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w800,
                      color: AppColors.primary, letterSpacing: 1))),
                  const SizedBox(height: 5),
                  Text(e.condition, style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800,
                    color: textColor, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, children: [
                    _Badge(
                      label: e.isHealthy
                          ? (t.isUrdu ? 'صحت مند' : 'Healthy')
                          : _translateSeverityBadge(e.severity, t),
                      color: e.isHealthy ? AppColors.primary : AppColors.error),
                    if (!e.isHealthy)
                      _Badge(
                        label: '${_translateSeverityBadge(e.spreadRate, t)} ${t.isUrdu ? 'پھیلاؤ' : 'spread'}',
                        color: AppColors.warning),
                  ]),
                ])),
              ]),

              const SizedBox(height: 16),

              // Live AI
              if (_loadingLive)
                _AiCard(child: Row(children: [
                  const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                  const SizedBox(width: 10),
                  Text(t.isUrdu ? 'AI بصیرت حاصل ہو رہی ہے...' : 'Getting AI insights...',
                      style: TextStyle(fontSize: 12, color: captionColor)),
                ]))
              else if (_liveInfo != null)
                _AiCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(t.isUrdu ? 'AI بصیرت' : 'Live AI Insight',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 6),
                  Text(_liveInfo!, style: TextStyle(fontSize: 12, color: subtext, height: 1.5)),
                ])),

              if (_loadingLive || _liveInfo != null) const SizedBox(height: 14),

              _Section(icon: Icons.info_outline_rounded,
                title: t.isUrdu ? 'تفصیل' : 'About',
                content: t.isUrdu ? e.descriptionUr : e.description, isDark: isDark),
              const SizedBox(height: 12),

              if (!e.isHealthy) ...[
                _Section(icon: Icons.warning_amber_rounded,
                  title: t.isUrdu ? 'علامات' : 'Symptoms',
                  content: t.isUrdu ? e.symptomsUr : e.symptoms, isDark: isDark),
                const SizedBox(height: 12),
              ],

              _Section(icon: Icons.biotech_rounded,
                title: t.isUrdu ? 'وجوہات' : 'Causes',
                content: e.causes, isDark: isDark),
              const SizedBox(height: 12),

              _Section(icon: Icons.healing_rounded,
                title: t.isUrdu ? 'علاج' : 'Treatment',
                content: t.isUrdu ? e.treatmentUr : e.treatment, isDark: isDark),
              const SizedBox(height: 12),

              _Section(icon: Icons.shield_outlined,
                title: t.isUrdu ? 'بچاؤ' : 'Prevention',
                content: t.isUrdu ? e.preventionUr : e.prevention, isDark: isDark),
              const SizedBox(height: 12),

              _Section(icon: Icons.cloud_outlined,
                title: t.isUrdu ? 'موسمی حالات' : 'Weather Conditions',
                content: e.weatherConditions, isDark: isDark),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(ctx, '/capture');
                  },
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: Text(t.isUrdu ? 'اسکین کریں' : 'Scan a Plant'),
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
      color: isDark ? AppColors.darkSubtext : const Color(0xFF4A5568),
      height: 1.5)),
  ]);
}
