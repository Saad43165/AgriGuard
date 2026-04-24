import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_fyp/core/services/translation_service.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';
import '../disease_data.dart';

class DiseaseChip extends StatelessWidget {
  final String label;
  final bool selected, isDark;
  final VoidCallback onTap;
  const DiseaseChip({super.key, required this.label, required this.selected, required this.isDark, required this.onTap});

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

class DiseaseCard extends StatelessWidget {
  final DiseaseEntry entry;
  final bool isDark;
  final VoidCallback onTap;
  const DiseaseCard({super.key, required this.entry, required this.isDark, required this.onTap});

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
    final t = Provider.of<TranslationService>(context);
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
