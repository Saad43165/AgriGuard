import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_fyp/core/services/translation_service.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';
import 'disease_data.dart';
import 'widgets/disease_library_widgets.dart';
import 'widgets/disease_detail_sheet.dart';

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
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
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
                  t.get('ui_disease_library'),
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
                        padding: const EdgeInsetsDirectional.only(end: 12),
                        child: Text(
                          t.get('ui_search'),
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
                          padding: const EdgeInsetsDirectional.only(end: 12),
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
                  padding: const EdgeInsetsDirectional.only(end: 16),
                  children: [
                    DiseaseChip(label: t.get('ui_all'), selected: _filter == 'all',
                        isDark: isDark, onTap: () => setState(() { _filter = 'all'; _selectedPlant = null; })),
                    const SizedBox(width: 8),
                    DiseaseChip(label: t.get('ui_healthy'), selected: _filter == 'healthy',
                        isDark: isDark, onTap: () => setState(() { _filter = 'healthy'; _selectedPlant = null; })),
                    const SizedBox(width: 8),
                    DiseaseChip(label: t.get('ui_diseased'), selected: _filter == 'diseased',
                        isDark: isDark, onTap: () => setState(() { _filter = 'diseased'; _selectedPlant = null; })),
                    const SizedBox(width: 8),
                    ..._plants.map((p) => Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: DiseaseChip(
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
                    Text(t.get('ui_no_results_found'),
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
                    itemBuilder: (ctx, i) => DiseaseCard(
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
      builder: (_) => DiseaseDetailSheet(entry: entry, isDark: isDark, t: t),
    );
  }
}


