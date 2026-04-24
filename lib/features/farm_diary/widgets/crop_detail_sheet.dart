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
  const CropDetailSheet({super.key, required this.crop, required this.onDelete, required this.onUpdateHealth});
  @override
  State<CropDetailSheet> createState() => _CropDetailSheetState();
}

class _CropDetailSheetState extends State<CropDetailSheet> {
  late String _healthStatus;

  @override
  void initState() {
    super.initState();
    _healthStatus = widget.crop['healthStatus'] as String? ?? 'healthy';
  }

  Color _plantColor(String? plantType) {
    final species = AppSpecies.allSpecies.firstWhere(
      (s) => s.nameEn.toLowerCase() == (plantType ?? '').toLowerCase(),
      orElse: () => AppSpecies.allSpecies.first,
    );
    return species.color;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final t = Provider.of<TranslationService>(context);
    final plantType = widget.crop['plantType'] as String?;
    final accentColor = _plantColor(plantType);
    final isHealthy = _healthStatus == 'healthy';
    final scanCount = (widget.crop['scanCount'] as int?) ?? 0;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: borderColor),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_florist_rounded, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.crop['name'] as String? ?? (t.isUrdu ? 'بے نام' : 'Unnamed'),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                  Text(t.isUrdu
                      ? AppSpecies.allSpecies.firstWhere(
                          (s) => s.nameEn == plantType,
                          orElse: () => AppSpecies.allSpecies.first).nameUr
                      : (plantType ?? (t.isUrdu ? 'نامعلوم' : 'Unknown')),
                      style: TextStyle(fontSize: 13, color: captionColor, fontWeight: FontWeight.w600)),
                ],
              )),
            ]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$scanCount', style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary)),
                  Text(t.get('scan_count'), style: TextStyle(fontSize: 12, color: captionColor)),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            _infoRow(icon: Icons.straighten_rounded, label: t.get('field_size'),
                value: '${widget.crop['fieldSize'] ?? '-'} ${t.get('acres')}', isDark: isDark),
            if ((widget.crop['lastScanDate'] as String?) != null) ...[
              const SizedBox(height: 10),
              _infoRow(icon: Icons.schedule_rounded, label: t.get('last_activity'),
                  value: widget.crop['lastScanDate'] as String, isDark: isDark),
            ],
            if ((widget.crop['notes'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              _infoRow(icon: Icons.notes_rounded, label: t.get('notes'),
                  value: widget.crop['notes'] as String, isDark: isDark),
            ],
            const SizedBox(height: 20),
            Divider(color: borderColor),
            const SizedBox(height: 16),
            Text(t.get('update_health'),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _healthToggleBtn(
                label: t.get('healthy_status'), icon: Icons.check_circle_outline_rounded,
                color: AppColors.success, selected: isHealthy,
                onTap: () { setState(() => _healthStatus = 'healthy'); widget.onUpdateHealth('healthy'); },
                isDark: isDark,
              )),
              const SizedBox(width: 10),
              Expanded(child: _healthToggleBtn(
                label: t.get('diseased_status'), icon: Icons.warning_amber_rounded,
                color: AppColors.error, selected: !isHealthy,
                onTap: () { setState(() => _healthStatus = 'diseased'); widget.onUpdateHealth('diseased'); },
                isDark: isDark,
              )),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                    builder: (_) => CropInfoSheet(
                      cropName: widget.crop['name'] as String? ?? '',
                      plantType: widget.crop['plantType'] as String? ?? 'default',
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                label: Text(t.isUrdu ? 'فصل کی معلومات اور بیماری گائیڈ' : 'Get Crop Info & Disease Guide'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () { HapticFeedback.mediumImpact(); widget.onDelete(); },
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                label: Text(t.get('delete_crop'),
                    style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String label, required String value, required bool isDark}) {
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(width: 8),
      Text('$label: ', style: TextStyle(fontSize: 13, color: captionColor, fontWeight: FontWeight.w600)),
      Expanded(child: Text(value,
          style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
          maxLines: 2, overflow: TextOverflow.ellipsis)),
    ]);
  }

  Widget _healthToggleBtn({required String label, required IconData icon, required Color color,
      required bool selected, required VoidCallback onTap, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: selected ? color : (isDark ? AppColors.darkCaption : AppColors.lightCaption)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: selected ? color : (isDark ? AppColors.darkCaption : AppColors.lightCaption),
          )),
        ]),
      ),
    );
  }
}
