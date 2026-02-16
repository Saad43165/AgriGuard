import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../../core/constants/app_measurements.dart';

class FirstTimeUserGuide extends StatelessWidget {
  const FirstTimeUserGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            const Color(0xFF1E1E2E),
            const Color(0xFF16213E),
          ]
              : [
            Colors.white,
            const Color(0xFFF8F9FF),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Start Guide',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: AppMeasurements.getResponsiveFontSize(
                                context,
                                baseSize: 17,
                              ),
                            ),
                          ),
                          Text(
                            'Get started in 3 easy steps',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Steps
                _ModernGuideStep(
                  number: '1',
                  icon: Icons.camera_alt_rounded,
                  title: 'Scan Your Plant',
                  description: 'Capture a clear photo',
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00B4DB),
                      const Color(0xFF0083B0),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _ModernGuideStep(
                  number: '2',
                  icon: Icons.analytics_rounded,
                  title: 'AI Diagnosis',
                  description: 'Get instant analysis',
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6A11CB),
                      const Color(0xFF2575FC),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _ModernGuideStep(
                  number: '3',
                  icon: Icons.medical_services_rounded,
                  title: 'View Treatment',
                  description: 'Follow care instructions',
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981),
                      const Color(0xFF059669),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernGuideStep extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;

  const _ModernGuideStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          // Number Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradient.colors.first.withOpacity(0.15),
                  gradient.colors.last.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: gradient.colors.first,
            ),
          ),

          const SizedBox(width: 12),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: AppMeasurements.getResponsiveFontSize(
                      context,
                      baseSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Arrow Icon
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}