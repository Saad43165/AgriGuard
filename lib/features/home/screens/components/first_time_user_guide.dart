import 'package:flutter/material.dart';
import 'dart:ui';
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1E2E), const Color(0xFF16213E)]
              : [Colors.white, const Color(0xFFF8F9FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ).createShader(bounds),
                child: Text(
                  'Quick Start Guide',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tap cards to expand details',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.08),
            Theme.of(context).colorScheme.secondary.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ).createShader(bounds),
            child: const Icon(Icons.bar_chart_rounded, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: i <= _currentStep
                          ? LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      )
                          : null,
                      color: i <= _currentStep
                          ? null
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
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
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_currentStep + 1}/3',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}