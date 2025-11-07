class OnboardingData {
  final String icon;
  final String title;
  final String description;

  OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
  });

  // Static list of onboarding pages data
  static List<OnboardingData> get pages => [
    OnboardingData(
      icon: '🌱',
      title: 'Protect Your Crops',
      description: 'Advanced AI-powered disease detection helps you identify crop issues early and take action before it\'s too late.',
    ),
    OnboardingData(
      icon: '📷',
      title: 'Instant Detection',
      description: 'Simply take a photo of your plant and get instant analysis with detailed information about diseases and treatments.',
    ),
    OnboardingData(
      icon: '💡',
      title: 'Expert Guidance',
      description: 'Receive personalized recommendations and treatment plans based on your crop type and detected conditions.',
    ),
    OnboardingData(
      icon: '📊',
      title: 'Track Progress',
      description: 'Monitor your crops over time, track treatments, and watch your fields thrive with data-driven insights.',
    ),
  ];
}