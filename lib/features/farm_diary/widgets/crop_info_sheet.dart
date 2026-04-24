// lib/features/farm_diary/widgets/crop_info_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/app_themes.dart';
import '../services/crop_info_service.dart';

class CropInfoSheet extends StatefulWidget {
  final String cropName;
  final String plantType;

  const CropInfoSheet({
    super.key,
    required this.cropName,
    required this.plantType,
  });

  @override
  State<CropInfoSheet> createState() => _CropInfoSheetState();
}

class _CropInfoSheetState extends State<CropInfoSheet> {
  Map<String, dynamic>? _info;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInfo();
  }

  Future<void> _fetchInfo() async {
    final t = Provider.of<TranslationService>(context, listen: false);
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await CropInfoService.getCropInfo(
        widget.cropName, 
        widget.plantType,
        language: t.currentLanguage,
      );
      if (mounted) setState(() { _info = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high': return AppColors.error;
      case 'medium': return AppColors.warning;
      default: return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final t = Provider.of<TranslationService>(context);
    final isLive = _info?['source'] == 'live';

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: borderColor, borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.secondary.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cropName.isNotEmpty ? widget.cropName : widget.plantType,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      Text(
                        widget.plantType,
                        style: TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (!_isLoading && _info != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isLive ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (isLive ? AppColors.success : AppColors.warning).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        isLive ? Icons.cloud_done_rounded : Icons.offline_bolt_rounded,
                        size: 12,
                        color: isLive ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLive ? 'AI Live' : 'Offline',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: isLive ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ]),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          Divider(color: borderColor, height: 1),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? _buildLoading(textColor, captionColor)
                : _error != null
                    ? _buildError(textColor, captionColor, t)
                    : _buildContent(isDark, textColor, captionColor, borderColor, surfaceColor, t),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(Color textColor, Color captionColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48, height: 48,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
              strokeCap: StrokeCap.round,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Fetching crop intelligence...',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 6),
          Text(
            'Powered by Groq AI',
            style: TextStyle(fontSize: 12, color: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Color textColor, Color captionColor, TranslationService t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 32),
            ),
            const SizedBox(height: 14),
            Text('Could not load crop info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 6),
            Text('Check your internet connection\nor try again.', style: TextStyle(fontSize: 13, color: captionColor), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchInfo,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, Color textColor, Color captionColor, Color borderColor, Color surfaceColor, TranslationService t) {
    final info = _info!;
    final diseases = (info['commonDiseases'] as List<dynamic>? ?? []);
    final tips = (info['tips'] as List<dynamic>? ?? []);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // ── Description ──────────────────────────────────────────────────
        _sectionCard(
          isDark: isDark, borderColor: borderColor,
          color: AppColors.primary.withValues(alpha: 0.06),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionLabel(Icons.description_rounded, t.get('overview'), AppColors.primary, textColor),
            const SizedBox(height: 8),
            Text(info['description'] as String? ?? '—',
                style: TextStyle(fontSize: 13.5, color: textColor, height: 1.55)),
          ]),
        ),

        const SizedBox(height: 12),

        // ── Quick Stats ──────────────────────────────────────────────────
        Row(children: [
          Expanded(child: _quickStatCard(
            isDark: isDark, icon: Icons.wb_sunny_rounded, label: t.get('growing_season'),
            value: info['growingSeason'] as String? ?? '—',
            color: AppColors.warning, borderColor: borderColor,
          )),
          const SizedBox(width: 10),
          Expanded(child: _quickStatCard(
            isDark: isDark, icon: Icons.access_time_rounded, label: t.get('harvest_time'),
            value: info['harvestTime'] as String? ?? '—',
            color: AppColors.secondary, borderColor: borderColor,
          )),
        ]),

        const SizedBox(height: 10),

        Row(children: [
          Expanded(child: _quickStatCard(
            isDark: isDark, icon: Icons.water_drop_rounded, label: t.get('water_needs'),
            value: info['waterNeeds'] as String? ?? '—',
            color: const Color(0xFF3B82F6), borderColor: borderColor,
          )),
          const SizedBox(width: 10),
          Expanded(child: _quickStatCard(
            isDark: isDark, icon: Icons.landscape_rounded, label: t.get('soil_type'),
            value: info['soilType'] as String? ?? '—',
            color: const Color(0xFF8B5CF6), borderColor: borderColor,
          )),
        ]),

        const SizedBox(height: 10),

        _quickStatCard(
          isDark: isDark, icon: Icons.bar_chart_rounded, label: t.get('yield_per_acre'),
          value: info['yieldPerAcre'] as String? ?? '—',
          color: AppColors.success, borderColor: borderColor,
          fullWidth: true,
        ),

        const SizedBox(height: 16),

        // ── Common Diseases ──────────────────────────────────────────────
        if (diseases.isNotEmpty) ...[
          _sectionLabel(Icons.biotech_rounded, t.get('common_diseases'), AppColors.error, textColor),
          const SizedBox(height: 10),
          ...diseases.map((d) {
            final disease = d as Map<String, dynamic>;
            final severity = disease['severity'] as String? ?? 'low';
            final sevColor = _severityColor(severity);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sevColor.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: sevColor.withValues(alpha: 0.08),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                    ),
                    child: Row(children: [
                      Icon(Icons.coronavirus_rounded, size: 15, color: sevColor),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        disease['name'] as String? ?? '—',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textColor),
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: sevColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          severity.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: sevColor),
                        ),
                      ),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _diseaseRow(Icons.visibility_rounded, t.get('symptoms'), disease['symptoms'] as String? ?? '—', textColor, captionColor),
                      const SizedBox(height: 6),
                      _diseaseRow(Icons.healing_rounded, t.get('treatment'), disease['treatment'] as String? ?? '—', textColor, captionColor),
                    ]),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
        ],

        // ── Pest Management ───────────────────────────────────────────────
        if ((info['pestManagement'] as String? ?? '').isNotEmpty) ...[
          _sectionLabel(Icons.pest_control_rounded, t.get('pest_management_title'), AppColors.warning, textColor),
          const SizedBox(height: 8),
          _sectionCard(
            isDark: isDark, borderColor: borderColor,
            color: AppColors.warning.withValues(alpha: 0.06),
            child: Text(info['pestManagement'] as String,
                style: TextStyle(fontSize: 13.5, color: textColor, height: 1.55)),
          ),
          const SizedBox(height: 16),
        ],

        // ── Tips ─────────────────────────────────────────────────────────
        if (tips.isNotEmpty) ...[
          _sectionLabel(Icons.tips_and_updates_rounded, t.get('pro_farmer_tips'), AppColors.secondary, textColor),
          const SizedBox(height: 10),
          ...tips.asMap().entries.map((entry) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                child: Center(
                  child: Text('${entry.key + 1}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(entry.value as String,
                  style: TextStyle(fontSize: 13, color: textColor, height: 1.4))),
            ]),
          )),
        ],
      ],
    );
  }

  Widget _sectionCard({required bool isDark, required Color borderColor, required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  Widget _sectionLabel(IconData icon, String label, Color color, Color textColor) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 15, color: color),
      ),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
    ]);
  }

  Widget _quickStatCard({
    required bool isDark, required IconData icon, required String label,
    required String value, required Color color, required Color borderColor,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(
            fontSize: fullWidth ? 13 : 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            height: 1.3,
          )),
        ])),
      ]),
    );
  }

  Widget _diseaseRow(IconData icon, String label, String value, Color textColor, Color captionColor) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 13, color: captionColor),
      const SizedBox(width: 6),
      Text('$label: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: captionColor)),
      Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: textColor, height: 1.4))),
    ]);
  }
}