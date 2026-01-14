// lib/features/ResultScreen/presentation/components/results/source_badge.dart
import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_measurements.dart';

class SourceBadge extends StatelessWidget {
  final Map<String, dynamic> result;
  final ThemeData theme;

  const SourceBadge({
    super.key,
    required this.result,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final source = result['source'] as String;
    final isRealData = result['isRealData'] as bool? ?? true;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppMeasurements.getResponsiveSmallPadding(context),
        vertical: AppMeasurements.getResponsiveSmallPadding(context) * 0.5,
      ),
      decoration: BoxDecoration(
        color: isRealData ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRealData ? Colors.green : Colors.orange,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRealData ? Icons.verified_user : Icons.sim_card_alert,
            size: 16,
            color: isRealData ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 6),
          Text(
            isRealData ? '✅ Real AI Analysis' : '⚠️ Using Demo Data',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isRealData ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}