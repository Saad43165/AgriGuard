import 'package:flutter/material.dart';
import '../../../../core/widgets/app_themes.dart';
import 'guide_step.dart';

class FirstTimeUserGuide extends StatefulWidget {
  const FirstTimeUserGuide({super.key});

  @override
  State<FirstTimeUserGuide> createState() => _FirstTimeUserGuideState();
}

class _FirstTimeUserGuideState extends State<FirstTimeUserGuide>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeIn),
    );
    _headerAnimController.forward();
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                FadeTransition(
                  opacity: _headerFadeAnimation,
                  child: _buildHeader(context),
                ),

                const SizedBox(height: 20),

                // Guide Steps - REMOVED individual colors
                GuideStepCompact(
                  stepNumber: 1,
                  icon: Icons.camera_alt_rounded,
                  title: 'Scan Plant',
                  titleUrdu: 'اسکین کریں',
                  description: 'Take a clear photo',
                  descriptionUrdu: 'واضح تصویر لیں',
                  isCompleted: _currentStep > 0,
                  isActive: _currentStep == 0,
                  showConnector: true,
                  detailPoints: [
                    'Good lighting required',
                    'Hold phone steady',
                    'Focus on affected area',
                  ],
                  detailPointsUrdu: [
                    'اچھی روشنی درکار',
                    'فون مستحکم رکھیں',
                    'متاثرہ علاقہ',
                  ],
                  onTap: () => setState(() => _currentStep = 0),
                ),

                GuideStepCompact(
                  stepNumber: 2,
                  icon: Icons.auto_awesome_rounded,
                  title: 'AI Analysis',
                  titleUrdu: 'AI تجزیہ',
                  description: 'Instant diagnosis',
                  descriptionUrdu: 'فوری تشخیص',
                  isCompleted: _currentStep > 1,
                  isActive: _currentStep == 1,
                  showConnector: true,
                  detailPoints: [
                    'Quick on-device scan',
                    'Advanced AI option',
                    'Takes 2-3 seconds',
                  ],
                  detailPointsUrdu: [
                    'تیز آن ڈیوائس',
                    'ایڈوانسڈ AI',
                    '2-3 سیکنڈ',
                  ],
                  onTap: () => setState(() => _currentStep = 1),
                ),

                GuideStepCompact(
                  stepNumber: 3,
                  icon: Icons.medication_rounded,
                  title: 'View Treatment',
                  titleUrdu: 'علاج دیکھیں',
                  description: 'Get care tips',
                  descriptionUrdu: 'دیکھ بھال کی تجاویز',
                  isCompleted: _currentStep > 2,
                  isActive: _currentStep == 2,
                  showConnector: false,
                  detailPoints: [
                    'Disease details',
                    'Treatment steps',
                    'Download PDF',
                  ],
                  detailPointsUrdu: [
                    'بیماری کی تفصیلات',
                    'علاج کے مراحل',
                    'PDF ڈاؤن لوڈ',
                  ],
                  onTap: () => setState(() => _currentStep = 2),
                ),

                const SizedBox(height: 16),

                // Progress
                _buildProgress(),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.rocket_launch_rounded, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quick Start Guide',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tap cards to expand details',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    height: 5,
                    decoration: BoxDecoration(
                      color: i <= _currentStep ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_currentStep + 1}/3',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    height: 5,
                    decoration: BoxDecoration(
                      color: i <= _currentStep ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_currentStep + 1}/3',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}