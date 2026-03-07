// lib/features/ResultScreen/presentation/components/disease_cause_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/translation_service.dart';
import 'section_header.dart';

class DiseaseCausesCard extends StatelessWidget {
  final List<dynamic> causes; // Changed from List<String> to List<dynamic>

  const DiseaseCausesCard({
    super.key,
    required this.causes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final translation = Provider.of<TranslationService>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: translation.get('disease_causes'),
          icon: Icons.science_rounded,
          subtitle: translation.get('understanding_causes'),
          iconColor: const Color(0xFF6366F1),
        ),
        const SizedBox(height: 16),
        Container(
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
                color: const Color(0xFF6366F1).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: causes.isEmpty
              ? _buildEmptyState(context, isDark, translation)
              : Column(
            children: List.generate(
              causes.length,
                  (index) => _buildCauseItem(
                context: context,
                causeData: causes[index],
                index: index,
                isLast: index == causes.length - 1,
                isDark: isDark,
                translation: translation,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, TranslationService translation) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.1),
                  const Color(0xFF6366F1).withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            translation.get('no_disease_analysis'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            translation.get('analysis_not_available'),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCauseItem({
    required BuildContext context,
    required dynamic causeData, // Can be String or Map
    required int index,
    required bool isLast,
    required bool isDark,
    required TranslationService translation,
  }) {
    // Handle both old format (String) and new format (Map with en/ur)
    String causeText;
    if (causeData is Map) {
      // New bilingual format
      causeText = translation.isUrdu
          ? (causeData['ur'] ?? causeData['en'] ?? '')
          : (causeData['en'] ?? causeData['ur'] ?? '');
    } else {
      // Old format - single string
      causeText = causeData.toString().trim();
    }

    if (causeText.isEmpty) return const SizedBox.shrink();

    final causeIcons = [
      Icons.bug_report_rounded,
      Icons.water_drop_rounded,
      Icons.wb_sunny_rounded,
      Icons.thermostat_rounded,
      Icons.eco_rounded,
    ];

    final causeIcon = causeIcons[index % causeIcons.length];

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
            width: 1.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  causeIcon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${translation.get('cause')} ${index + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6366F1),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      // Add Urdu indicator if showing Urdu
                      if (translation.isUrdu && causeData is Map && causeData['ur'] != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'اردو',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    causeText,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: translation.isUrdu ? TextAlign.right : TextAlign.left,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}