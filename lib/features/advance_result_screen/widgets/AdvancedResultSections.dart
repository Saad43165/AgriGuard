import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/translation_service.dart';
import '../../../core/widgets/app_themes.dart';
import 'image_preview_results.dart';

class AdvancedResultSections extends StatelessWidget {
  final Map<String, dynamic> analysisResult;
  final Map<String, dynamic> originalScanData;
  final Uint8List? imageBytes;
  final bool hasDiseaseInfo;
  final String source;

  final bool symptomsExpanded;
  final bool treatmentExpanded;
  final bool preventiveExpanded;
  final VoidCallback onToggleSymptoms;
  final VoidCallback onToggleTreatment;
  final VoidCallback onTogglePreventive;

  final bool isAlreadySaved;

  const AdvancedResultSections({
    super.key,
    required this.analysisResult,
    required this.originalScanData,
    required this.imageBytes,
    required this.hasDiseaseInfo,
    required this.source,
    required this.symptomsExpanded,
    required this.treatmentExpanded,
    required this.preventiveExpanded,
    required this.onToggleSymptoms,
    required this.onToggleTreatment,
    required this.onTogglePreventive,
    required this.isAlreadySaved,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);
    final data = analysisResult['data'] as Map<String, dynamic>? ?? {};
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSourceBadge(source),
          const SizedBox(height: 14),
          _buildDiagnosisCard(data, isDark, t),
          const SizedBox(height: 14),

          if (imageBytes != null || _hasImage()) _buildImageCard(context, isDark, borderColor),
          if (imageBytes != null || _hasImage()) const SizedBox(height: 14),

          _buildCollapsibleSection(
            isDark: isDark,
            title: t.get('results.symptoms_detected'),
            icon: Icons.visibility_outlined,
            color: AppColors.info,
            items: t.translateList((data['symptoms'] as List<dynamic>?)?.cast<String>() ?? []),
            isExpanded: symptomsExpanded,
            onToggle: onToggleSymptoms,
          ),
          const SizedBox(height: 14),

          _buildCollapsibleSection(
            isDark: isDark,
            title: t.get('results.treatment_recommendations'),
            icon: Icons.medical_services_outlined,
            color: AppColors.success,
            items: t.translateList((data['remediation'] as List<dynamic>?)?.cast<String>() ?? []),
            isExpanded: treatmentExpanded,
            onToggle: onToggleTreatment,
          ),
          const SizedBox(height: 14),

          _buildCollapsibleSection(
            isDark: isDark,
            title: t.get('results.preventive_measures'),
            icon: Icons.shield_outlined,
            color: AppColors.warning,
            items: t.translateList((data['precautions'] as List<dynamic>?)?.cast<String>() ?? []),
            isExpanded: preventiveExpanded,
            onToggle: onTogglePreventive,
          ),

          if (data['additionalInfo'] != null) ...[
            const SizedBox(height: 14),
            _buildAdditionalInfoCard(
              data['additionalInfo'] as String,
              hasDiseaseInfo,
              isDark,
              t,
            ),
          ],

          if (isAlreadySaved) ...[
            const SizedBox(height: 16),
            _buildSavedIndicator(t),
          ],
        ],
      ),
    );
  }

  bool _hasImage() {
    final imagePath = originalScanData['imagePath'] as String?;
    final imageBase64 = originalScanData['imageBase64'] as String?;
    final imageUrl = originalScanData['imageUrl'] as String?;
    if (imageBase64 != null && imageBase64.isNotEmpty) return true;
    if (imageUrl != null && imageUrl.isNotEmpty) return true;
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        return File(imagePath).existsSync();
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppColors.error;
      case 'high':
        return const Color(0xFFEA580C);
      case 'medium':
        return AppColors.warning;
      case 'low':
        return const Color(0xFFCA8A04);
      case 'healthy':
      case 'none':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  Color _getSourceColor(String source) {
    final s = source.toLowerCase();
    if (s.contains('groq')) return AppColors.secondary;
    if (s.contains('planthealth')) return AppColors.info;
    if (s.contains('plant')) return AppColors.success;
    return AppColors.primary;
  }

  IconData _getSourceIcon(String source) {
    final s = source.toLowerCase();
    if (s.contains('groq')) return Icons.psychology_rounded;
    if (s.contains('planthealth')) return Icons.cloud_rounded;
    if (s.contains('plant')) return Icons.local_florist_rounded;
    return Icons.auto_awesome_rounded;
  }

  Widget _buildSourceBadge(String source) {
    final color = _getSourceColor(source);
    final icon = _getSourceIcon(source);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            source,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisCard(Map<String, dynamic> data, bool isDark, TranslationService t) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    final severity = data['severity'] as String? ?? data['severityLevel'] as String? ?? 'Unknown';
    final plantNameRaw = data['plantName'] as String? ?? data['plant'] as String? ?? '-';
    final scientificNameRaw = data['scientificName'] as String? ?? '';
    final plantNameUrdu = data['plantNameUrdu'] as String? ?? '';
    final plantDescription = data['plantDescription'] as String? ?? '';
    final diseaseNameRaw = data['diseaseName'] as String? ?? data['disease'] as String? ?? '-';
    final confidence = data['confidence'];

    // Prefer common name over scientific name, and use Urdu name when available
    final displayPlantRaw = plantNameRaw.isNotEmpty && plantNameRaw != '-' ? plantNameRaw : scientificNameRaw;
    final bool hasMeaningfulPlantName = displayPlantRaw.isNotEmpty &&
        displayPlantRaw != '-' &&
        displayPlantRaw.toLowerCase() != 'unknown plant';

    final plantName = hasMeaningfulPlantName ? t.translatePlant(displayPlantRaw) : '';
    final plantNameFinal = t.isUrdu && plantNameUrdu.isNotEmpty ? plantNameUrdu : plantName;
    final diseaseName = diseaseNameRaw.toLowerCase() == 'healthy'
        ? (t.isUrdu ? 'صحت مند' : 'Healthy')
        : t.translateDisease(diseaseNameRaw);
    final severityDisplay = t.translateSeverity(severity);

    String confText = '-';
    if (confidence is int) confText = '$confidence%';
    if (confidence is double) confText = '${confidence.round()}%';
    if (confidence is String) confText = confidence.contains('%') ? confidence : '$confidence%';

    final severityColor = _getSeverityColor(severity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.biotech_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasMeaningfulPlantName) ...[
                      Text(t.get('results.plant_name'),
                          style: TextStyle(fontSize: 11, color: captionColor, fontWeight: FontWeight.w600)),
                      Text(plantNameFinal,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
                      if (plantDescription.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(plantDescription,
                            style: TextStyle(fontSize: 12, color: captionColor, fontStyle: FontStyle.italic)),
                      ],
                      const SizedBox(height: 4),
                    ],
                    Text(t.get('results.disease'),
                        style: TextStyle(fontSize: 11, color: captionColor, fontWeight: FontWeight.w600)),
                    Text(diseaseName,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: severityColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _infoChip(
                  label: t.get('results.severity'),
                  value: severityDisplay,
                  color: severityColor,
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoChip(
                  label: t.get('results.confidence'),
                  value: confText,
                  color: AppColors.primary,
                  icon: Icons.percent_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(BuildContext context, bool isDark, Color borderColor) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ImagePreviewResults(
        originalScanData: originalScanData,
        theme: Theme.of(context),
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${items.length}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: captionColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded && items.isNotEmpty) ...[
            Divider(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          if (isExpanded && items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Text('-',
                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkCaption : AppColors.lightCaption)),
            ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard(
    String info,
    bool hasDiseaseInfo,
    bool isDark,
    TranslationService t,
  ) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final accentColor = hasDiseaseInfo ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasDiseaseInfo ? Icons.medical_services_outlined : Icons.info_outline_rounded,
                  size: 16,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                t.get('results.additional_info'),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            info,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedIndicator(TranslationService t) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              color: AppColors.success.withValues(alpha: 0.7), size: 15),
          const SizedBox(width: 6),
          Text(
            t.get('results.saved_to_history'),
            style: TextStyle(
              color: AppColors.success.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}