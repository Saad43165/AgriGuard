// lib/features/farm_diary/widgets/crop_detail_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/app_themes.dart';
import '../../home/screens/species/plant_species.dart';
import 'crop_info_sheet.dart';

class CropDetailSheet extends StatefulWidget {
  final Map<String, dynamic> crop;
  final VoidCallback onDelete;
  final void Function(String status) onUpdateHealth;
  const CropDetailSheet({
    super.key,
    required this.crop,
    required this.onDelete,
    required this.onUpdateHealth,
  });
  @override
  State<CropDetailSheet> createState() => _CropDetailSheetState();
}

class _CropDetailSheetState extends State<CropDetailSheet>
    with TickerProviderStateMixin {
  late String _healthStatus;
  late AnimationController _slideCtrl;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _healthStatus = widget.crop['healthStatus'] as String? ?? 'healthy';
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim =
        CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  Color _plantColor(String? plantType) {
    if (plantType == null) return AppColors.primary;
    final species = AppSpecies.allSpecies.firstWhere(
          (s) => s.nameEn.toLowerCase() == plantType.toLowerCase(),
      orElse: () => AppSpecies.allSpecies.first,
    );
    return species.color;
  }

  String _plantEmoji(String? plantType) {
    const emojis = {
      'apple': '🍎', 'apricot': '🍑', 'bean': '🫘', 'cherry': '🍒',
      'corn': '🌽', 'fig': '🍈', 'grape': '🍇', 'loquat': '🍊',
      'peach': '🍑', 'pear': '🍐', 'persimmon': '🍅', 'potato': '🥔',
      'strawberry': '🍓', 'tomato': '🍅', 'walnut': '🌰',
      'wheat': '🌾', 'rice': '🍚', 'cotton': '🌿', 'sugarcane': '🎋',
      'onion': '🧅', 'garlic': '🧄', 'chili': '🌶️', 'mango': '🥭',
      'banana': '🍌', 'citrus': '🍊',
    };
    return emojis[plantType?.toLowerCase() ?? ''] ?? '🌱';
  }

  bool get _isCustomSpecies =>
      widget.crop['isCustomSpecies'] as bool? ?? false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);

    // Color palette
    final sheetBg =
    isDark ? const Color(0xFF0F1923) : const Color(0xFFFAFBFC);
    final cardBg = isDark ? const Color(0xFF1A2535) : Colors.white;
    final textColor =
    isDark ? AppColors.slate100 : const Color(0xFF0F172A);
    final captionColor =
    isDark ? AppColors.slate500 : AppColors.slate400;
    final borderColor = isDark
        ? const Color(0xFF1E3A5F).withValues(alpha: 0.6)
        : AppColors.slate200;
    final inputBg =
    isDark ? const Color(0xFF111C28) : const Color(0xFFF0F4F8);

    final plantType = widget.crop['plantType'] as String?;
    final accentColor =
    _isCustomSpecies ? AppColors.blue : _plantColor(plantType);
    final isHealthy = _healthStatus == 'healthy';
    final scanCount = (widget.crop['scanCount'] as int?) ?? 0;
    final fieldSize = widget.crop['fieldSize'] as String? ?? '';
    final notes = widget.crop['notes'] as String? ?? '';
    final lastScan = widget.crop['lastScanDate'] as String?;
    final scientificName = widget.crop['scientificName'] as String? ??
        (!_isCustomSpecies
            ? AppSpecies.allSpecies
            .firstWhere(
                (s) =>
            s.nameEn.toLowerCase() ==
                (plantType ?? '').toLowerCase(),
            orElse: () => AppSpecies.allSpecies.first)
            .scientificName
            : '');

    return AnimatedBuilder(
      animation: _slideAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 30 * (1 - _slideAnim.value)),
        child: Opacity(opacity: _slideAnim.value.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
              blurRadius: 40,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Hero Section ──────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.1),
                    accentColor.withValues(alpha: 0.03),
                  ],
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: accentColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  // Plant emoji badge
                  Container(
                    width: 62, height: 62,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        _plantEmoji(plantType),
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.crop['name'] as String? ??
                              (t.get('ui_unnamed')),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isCustomSpecies
                              ? (plantType ?? '')
                              : (t.isUrdu
                              ? AppSpecies.allSpecies
                              .firstWhere(
                                  (s) =>
                              s.nameEn == plantType,
                              orElse: () =>
                              AppSpecies.allSpecies.first)
                              .nameUr
                              : (plantType ?? '')),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                        if (scientificName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            scientificName,
                            style: TextStyle(
                              fontSize: 11,
                              color: captionColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (_isCustomSpecies) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.blue
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.blue
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              t.get('ui_custom_species'),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.blue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Health status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isHealthy
                          ? AppColors.emerald.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isHealthy
                            ? AppColors.emerald.withValues(alpha: 0.3)
                            : AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isHealthy
                              ? Icons.favorite_rounded
                              : Icons.sick_rounded,
                          size: 18,
                          color: isHealthy
                              ? AppColors.emerald
                              : AppColors.error,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isHealthy
                              ? (t.get('ui_ok'))
                              : (t.get('ui_sick')),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isHealthy
                                ? AppColors.emerald
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable content ────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Quick stats row ──────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            icon: Icons.qr_code_scanner_rounded,
                            label: t.get('ui_scans'),
                            value: '$scanCount',
                            color: AppColors.violet,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            captionColor: captionColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            icon: Icons.straighten_rounded,
                            label: t.get('ui_acres_2'),
                            value: fieldSize.isEmpty ? '—' : fieldSize,
                            color: AppColors.blue,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            captionColor: captionColor,
                          ),
                        ),
                        if (lastScan != null) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: _statCard(
                              icon: Icons.schedule_rounded,
                              label: t.get('ui_last'),
                              value: lastScan,
                              color: AppColors.warning,
                              cardBg: cardBg,
                              borderColor: borderColor,
                              textColor: textColor,
                              captionColor: captionColor,
                              valueSmall: true,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // ── Notes (if any) ───────────────────────────────
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.sticky_note_2_rounded,
                                size: 16,
                                color: captionColor.withValues(alpha: 0.7)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.get('ui_notes'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: captionColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notes,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textColor,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Health toggle ─────────────────────────────────
                    Text(
                      t.get('ui_health_status'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _healthToggle(
                            label: t.get('ui_healthy_3'),
                            icon: Icons.favorite_rounded,
                            color: AppColors.emerald,
                            selected: isHealthy,
                            onTap: () {
                              setState(() => _healthStatus = 'healthy');
                              widget.onUpdateHealth('healthy');
                              HapticFeedback.lightImpact();
                            },
                            isDark: isDark,
                            borderColor: borderColor,
                            cardBg: cardBg,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _healthToggle(
                            label: t.get('ui_diseased_2'),
                            icon: Icons.sick_rounded,
                            color: AppColors.error,
                            selected: !isHealthy,
                            onTap: () {
                              setState(() => _healthStatus = 'diseased');
                              widget.onUpdateHealth('diseased');
                              HapticFeedback.lightImpact();
                            },
                            isDark: isDark,
                            borderColor: borderColor,
                            cardBg: cardBg,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── AI Info Button ────────────────────────────────
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => CropInfoSheet(
                            cropName:
                            widget.crop['name'] as String? ?? '',
                            plantType:
                            widget.crop['plantType'] as String? ??
                                'default',
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.emerald.withValues(alpha: 0.9),
                              AppColors.emeraldDark,
                            ],
                            begin: AlignmentDirectional.topStart,
                            end: AlignmentDirectional.bottomEnd,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.emerald
                                  .withValues(alpha: 0.3),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.auto_awesome_rounded,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.get('ui_get_ai_crop_intelligence'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    t.get('ui_diseases_tips_full_crop_guide'),
                                    style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.75),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 14),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Delete button ─────────────────────────────────
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _showDeleteConfirm(context, t, isDark, borderColor,
                            textColor, captionColor);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.error
                                  .withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.delete_outline_rounded,
                                color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              t.get('ui_delete_crop'),
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, TranslationService t,
      bool isDark, Color borderColor, Color textColor, Color captionColor) {
    final sheetBg =
    isDark ? const Color(0xFF0F1923) : const Color(0xFFFAFBFC);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: borderColor, borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_rounded,
                  color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              t.get('ui_delete_this_crop'),
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              t.get('ui_this_action_cannot_be_undone'),
              style: TextStyle(fontSize: 13, color: captionColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: borderColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          t.get('ui_cancel'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onDelete();
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          t.get('ui_delete'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color captionColor,
    bool valueSmall = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: valueSmall ? 12 : 20,
              fontWeight: FontWeight.w900,
              color: textColor,
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: captionColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthToggle({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
    required Color borderColor,
    required Color cardBg,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.4) : borderColor,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected
                    ? color
                    : (isDark
                    ? AppColors.slate500
                    : AppColors.slate400)),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected
                    ? color
                    : (isDark
                    ? AppColors.slate500
                    : AppColors.slate400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}