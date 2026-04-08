// lib/features/support/screens/help_and_support_screen.dart
import 'package:agriguard_fyp/features/HelpSupport/presentation/widgets/contact_form_card.dart';
import 'package:agriguard_fyp/features/HelpSupport/presentation/widgets/contact_info_card.dart';
import 'package:agriguard_fyp/features/HelpSupport/presentation/widgets/faq_card.dart';
import 'package:agriguard_fyp/features/HelpSupport/presentation/widgets/faq_page.dart';
import 'package:agriguard_fyp/features/HelpSupport/presentation/widgets/help_quick_action_grid.dart';
import 'package:agriguard_fyp/features/HelpSupport/presentation/widgets/help_visual_guides.dart';
import 'package:agriguard_fyp/features/HelpSupport/presentation/widgets/support_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/constants/app_routes.dart';

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
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? const Color(0xFF0F0F23) : const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: translation.get('help_support'),
        topPadding: 20.0,
        onBackPressed: _handleBackPressed,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              const Color(0xFF0F0F23),
              const Color(0xFF16213E),
              const Color(0xFF1A1A2E),
              const Color(0xFF0F0F23),
            ]
                : [
              const Color(0xFFF5F7FA),
              const Color(0xFFE8EDF2),
              const Color(0xFFF0F4F8),
              const Color(0xFFF5F7FA),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
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

class _HeroCard extends StatelessWidget {
  final bool isDark;
  const _HeroCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = Provider.of<TranslationService>(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.10)),
        color: theme.colorScheme.surface.withOpacity(isDark ? 0.55 : 0.90),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: isDark ? 0.20 : 0.16,
                child: Image.asset(
                  'assets/images/grape.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withOpacity(isDark ? 0.28 : 0.16),
                      theme.colorScheme.secondary.withOpacity(isDark ? 0.18 : 0.10),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.get('help_support'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Guides, FAQs, and support — made simple for everyone.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.80),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Pill(
                              icon: Icons.photo_camera_rounded,
                              label: 'Photo tips',
                            ),
                            _Pill(
                              icon: Icons.analytics_rounded,
                              label: 'Result meaning',
                            ),
                            _Pill(
                              icon: Icons.bug_report_rounded,
                              label: 'Troubleshooting',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surface.withOpacity(isDark ? 0.65 : 0.90),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface.withOpacity(0.80),
            ),
          ),
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
            color: theme.colorScheme.surface.withOpacity(isDark ? 0.65 : 0.90),
            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: theme.colorScheme.primary.withOpacity(0.12),
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
                        color: theme.colorScheme.onSurface.withOpacity(0.70),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.35)),
            ],
          ),
        ),
      ),
    );
  }
}