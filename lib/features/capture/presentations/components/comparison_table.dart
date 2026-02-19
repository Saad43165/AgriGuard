import 'package:flutter/material.dart';
import '../../../../core/services/translation_service.dart';

class ComparisonTable extends StatelessWidget {
  const ComparisonTable({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final translation = TranslationService();

    return AnimatedBuilder(
      animation: translation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.06),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, translation, isDark),
                const SizedBox(height: 14),
                _buildMethodHeaders(context, translation),
                const SizedBox(height: 12),
                ..._buildComparisonRows(context, translation, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, TranslationService translation, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.compare_arrows_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                translation.get('comparison_title'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                translation.get('comparison_subtitle'),
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMethodHeaders(BuildContext context, TranslationService translation) {
    return Row(
      children: [
        const SizedBox(width: 70),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Icon(Icons.phone_android_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(height: 3),
                Text(
                  translation.get('comparison_ondevice'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_rounded, color: Colors.white, size: 14),
                const SizedBox(height: 3),
                Text(
                  translation.get('comparison_cloudai'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildComparisonRows(
      BuildContext context, TranslationService translation, bool isDark) {
    final rows = [
      {
        'icon': Icons.wifi_off_rounded,
        'feature': translation.get('comparison_internet'),
        'onDevice': translation.get('comparison_not_required'),
        'onDevicePositive': true,
        'cloudAI': translation.get('comparison_required'),
        'cloudAIPositive': false,
      },
      {
        'icon': Icons.flash_on_rounded,
        'feature': translation.get('comparison_speed'),
        'onDevice': translation.get('comparison_instant'),
        'onDevicePositive': true,
        'cloudAI': '10-30s',
        'cloudAIPositive': false,
      },
      {
        'icon': Icons.eco_rounded,
        'feature': translation.get('comparison_database'),
        'onDevice': '12 ${translation.get('comparison_species')}',
        'onDevicePositive': false,
        'cloudAI': '50,000+',
        'cloudAIPositive': true,
      },
      {
        'icon': Icons.lock_rounded,
        'feature': translation.get('comparison_privacy'),
        'onDevice': translation.get('comparison_private'),
        'onDevicePositive': true,
        'cloudAI': translation.get('comparison_cloud_based'),
        'cloudAIPositive': false,
      },
      {
        'icon': Icons.star_rounded,
        'feature': translation.get('comparison_bestfor'),
        'onDevice': translation.get('comparison_quick'),
        'onDevicePositive': null,
        'cloudAI': translation.get('comparison_deep'),
        'cloudAIPositive': null,
      },
    ];

    return rows.map((row) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildComparisonRow(
          context,
          icon: row['icon'] as IconData,
          feature: row['feature'] as String,
          onDevice: row['onDevice'] as String,
          onDevicePositive: row['onDevicePositive'] as bool?,
          cloudAI: row['cloudAI'] as String,
          cloudAIPositive: row['cloudAIPositive'] as bool?,
          isDark: isDark,
        ),
      );
    }).toList();
  }

  Widget _buildComparisonRow(
      BuildContext context, {
        required IconData icon,
        required String feature,
        required String onDevice,
        required bool? onDevicePositive,
        required String cloudAI,
        required bool? cloudAIPositive,
        required bool isDark,
      }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildValueChip(
              value: onDevice,
              isPositive: onDevicePositive,
              baseColor: const Color(0xFF00B4DB),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildValueChip(
              value: cloudAI,
              isPositive: cloudAIPositive,
              baseColor: const Color(0xFF6A11CB),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueChip({
    required String value,
    required bool? isPositive,
    required Color baseColor,
    required bool isDark,
  }) {
    Color bgColor;
    Color textColor;
    IconData? icon;

    if (isPositive == null) {
      bgColor = baseColor.withOpacity(isDark ? 0.2 : 0.12);
      textColor = baseColor;
    } else if (isPositive) {
      bgColor = const Color(0xFF10B981).withOpacity(isDark ? 0.25 : 0.15);
      textColor = const Color(0xFF10B981);
      icon = Icons.check_circle_rounded;
    } else {
      bgColor = const Color(0xFFFF9800).withOpacity(isDark ? 0.25 : 0.15);
      textColor = const Color(0xFFFF9800);
      icon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 10, color: textColor),
          if (icon != null) const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}