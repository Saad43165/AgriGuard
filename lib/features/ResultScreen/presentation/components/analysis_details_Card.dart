import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'section_header.dart';
import 'detail_row.dart';

class AnalysisDetailsCard extends StatelessWidget {
  final Map<String, dynamic> scanData;

  const AnalysisDetailsCard({super.key, required this.scanData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Helper method to get disease display information
    Map<String, dynamic> getDiseaseDisplayInfo() {
      String label = 'Health Status';
      String value = 'Healthy';
      IconData icon = Icons.check_circle_rounded;
      Color color = Colors.green;

      // Check multiple sources for disease information
      String? diseaseFromModel = scanData['originalDiseaseName']?.toString() ??
          scanData['rawLabel']?.toString();

      String? processedDisease = scanData['diseaseName']?.toString() ??
          scanData['diagnosis']?.toString() ??
          scanData['disease']?.toString();

      String? rawLabel = scanData['rawLabel']?.toString();

      // Check if rawLabel contains an actual disease (not "healthy")
      if (rawLabel != null && rawLabel.contains('___')) {
        final parts = rawLabel.split('___');
        if (parts.length >= 2) {
          final diseasePart = parts[1].replaceAll('_', ' ').trim();
          if (diseasePart.toLowerCase() != 'healthy') {
            // Found actual disease in raw label
            label = 'Detected Disease';
            value = diseasePart.split(' ')
                .map((word) => word.isNotEmpty ?
            word[0].toUpperCase() + word.substring(1).toLowerCase() :
            word)
                .join(' ');
            icon = Icons.medical_services_rounded;

            // Get severity for color
            final severity = scanData['severity']?.toString() ?? 'Medium';
            color = _getDiseaseColor(severity);

            return {'label': label, 'value': value, 'icon': icon, 'color': color, 'hasDisease': true};
          }
        }
      }

      // Check if processed disease indicates actual disease (not "Healthy" variations)
      if (processedDisease != null &&
          processedDisease.isNotEmpty &&
          processedDisease.toLowerCase() != 'healthy' &&
          processedDisease.toLowerCase() != 'no disease detected' &&
          processedDisease.toLowerCase() != 'health analysis') {
        label = 'Detected Disease';
        value = processedDisease;
        icon = Icons.medical_services_rounded;

        // Get severity for color
        final severity = scanData['severity']?.toString() ?? 'Medium';
        color = _getDiseaseColor(severity);

        return {'label': label, 'value': value, 'icon': icon, 'color': color, 'hasDisease': true};
      }

      // If we get here, plant is healthy
      label = 'Health Status';
      value = 'Healthy';
      icon = Icons.check_circle_rounded;
      color = Colors.green;

      return {'label': label, 'value': value, 'icon': icon, 'color': color, 'hasDisease': false};
    }

    final displayInfo = getDiseaseDisplayInfo();
    final String? plantName = scanData['plantName']?.toString();
    final String? confidence = scanData['confidence']?.toString();
    final String? severity = scanData['severity']?.toString();
    final String? cause = scanData['cause']?.toString();
    final bool hasDisease = displayInfo['hasDisease'] as bool;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Analysis Details',
          icon: Icons.analytics_rounded,
          subtitle: 'Detailed breakdown of the diagnosis',
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surface.withOpacity(0.5)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Disease/Health Information - ALWAYS show this
                DetailRow(
                  label: displayInfo['label'] as String,
                  value: displayInfo['value'] as String,
                  icon: displayInfo['icon'] as IconData,
                  iconColor: displayInfo['color'] as Color,
                  valueColor: displayInfo['color'] as Color,
                ),
                const SizedBox(height: 16),

                // Plant Information
                if (plantName != null && plantName.isNotEmpty && plantName != 'Unknown Plant')
                  Column(
                    children: [
                      DetailRow(
                        label: 'Plant Species',
                        value: plantName,
                        icon: Icons.eco_rounded,
                        iconColor: Colors.green,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Severity Level - Only show if there's a disease and severity is not "None"
                if (hasDisease && severity != null && severity.isNotEmpty && severity.toLowerCase() != 'none')
                  Column(
                    children: [
                      DetailRow(
                        label: 'Severity Level',
                        value: severity,
                        icon: Icons.warning_rounded,
                        iconColor: _getSeverityColor(severity),
                        valueColor: _getSeverityColor(severity),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Confidence Level
                if (confidence != null && confidence.isNotEmpty)
                  Column(
                    children: [
                      DetailRow(
                        label: 'AI Confidence',
                        value: '${_formatConfidence(confidence)}%',
                        icon: Icons.analytics_rounded,
                        iconColor: _getConfidenceColor(confidence),
                        valueColor: _getConfidenceColor(confidence),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Cause Information - Only show if there's an actual disease
                if (hasDisease && cause != null && cause.isNotEmpty)
                  Column(
                    children: [
                      DetailRow(
                        label: 'Likely Cause',
                        value: cause,
                        icon: Icons.search_rounded,
                        iconColor: theme.colorScheme.secondary,
                        valueColor: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Additional note for healthy plants
                if (!hasDisease)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'No diseases detected. Plant appears to be in good health.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getDiseaseColor(String? severity) {
    if (severity == null) return Colors.orange;
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      case 'none':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getConfidenceColor(String confidence) {
    try {
      final value = double.tryParse(confidence) ?? 0;
      if (value >= 80) return Colors.green;
      if (value >= 60) return Colors.orange;
      return Colors.red;
    } catch (e) {
      return Colors.grey;
    }
  }

  String _formatConfidence(String confidence) {
    try {
      final value = double.tryParse(confidence) ?? 0;
      return value.toStringAsFixed(0);
    } catch (e) {
      return '0';
    }
  }
}