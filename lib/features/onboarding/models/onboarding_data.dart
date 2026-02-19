import 'package:flutter/material.dart';

class OnboardingData {
  final IconData mainIcon;
  final List<IconData> featureIcons;
  final String title;
  final String subtitle;
  final String description;
  final List<String> features;

  OnboardingData({
    required this.mainIcon,
    required this.featureIcons,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
  });

  static List<OnboardingData> get pages => [
    OnboardingData(
      mainIcon: Icons.eco_rounded,
      featureIcons: [
        Icons.spa_rounded,
        Icons.local_florist_rounded,
        Icons.grass_rounded,
      ],
      title: 'Protect Your Crops',
      subtitle: 'AI-Powered Detection',
      description:
      'Advanced machine learning identifies crop diseases early, helping you take action before it\'s too late.',
      features: [
        'Real-time disease detection',
        'Early warning system',
        '95% accuracy rate',
      ],
    ),
    OnboardingData(
      mainIcon: Icons.camera_alt_rounded,
      featureIcons: [
        Icons.photo_camera_rounded,
        Icons.image_search_rounded,
        Icons.analytics_rounded,
      ],
      title: 'Instant Analysis',
      subtitle: 'Snap & Diagnose',
      description:
      'Simply capture a photo of your plant and receive instant AI-powered analysis with detailed insights.',
      features: [
        'Instant photo analysis',
        'Detailed diagnostics',
        'Treatment recommendations',
      ],
    ),
    OnboardingData(
      mainIcon: Icons.lightbulb_rounded,
      featureIcons: [
        Icons.stars_rounded,
        Icons.psychology_rounded,
        Icons.tips_and_updates_rounded,
      ],
      title: 'Expert Guidance',
      subtitle: 'Personalized Solutions',
      description:
      'Get tailored treatment plans and expert recommendations based on your specific crop conditions.',
      features: [
        'Custom treatment plans',
        'Expert recommendations',
        'Step-by-step guidance',
      ],
    ),
    OnboardingData(
      mainIcon: Icons.trending_up_rounded,
      featureIcons: [
        Icons.insert_chart_rounded,
        Icons.history_rounded,
        Icons.timeline_rounded,
      ],
      title: 'Track Your Success',
      subtitle: 'Data-Driven Farming',
      description:
      'Monitor crop health over time with comprehensive analytics and watch your fields thrive.',
      features: [
        'Progress tracking',
        'Historical analysis',
        'Performance insights',
      ],
    ),
  ];
}