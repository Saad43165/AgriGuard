// lib/features/advance_result_screen/advanced_result_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/translation_service.dart';
import '../../core/widgets/app_bar.dart';
import '../../core/widgets/app_themes.dart';
import 'components/additional_info_card.dart';
import 'components/image_preview_results.dart';
import 'components/result_action_button.dart' show ResultActionButton;
import 'components/section_card.dart';
import '../../core/repositories/scan_repository.dart';
import '../auth/Login_Screen/services/guest_service.dart';

class AdvancedResultsScreen extends StatefulWidget {
  final Map<String, dynamic> analysisResult;
  final Map<String, dynamic> originalScanData;

  const AdvancedResultsScreen({
    super.key,
    required this.analysisResult,
    required this.originalScanData,
  });

  @override
  State<AdvancedResultsScreen> createState() => _AdvancedResultsScreenState();
}

class _AdvancedResultsScreenState extends State<AdvancedResultsScreen>
    with TickerProviderStateMixin {
  late final ScanRepository _scanRepository;
  final GuestService _guestService = GuestService();
  bool _isGuestMode = false;
  bool _isProcessing = false;
  bool _isAlreadySaved = false;
  Uint8List? _imageBytes;

  // Collapsible section states
  bool _symptomsExpanded = true;
  bool _treatmentExpanded = true;
  bool _preventiveExpanded = true;

  @override
  void initState() {
    super.initState();
    _scanRepository = ScanRepository();
    _loadImageBytes();
    _initializeGuestMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAutoSaveScan();
    });
  }

  Future<void> _initializeGuestMode() async {
    await _guestService.initialize();
    if (mounted) setState(() => _isGuestMode = _guestService.isGuestMode);
  }

  Future<void> _loadImageBytes() async {
    try {
      final imagePath = widget.originalScanData['imagePath'] as String?;
      final imageBase64 = widget.originalScanData['imageBase64'] as String?;
      if (imageBase64 != null) {
        _imageBytes = base64Decode(imageBase64);
      } else if (imagePath != null) {
        final file = File(imagePath);
        if (await file.exists()) {
          _imageBytes = await file.readAsBytes();
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading image bytes: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _generateScanId() {
    final dataHash = jsonEncode(widget.analysisResult).hashCode.abs();
    final imagePathHash = widget.originalScanData['imagePath']?.hashCode ?? 0;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'advanced_${dataHash}_${imagePathHash}_$timestamp';
  }

  Future<void> _checkAndAutoSaveScan() async {
    final isFromHistory = widget.originalScanData['isFromHistory'] == true ||
        widget.originalScanData['skipSave'] == true ||
        widget.originalScanData['databaseId'] != null;

    if (isFromHistory) {
      setState(() => _isAlreadySaved = true);
      return;
    }

    if (_isAlreadySaved || _isProcessing) return;
    if (_isGuestMode) return;

    setState(() => _isProcessing = true);

    try {
      final originalId = widget.originalScanData['id'] as String?;
      final scanId = originalId ?? _generateScanId();

      final existing = await _scanRepository.getScanById(scanId);
      if (existing != null) {
        setState(() {
          _isAlreadySaved = true;
          _isProcessing = false;
        });
        return;
      }

      String? imageBase64 = widget.originalScanData['imageBase64'] as String?;
      final imagePath = widget.originalScanData['imagePath'] as String?;

      if (imageBase64 == null && imagePath != null) {
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            imageBase64 = base64Encode(bytes);
          }
        } catch (e) {
          debugPrint('Failed to convert image to base64: $e');
        }
      }

      final updatedAnalysisResult = {
        ...widget.analysisResult,
        'scanId': scanId,
      };

      final source =
          updatedAnalysisResult['source']?.toString().toLowerCase() ?? 'groq';
      final isGroq = source.contains('groq');
      final isHuggingFace =
          source.contains('hugging') || source.contains('hf');

      final savedScan = isGroq
          ? await _scanRepository.saveGroqScan(
              analysisResult: updatedAnalysisResult,
              imagePath: imagePath,
            )
          : isHuggingFace
              ? await _scanRepository.saveHuggingFaceScan(
                  analysisResult: updatedAnalysisResult,
                  imagePath: imagePath,
                )
              : await _scanRepository.savePlantIdScan(
                  analysisResult: updatedAnalysisResult,
                  imagePath: imagePath,
                );

      debugPrint('Advanced scan auto-saved → ID: ${savedScan.id}');

      if (mounted) {
        setState(() {
          _isAlreadySaved = true;
          _isProcessing = false;
        });
      }
    } catch (e, stack) {
      debugPrint('Auto-save failed: $e\n$stack');
      if (mounted) setState(() => _isProcessing = false);
    }
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
    if (s.contains('hugging') || s.contains('hf')) return AppColors.info;
    if (s.contains('plant')) return AppColors.success;
    return AppColors.primary;
  }

  IconData _getSourceIcon(String source) {
    final s = source.toLowerCase();
    if (s.contains('groq')) return Icons.psychology_rounded;
    if (s.contains('hugging') || s.contains('hf')) return Icons.cloud_rounded;
    if (s.contains('plant')) return Icons.local_florist_rounded;
    return Icons.auto_awesome_rounded;
  }

  Future<void> _handleShare(
      TranslationService t, Map<String, dynamic> data) async {
    HapticFeedback.lightImpact();
    final source = widget.analysisResult['source'] as String? ?? 'AI';
    final plant = data['plantName'] as String? ?? data['plant'] as String? ?? '-';
    final disease =
        data['diseaseName'] as String? ?? data['disease'] as String? ?? '-';
    final severity = data['severity'] as String? ?? '-';
    final confidence = data['confidence'];
    final confText = confidence != null ? '$confidence%' : '-';

    final text = '''
🌿 AgriGuard ${t.get('results.advanced_title')}

🔬 ${t.get('source.analyzed_by')}: $source
🌱 ${t.get('results.plant_name')}: $plant
🦠 ${t.get('results.disease')}: $disease
⚠️ ${t.get('results.severity')}: $severity
📊 ${t.get('results.confidence')}: $confText
''';

    await Share.share(text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);
    final data = widget.analysisResult['data'] as Map<String, dynamic>? ?? {};
    final hasDiseaseInfo =
        widget.analysisResult['hasDiseaseInfo'] as bool? ?? false;
    final source =
        widget.analysisResult['source'] as String? ?? 'AI';

    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor, size: 22),
          onPressed: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
        ),
        title: Text(
          t.get('results.advanced_title'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        actions: [
          AppBarIconButton(
            icon: Icons.share_rounded,
            tooltip: t.get('share'),
            onPressed: () => _handleShare(t, data),
          ),
          AppBarIconButton(
            icon: Icons.translate_rounded,
            color: t.isUrdu ? AppColors.secondary : AppColors.primary,
            tooltip: t.isUrdu
                ? t.get('buttons.switch_to_english')
                : t.get('buttons.switch_to_urdu'),
            onPressed: () { HapticFeedback.lightImpact(); t.toggleLanguage(); },
          ),
        ],
      ),
      floatingActionButton: ResultActionButton(
        analysisResult: widget.analysisResult,
        originalScanData: widget.originalScanData,
        plantImageBytes: _imageBytes,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source badge
            _buildSourceBadge(source, isDark),
            const SizedBox(height: 14),

            // Main diagnosis card
            _buildDiagnosisCard(data, isDark, t),
            const SizedBox(height: 14),

            // Image preview
            if (_imageBytes != null || _hasImage())
              _buildImageCard(isDark, borderColor),
            if (_imageBytes != null || _hasImage())
              const SizedBox(height: 14),

            // Symptoms
            _buildCollapsibleSection(
              isDark: isDark,
              title: t.get('results.symptoms_detected'),
              icon: Icons.visibility_outlined,
              color: AppColors.info,
              items: (data['symptoms'] as List<dynamic>?)?.cast<String>() ?? [],
              isExpanded: _symptomsExpanded,
              onToggle: () =>
                  setState(() => _symptomsExpanded = !_symptomsExpanded),
            ),
            const SizedBox(height: 14),

            // Treatment
            _buildCollapsibleSection(
              isDark: isDark,
              title: t.get('results.treatment_recommendations'),
              icon: Icons.medical_services_outlined,
              color: AppColors.success,
              items:
                  (data['remediation'] as List<dynamic>?)?.cast<String>() ?? [],
              isExpanded: _treatmentExpanded,
              onToggle: () =>
                  setState(() => _treatmentExpanded = !_treatmentExpanded),
            ),
            const SizedBox(height: 14),

            // Preventive measures
            _buildCollapsibleSection(
              isDark: isDark,
              title: t.get('results.preventive_measures'),
              icon: Icons.shield_outlined,
              color: AppColors.warning,
              items:
                  (data['precautions'] as List<dynamic>?)?.cast<String>() ?? [],
              isExpanded: _preventiveExpanded,
              onToggle: () =>
                  setState(() => _preventiveExpanded = !_preventiveExpanded),
            ),

            // Additional info
            if (data['additionalInfo'] != null) ...[
              const SizedBox(height: 14),
              _buildAdditionalInfoCard(
                  data['additionalInfo'] as String, hasDiseaseInfo, isDark, t),
            ],

            // Saved indicator
            if (_isAlreadySaved) ...[
              const SizedBox(height: 16),
              _buildSavedIndicator(t),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasImage() {
    final imagePath = widget.originalScanData['imagePath'] as String?;
    final imageBase64 = widget.originalScanData['imageBase64'] as String?;
    final imageUrl = widget.originalScanData['imageUrl'] as String?;
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

  Widget _buildSourceBadge(String source, bool isDark) {
    final color = _getSourceColor(source);
    final icon = _getSourceIcon(source);
    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosisCard(
      Map<String, dynamic> data, bool isDark, TranslationService t) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor =
        isDark ? AppColors.darkCaption : AppColors.lightCaption;

    final severity =
        data['severity'] as String? ?? data['severityLevel'] as String? ?? 'Unknown';
    final plantName =
        data['plantName'] as String? ?? data['plant'] as String? ?? '-';
    final diseaseName =
        data['diseaseName'] as String? ?? data['disease'] as String? ?? '-';
    final confidence = data['confidence'];

    String confText = '-';
    if (confidence is int) {
      confText = '$confidence%';
    } else if (confidence is double) {
      confText = '${confidence.round()}%';
    } else if (confidence is String) {
      confText = confidence.contains('%') ? confidence : '$confidence%';
    }

    final severityColor = _getSeverityColor(severity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.biotech_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.get('results.plant_name'),
                      style: TextStyle(
                          fontSize: 11,
                          color: captionColor,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      plantName,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.get('results.disease'),
                      style: TextStyle(
                          fontSize: 11,
                          color: captionColor,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      diseaseName,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: severityColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  label: t.get('results.severity'),
                  value: severity,
                  color: severityColor,
                  icon: Icons.warning_amber_rounded,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoChip(
                  label: t.get('results.confidence'),
                  value: confText,
                  color: AppColors.primary,
                  icon: Icons.percent_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
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
                    style: TextStyle(
                        fontSize: 10,
                        color: color.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600)),
                Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(bool isDark, Color borderColor) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ImagePreviewResults(
        originalScanData: widget.originalScanData,
        theme: theme,
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
    final textColor =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor =
        isDark ? AppColors.darkCaption : AppColors.lightCaption;

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
                    child: Text(
                      title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${items.length}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
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
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.darkSubtext
                                        : AppColors.lightSubtext,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
          if (isExpanded && items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Text(
                '-',
                style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkCaption
                        : AppColors.lightCaption),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard(
      String info, bool hasDiseaseInfo, bool isDark, TranslationService t) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
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
                  hasDiseaseInfo
                      ? Icons.medical_services_outlined
                      : Icons.info_outline_rounded,
                  size: 16,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                t.get('results.additional_info'),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            info,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              height: 1.5,
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
