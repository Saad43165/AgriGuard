import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../../core/services/translation_service.dart';
import '../../../../../core/widgets/app_themes.dart';
import '../../../result_screen/presentation/results_screen.dart';
import '../../../advance_result_screen/advanced_result_screen.dart';

class ScanCard extends StatefulWidget {
  final Map<String, dynamic> scan;
  final int index;
  final Animation<double> scaleAnimation;
  final void Function(Map<String, dynamic>) onShowOptions;
  final bool showFullPlantName;

  const ScanCard({
    super.key,
    required this.scan,
    required this.index,
    required this.scaleAnimation,
    required this.onShowOptions,
    this.showFullPlantName = true,
  });

  @override
  State<ScanCard> createState() => _ScanCardState();
}

class _ScanCardState extends State<ScanCard> with SingleTickerProviderStateMixin {
  late final String _formattedDate;
  late final double _confidence;
  late AnimationController _pressCtrl;
  late Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _formattedDate = _formatTimestamp(widget.scan['timestamp'] ?? widget.scan['scanDate']);
    _confidence = double.tryParse(widget.scan['confidence'].toString()) ?? 0;
    _pressCtrl = AnimationController(duration: const Duration(milliseconds: 100), vsync: this);
    _pressAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    try {
      DateTime? dt;
      if (ts is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(ts);
      } else if (ts is Timestamp) dt = ts.toDate();
      else if (ts is DateTime)  dt = ts;
      else if (ts is String)    dt = DateTime.tryParse(ts);
      return dt != null ? DateFormat('MMM d').format(dt) : '';
    } catch (_) { return ''; }
  }

  bool get _isAdvanced =>
      widget.scan['isAdvanced'] == true ||
      widget.scan['scanType']?.toString() == 'advanced' ||
      ['groq','huggingface','plantid','plantId'].contains(widget.scan['analysisSource']?.toString());

  String get _plantName => widget.scan['plantName']?.toString() ?? 'Unknown';
  String get _disease {
    // Prefer diseaseName directly — diagnosis field contains emoji-prefixed strings
    final d = widget.scan['diseaseName']?.toString();
    if (d != null && d.isNotEmpty) return d;
    // Fallback: strip emoji prefix from diagnosis
    final diag = widget.scan['diagnosis']?.toString() ?? '';
    if (diag.contains(' on ')) return diag.split(' on ').first.replaceAll(RegExp(r'^[^\w]+'), '').trim();
    return diag.replaceAll(RegExp(r'^[^\w]+'), '').trim().isNotEmpty
        ? diag.replaceAll(RegExp(r'^[^\w]+'), '').trim()
        : 'Healthy';
  }
  String get _severity  => widget.scan['severity']?.toString() ?? '';
  bool   get _isHealthy => _disease.toLowerCase() == 'healthy' || _disease.toLowerCase().contains('healthy');
  Color  get _statusColor => _isHealthy ? AppColors.success : AppColors.warning;

  Color get _severityColor {
    switch (_severity.toLowerCase()) {
      case 'low':      return AppColors.info;
      case 'medium':   return AppColors.warning;
      case 'high':     return AppColors.error;
      case 'critical': return const Color(0xFFDC2626);
      case 'none':     return AppColors.success;
      default:         return AppColors.lightCaption;
    }
  }

  Color get _confidenceColor {
    if (_confidence >= 80) return AppColors.success;
    if (_confidence >= 60) return AppColors.warning;
    return AppColors.error;
  }

  void _navigate() {
    HapticFeedback.lightImpact();
    if (_isAdvanced) {
      // Reconstruct full data map from all available fields
      final rawData = widget.scan['rawData'];
      final advancedData = widget.scan['advancedData'];

      Map<String, dynamic> data = {};
      if (advancedData is Map<String, dynamic> && advancedData.isNotEmpty) {
        data = Map<String, dynamic>.from(advancedData);
      } else if (rawData is Map<String, dynamic> && rawData['data'] is Map<String, dynamic>) {
        data = Map<String, dynamic>.from(rawData['data'] as Map<String, dynamic>);
      }

      List<String> remediation = [];
      final remRaw = data['remediation'] ?? widget.scan['treatments'] ?? widget.scan['remediation'] ?? [];
      if (remRaw is List) remediation = List<String>.from(remRaw.map((e) => e.toString()));

      List<String> symptoms = [];
      final symRaw = data['symptoms'] ?? widget.scan['symptoms'] ?? [];
      if (symRaw is List) symptoms = List<String>.from(symRaw.map((e) => e.toString()));

      List<String> precautions = [];
      final preRaw = data['precautions'] ?? widget.scan['precautions'] ?? [];
      if (preRaw is List) precautions = List<String>.from(preRaw.map((e) => e.toString()));

      final finalData = {
        ...data,
        'plantName': data['plantName'] ?? data['plant'] ?? _plantName,
        'plant': data['plant'] ?? data['plantName'] ?? _plantName,
        'diseaseName': data['diseaseName'] ?? data['disease'] ?? _disease,
        'disease': data['disease'] ?? data['diseaseName'] ?? _disease,
        'confidence': data['confidence'] ?? widget.scan['confidence']?.toString() ?? '0',
        'severity': data['severity'] ?? _severity,
        'symptoms': symptoms,
        'remediation': remediation,
        'precautions': precautions,
        'cause': data['cause'] ?? 'Saved scan from history',
      };

      Navigator.push(context, MaterialPageRoute(builder: (_) => AdvancedResultsScreen(
        analysisResult: {
          'source': widget.scan['analysisSource']?.toString() ?? 'Groq AI',
          'data': finalData,
          'success': true,
          'hasDiseaseInfo': !_isHealthy,
          'scanId': widget.scan['id'],
        },
        originalScanData: {
          'imagePath': widget.scan['imagePath'],
          'imageUrl': widget.scan['imageUrl'],
          'imageBase64': widget.scan['imageBase64'],
          'isFromHistory': true,
          'skipSave': true,
          'alreadySaved': true,
          'id': widget.scan['id'],
        },
      )));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ResultsScreen(
        scanData: {...widget.scan, 'isFromHistory': true, 'skipSave': true, 'alreadySaved': true},
      )));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final textSub = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return ScaleTransition(
      scale: _pressAnim,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) { _pressCtrl.reverse(); _navigate(); },
        onTapCancel: () => _pressCtrl.reverse(),
        onLongPress: () { HapticFeedback.mediumImpact(); widget.onShowOptions(widget.scan); },
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 6, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image — fixed height, no overflow
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                child: SizedBox(
                  height: 85,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(isDark),
                      // Confidence badge
                      Positioned(
                        top: 5, right: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: _confidenceColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${_confidence.toInt()}%',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                      ),
                      // AI badge
                      if (_isAdvanced)
                        Positioned(
                          top: 5, left: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text('AI', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      // Date overlay
                      if (_formattedDate.isNotEmpty)
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
                              ),
                            ),
                            child: Text(_formattedDate,
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Info — intrinsic height, no Expanded/Flexible
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                child: Builder(builder: (context) {
                  final t = Provider.of<TranslationService>(context);
                  final displayPlant = t.translatePlant(_plantName);
                  final displayDisease = _isHealthy
                      ? (t.isUrdu ? 'صحت مند' : 'Healthy')
                      : t.translateDisease(_disease);
                  final displaySeverity = t.translateSeverity(_severity);
                  return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Plant name
                    Text(displayPlant,
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800,
                        color: textPrimary, height: 1.2),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),

                    // Disease status — no Expanded inside
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: isDark ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: _statusColor.withValues(alpha: 0.4), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isHealthy ? Icons.check_circle_rounded : Icons.warning_rounded,
                            size: 10, color: _statusColor,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(displayDisease,
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                                color: _statusColor, height: 1.2),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),

                    // Severity row
                    if (_severity.isNotEmpty && _severity.toLowerCase() != 'none' && !_isHealthy) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(color: _severityColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text(displaySeverity,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _severityColor)),
                          const SizedBox(width: 4),
                          Text(t.isUrdu ? 'شدت' : 'severity', style: TextStyle(fontSize: 8, color: textSub)),
                        ],
                      ),
                    ],
                  ],
                );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(bool isDark) {
    final base64 = widget.scan['imageBase64']?.toString();
    if (base64 != null && base64.isNotEmpty) {
      try { return Image.memory(base64Decode(base64), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(isDark)); }
      catch (_) {}
    }
    final url = widget.scan['imageUrl']?.toString();
    if (url != null && url.isNotEmpty) {
      return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(isDark));
    }
    final path = widget.scan['imagePath']?.toString();
    if (path != null && path.isNotEmpty) {
      final f = File(path);
      if (f.existsSync()) return Image.file(f, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(isDark));
    }
    return _placeholder(isDark);
  }

  Widget _placeholder(bool isDark) => Container(
    color: isDark ? const Color(0xFF1C2333) : const Color(0xFFE8F4FD),
    child: Center(child: Icon(Icons.eco_rounded, size: 28, color: AppColors.primary.withValues(alpha: 0.5))),
  );
}
