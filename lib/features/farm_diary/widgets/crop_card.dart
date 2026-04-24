import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/app_themes.dart';
import '../../home/screens/species/plant_species.dart';

class CropCard extends StatelessWidget {
  final Map<String, dynamic> crop;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  const CropCard({super.key, required this.crop, required this.onDelete, required this.onTap});

  Color _plantColor(String? plantType) {
    final species = AppSpecies.allSpecies.firstWhere(
      (s) => s.nameEn.toLowerCase() == (plantType ?? '').toLowerCase(),
      orElse: () => AppSpecies.allSpecies.first,
    );
    return species.color;
  }

  String _speciesEmoji(String? nameEn) {
    const emojis = {
      'Apricot': '🍑', 'Bean': '🫘', 'Cherry': '🍒', 'Corn': '🌽',
      'Fig': '🍈', 'Grape': '🍇', 'Loquat': '🍊', 'Pear': '🍐',
      'Persimmon': '🍅', 'Tomato': '🍅', 'Walnut': '🌰',
    };
    return emojis[nameEn] ?? '🌿';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final plantType = crop['plantType'] as String?;
    final accentColor = _plantColor(plantType);
    final isHealthy = (crop['healthStatus'] as String? ?? 'healthy') == 'healthy';
    final scanCount = (crop['scanCount'] as int?) ?? 0;
    final lastScan = crop['lastScanDate'] as String?;
    final fieldSize = crop['fieldSize'] as String? ?? '';
    final notes = crop['notes'] as String? ?? '';

    final speciesName = t.isUrdu
        ? AppSpecies.allSpecies.firstWhere(
            (s) => s.nameEn == plantType, orElse: () => AppSpecies.allSpecies.first).nameUr
        : (plantType ?? (t.isUrdu ? 'نامعلوم' : 'Unknown'));

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.05 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              // ── Colored accent strip ─────────────────────────────
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accentColor, accentColor.withValues(alpha: 0.3)]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    // ── Plant emoji icon ───────────────────────────
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          _speciesEmoji(plantType),
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ── Main info ──────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + Health badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  crop['name'] as String? ?? (t.isUrdu ? 'بے نام' : 'Unnamed'),
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _healthBadge(isHealthy, t),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Species name
                          Row(children: [
                            Icon(Icons.local_florist_rounded, size: 12, color: accentColor),
                            const SizedBox(width: 4),
                            Text(speciesName,
                                style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w700)),
                            if (fieldSize.isNotEmpty) ...[
                              Text('  ·  ', style: TextStyle(fontSize: 12, color: captionColor)),
                              Icon(Icons.straighten_rounded, size: 12, color: captionColor),
                              const SizedBox(width: 4),
                              Text('$fieldSize ${t.get('acres')}',
                                  style: TextStyle(fontSize: 12, color: captionColor, fontWeight: FontWeight.w500)),
                            ],
                          ]),
                          const SizedBox(height: 6),

                          // Scan count + last scan
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: scanCount > 0
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.qr_code_scanner_rounded, size: 11,
                                    color: scanCount > 0 ? AppColors.primary : captionColor),
                                const SizedBox(width: 4),
                                Text('$scanCount ${t.get('scans')}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: scanCount > 0 ? AppColors.primary : captionColor,
                                    )),
                              ]),
                            ),
                            if (lastScan != null) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.schedule_rounded, size: 11, color: captionColor),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(lastScan,
                                    style: TextStyle(fontSize: 10.5, color: captionColor),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ]),

                          // Notes
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Row(children: [
                              Icon(Icons.notes_rounded, size: 11, color: captionColor),
                              const SizedBox(width: 4),
                              Expanded(child: Text(notes,
                                  style: TextStyle(fontSize: 11, color: captionColor),
                                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ]),
                          ],
                        ],
                      ),
                    ),

                    // ── Chevron ────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: borderColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.chevron_right_rounded, color: captionColor, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _healthBadge(bool isHealthy, TranslationService t) {
    final color = isHealthy ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          isHealthy ? t.get('healthy_status') : t.get('diseased_status'),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
        ),
      ]),
    );
  }
}
