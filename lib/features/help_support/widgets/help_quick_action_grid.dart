import 'package:agriguard_fyp/core/widgets/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_fyp/core/services/translation_service.dart';

class HelpQuickActionGrid extends StatelessWidget {
  final VoidCallback onOpenFaqs;
  final VoidCallback onScrollToContact;

  const HelpQuickActionGrid({
    super.key,
    required this.onOpenFaqs,
    required this.onScrollToContact,
  });

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<TranslationService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final actions = <_QuickAction>[
      _QuickAction(
        title: t.get('quick_answers'),
        subtitle: t.get('find_answers'),
        icon: Icons.question_answer_rounded,
        gradient: const [AppColors.blue, Color(0xFF22C55E)],
        onTap: onOpenFaqs,
      ),
      _QuickAction(
        title: t.get('take_photo'),
        subtitle: t.get('step1_text'),
        icon: Icons.photo_camera_rounded,
        gradient: const [AppColors.warning, AppColors.error],
        onTap: () {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              content: Text(
                isDark
                    ? 'Tip: Use good light and fill the frame with the leaf.'
                    : 'Tip: Use good light and fill the frame with the leaf.',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
      _QuickAction(
        title: t.get('next_steps'),
        subtitle: t.get('recommended_actions'),
        icon: Icons.playlist_add_check_circle_rounded,
        gradient: const [AppColors.violet, Color(0xFFEC4899)],
        onTap: () {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              content: const Text('Open a scan result to see step-by-step recommendations.'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
      _QuickAction(
        title: t.get('get_in_touch'),
        subtitle: t.get('help_questions'),
        icon: Icons.support_agent_rounded,
        gradient: const [Color(0xFF06B6D4), AppColors.blue],
        onTap: onScrollToContact,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.18,
      ),
      itemBuilder: (context, index) => _QuickActionCard(action: actions[index]),
    );
  }
}

class _QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.lightImpact();
          action.onTap();
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: theme.colorScheme.surface.withValues(alpha: isDark ? 0.65 : 0.85),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(colors: action.gradient),
                  ),
                  child: Icon(action.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  action.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    action.subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.35,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w600,
                    ),
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

