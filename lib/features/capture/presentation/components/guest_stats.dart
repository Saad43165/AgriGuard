import 'package:flutter/material.dart';
import '../../../../core/services/translation_service.dart';

class GuestStats extends StatelessWidget {
  final int remainingScans;

  const GuestStats({super.key, required this.remainingScans});

  @override
  Widget build(BuildContext context) {
    final translation = TranslationService();

    return AnimatedBuilder(
      animation: translation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.withValues(alpha: 0.15),
                Colors.deepOrange.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_circle_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translation.get('guest_stats_title'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.orange,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$remainingScans ${translation.get('guest_stats_scans')}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      translation.get('guest_stats_signup'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.orange,
                size: 18,
              ),
            ],
          ),
        );
      },
    );
  }
}