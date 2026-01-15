import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../advance_result_screen/advanced_result_screen.dart';

class AdvanceScanSection extends StatelessWidget {
  final List<Map<String, dynamic>> advancedScans;
  final void Function(Map<String, dynamic> scan) onShowOptions;
  final VoidCallback onShowAllAdvancedScans;
  final Animation<double> scaleAnimation;

  const AdvanceScanSection({
    super.key,
    required this.advancedScans,
    required this.onShowOptions,
    required this.onShowAllAdvancedScans,
    required this.scaleAnimation,
  });

  bool _isAdvancedScan(Map<String, dynamic> scan) {
    return scan['isAdvanced'] as bool? ??
        scan['scanType']?.toString() == 'advanced' ||
            scan['analysisSource']?.toString() == 'gemini' ||
            scan['analysisSource']?.toString() == 'plantid' ||
            scan['analysisSource']?.toString() == 'plantId' ||
            scan['advancedData'] != null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade400]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: const Icon(Icons.cloud, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Advanced AI Scans',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 19, letterSpacing: -0.5),
                      ),
                    ),
                  ],
                ),
              ),
              _buildViewAllButton(context),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: advancedScans.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: advancedScans.length,
            itemBuilder: (context, index) {
              final scan = advancedScans[index];
              return _buildAdvancedScanCard(context, scan, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildViewAllButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onShowAllAdvancedScans,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue.withOpacity(0.15), Colors.blue.withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('View All', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedScanCard(BuildContext context, Map<String, dynamic> scan, int index) {
    final plantName = scan['plantName']?.toString() ?? 'Unknown Plant';
    final diseaseName = scan['diagnosis']?.toString() ?? scan['diseaseName']?.toString() ?? 'Healthy';
    final confidence = double.tryParse(scan['confidence']?.toString() ?? '0') ?? 0;
    final isAdvanced = _isAdvancedScan(scan);

    return Container(
      width: 170,
      margin: EdgeInsets.only(right: index < advancedScans.length - 1 ? 14 : 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blue.shade50.withOpacity(0.5)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openAdvancedScan(context, scan),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 90,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                        color: Colors.grey.shade100,
                      ),
                      child: scan['imageBase64'] != null && scan['imageBase64'].isNotEmpty
                          ? ClipRRect(
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                        child: Image.memory(base64Decode(scan['imageBase64']), fit: BoxFit.cover, height: 110, width: double.infinity),
                      )
                          : Center(child: Icon(Icons.photo, color: Colors.grey.shade400, size: 36)),
                    ),
                    if (isAdvanced)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade400]),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: const Text('AI', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (confidence > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(confidence),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Text('${confidence.toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        plantName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14, height: 1.2, color: Colors.blue.shade800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        diseaseName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          height: 1.2,
                          color: diseaseName.toLowerCase() == 'healthy' ? Colors.green.shade700 : Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isAdvanced && scan['analysisSource'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 10, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  scan['analysisSource']?.toString() ?? 'Gemini',
                                  style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return const Color(0xFF10B981);
    if (confidence >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.auto_awesome, size: 40, color: Colors.blue.shade400),
            ),
            const SizedBox(height: 12),
            Text('No Advanced Scans', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Try advanced scanning', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  void _openAdvancedScan(BuildContext context, Map<String, dynamic> scan) {
    try {
      final plantName = scan['plantName']?.toString() ?? scan['plant_name']?.toString() ?? 'Unknown Plant';
      final diseaseName = scan['diagnosis']?.toString() ?? scan['diseaseName']?.toString() ?? scan['disease_name']?.toString() ?? 'Healthy';
      final confidence = scan['confidence']?.toString() ?? scan['accuracy']?.toString() ?? '0';
      final severity = scan['severity']?.toString() ?? scan['disease_severity']?.toString() ?? 'Medium';

      List<String> symptoms = [];
      if (scan['symptoms'] is List) {
        symptoms = List<String>.from(scan['symptoms']);
      } else if (scan['symptoms'] is String && (scan['symptoms'] as String).isNotEmpty) {
        symptoms = (scan['symptoms'] as String).split(', ').where((s) => s.isNotEmpty).toList();
      }

      List<String> remediation = _convertTreatmentToList(scan['treatment']);
      if (remediation.isEmpty) remediation = _convertTreatmentToList(scan['remediation']);

      List<String> precautions = [];
      if (scan['precautions'] is List) {
        precautions = List<String>.from(scan['precautions']);
      } else if (scan['precautions'] is String && (scan['precautions'] as String).isNotEmpty) {
        precautions = (scan['precautions'] as String).split(', ').where((s) => s.isNotEmpty).toList();
      }

      Map<String, dynamic>? advancedInnerData;
      if (scan['advancedData'] != null) {
        try {
          if (scan['advancedData'] is String) {
            final decoded = jsonDecode(scan['advancedData'] as String);
            if (decoded is Map<String, dynamic>) advancedInnerData = decoded;
          } else if (scan['advancedData'] is Map<String, dynamic>) {
            advancedInnerData = scan['advancedData'] as Map<String, dynamic>;
          }
        } catch (e) {
          debugPrint('❌ Error parsing advancedData: $e');
        }
      }

      final analysisResult = {
        'source': scan['analysisSource']?.toString() ?? 'Gemini',
        'data': {
          'plant': plantName,
          'disease': diseaseName,
          'confidence': confidence,
          'severity': severity,
          'symptoms': symptoms,
          'remediation': remediation,
          'precautions': precautions,
          'additionalInfo': scan['description']?.toString() ?? scan['additional_info']?.toString() ?? '',
          'scientificName': scan['scientificName']?.toString() ?? scan['scientific_name']?.toString() ?? '',
          'cause': scan['cause']?.toString() ?? '',
          'prevention': scan['prevention']?.toString() ?? '',
          if (advancedInnerData != null) ...advancedInnerData,
        },
        'success': true,
        'hasDiseaseInfo': diseaseName.toLowerCase() != 'healthy',
        'scanId': scan['id'],
      };

      final originalScanData = {
        'imagePath': scan['imagePath'],
        'imageUrl': scan['imageUrl'],
        'imageBase64': scan['imageBase64'],
        'isFromHistory': true,
        'skipSave': true,
        'alreadySaved': true,
        'id': scan['id'],
      };

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdvancedResultsScreen(analysisResult: analysisResult, originalScanData: originalScanData)),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error opening advanced scan: $e');
      debugPrint('Stack trace: $stackTrace');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Could not load scan details. Please try again.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    }
  }

  List<String> _convertTreatmentToList(dynamic treatment) {
    if (treatment == null) return [];
    if (treatment is List) return treatment.map((item) => item.toString()).where((s) => s.isNotEmpty).toList();
    if (treatment is String) {
      return treatment.replaceAll(RegExp(r'\s*[•\-]\s*'), '. ').split(RegExp(r'[.;]\s+')).where((s) => s.trim().isNotEmpty).map((s) => s.trim() + (s.trim().endsWith('.') ? '' : '.')).toList();
    }
    return [treatment.toString()];
  }
}