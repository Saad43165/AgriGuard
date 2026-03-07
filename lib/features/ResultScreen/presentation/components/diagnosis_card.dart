// lib/features/ResultScreen/presentation/components/diagnosis_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/severity_indicator.dart';
import '../../../../core/services/translation_service.dart';
import '../models/diagnosis_result.dart';

class DiagnosisCard extends StatelessWidget {
  final DiagnosisResult diagnosisResult;

  const DiagnosisCard({
    super.key,
    required this.diagnosisResult,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final translation = Provider.of<TranslationService>(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant Name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translation.get('plant_name'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        translation.translatePlant(diagnosisResult.plantName),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Disease Name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: diagnosisResult.isHealthy
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    diagnosisResult.isHealthy ? Icons.check_circle : Icons.warning,
                    color: diagnosisResult.isHealthy ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translation.get('disease_detected'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        translation.translateDisease(diagnosisResult.disease),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: diagnosisResult.isHealthy
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Severity
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(diagnosisResult.severity).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.speed_rounded,
                    color: _getSeverityColor(diagnosisResult.severity),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translation.get('severity_level'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getSeverityColor(diagnosisResult.severity),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              translation.translateSeverity(diagnosisResult.severity),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${diagnosisResult.confidence}% Confidence',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (diagnosisResult.description != null && diagnosisResult.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                  ),
                ),
                child: Text(
                  diagnosisResult.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],

            if (diagnosisResult.scientificName != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.science_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      diagnosisResult.scientificName!,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
      case 'mild':
        return const Color(0xFF3B82F6);
      case 'medium':
      case 'moderate':
        return const Color(0xFFF59E0B);
      case 'high':
      case 'severe':
        return const Color(0xFFEF4444);
      case 'critical':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }
}