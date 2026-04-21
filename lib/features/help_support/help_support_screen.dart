// lib/features/help_support/help_support_screen.dart
import 'package:agriguard_fyp/features/help_support/bug_report_screen.dart';
import 'package:agriguard_fyp/features/help_support/widgets/contact_form_card.dart';
import 'package:agriguard_fyp/features/help_support/widgets/contact_info_card.dart';
import 'package:agriguard_fyp/features/help_support/widgets/faq_card.dart';
import 'package:agriguard_fyp/features/help_support/widgets/faq_page.dart';
import 'package:agriguard_fyp/features/help_support/widgets/help_quick_action_grid.dart';
import 'package:agriguard_fyp/features/help_support/widgets/help_visual_guides.dart';
import 'package:agriguard_fyp/features/help_support/widgets/support_app_bar.dart';
import 'package:agriguard_fyp/features/chatbot/chatbot_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_themes.dart';

class HelpAndSupportScreen extends StatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _contactKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleBackPressed() {
    HapticFeedback.lightImpact();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final translation = Provider.of<TranslationService>(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: CustomAppBar(
        title: translation.get('help_support'),
        onBackPressed: _handleBackPressed,
      ),
      body: Container(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _HeroCard(isDark: isDark),
                    const SizedBox(height: 16),

                    // AI Chat + Bug Report prominent buttons
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.smart_toy_rounded,
                            title: 'AI Assistant',
                            subtitle: 'Ask about diseases',
                            gradient: const [AppColors.primary, AppColors.secondary],
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen()));
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.bug_report_rounded,
                            title: 'Report Bug',
                            subtitle: 'Help us improve',
                            gradient: [AppColors.error, const Color(0xFFDC2626)],
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const BugReportScreen()));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Prevent overflow on small devices by using a single-column layout.
                        if (constraints.maxWidth < 420) {
                          return Column(
                            children: [
                              _QuickActionTile(
                                icon: Icons.question_answer_rounded,
                                title: translation.get('quick_answers'),
                                subtitle: translation.get('find_answers'),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const FaqPage()),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _QuickActionTile(
                                icon: Icons.support_agent_rounded,
                                title: translation.get('get_in_touch'),
                                subtitle: translation.get('help_questions'),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  final ctx = _contactKey.currentContext;
                                  if (ctx != null) {
                                    Scrollable.ensureVisible(
                                      ctx,
                                      duration: const Duration(milliseconds: 450),
                                      curve: Curves.easeOutCubic,
                                      alignment: 0.05,
                                    );
                                  }
                                },
                              ),
                            ],
                          );
                        }

                        return HelpQuickActionGrid(
                          onOpenFaqs: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FaqPage(),
                              ),
                            );
                          },
                          onScrollToContact: () {
                            HapticFeedback.lightImpact();
                            final ctx = _contactKey.currentContext;
                            if (ctx != null) {
                              Scrollable.ensureVisible(
                                ctx,
                                duration: const Duration(milliseconds: 450),
                                curve: Curves.easeOutCubic,
                                alignment: 0.05,
                              );
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    const HelpVisualGuides(),
                    const SizedBox(height: 18),
                    const FaqCard(),
                    const SizedBox(height: 22),
                    Container(key: _contactKey, child: const ContactInfoCard()),
                    const SizedBox(height: 16),
                    const ContactFormCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon, required this.title, required this.subtitle,
    required this.gradient, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final accentColor = gradient[0];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(height: 10),
              Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: captionColor, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final bool isDark;
  const _HeroCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<TranslationService>(context);
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.support_agent_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.get('help_support'),
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor)),
                const SizedBox(height: 4),
                Text('Guides, FAQs, and support — made simple for everyone.',
                    style: TextStyle(fontSize: 13, color: captionColor, height: 1.4)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: [
                    _Pill(icon: Icons.photo_camera_rounded, label: 'Photo tips'),
                    _Pill(icon: Icons.analytics_rounded, label: 'Result meaning'),
                    _Pill(icon: Icons.bug_report_rounded, label: 'Troubleshooting'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          )),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: theme.colorScheme.surface.withValues(alpha: isDark ? 0.65 : 0.90),
            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }
}