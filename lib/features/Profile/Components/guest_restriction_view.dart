import 'package:flutter/material.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/floating_orb.dart';
import '../../auth/Login_Screen/services/guest_service.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/translation_service.dart';

class GuestRestrictionView extends StatelessWidget {
  final double maxWidth;
  final AnimationController fadeController;
  final Animation<double> scaleAnimation;
  final GuestService guestService;

  const GuestRestrictionView({
    super.key,
    required this.maxWidth,
    required this.fadeController,
    required this.scaleAnimation,
    required this.guestService,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                const Color(0xFF0A0E27),
                const Color(0xFF1A1F3A),
                const Color(0xFF0F1419),
              ]
                  : [
                const Color(0xFFF8FAFB),
                const Color(0xFFE8F5E9),
                const Color(0xFFF1F8F4),
              ],
            ),
          ),
        ),

        ...List.generate(
          8,
              (i) => FloatingOrb(
            index: i,
            maxWidth: maxWidth,
            fadeController: fadeController,
            scaleAnimation: scaleAnimation,
          ),
        ),

        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_off_rounded,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Profile Not Available',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    guestService.getRestrictionMessage('view_profile'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                            (route) => false,
                      );
                    },
                    icon: const Icon(Icons.login_rounded),
                    label: Text(t.get('sign_in_now')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                        icon: const Icon(Icons.settings_rounded),
                        label: const Text('Settings'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.help),
                        icon: const Icon(Icons.support_agent_rounded),
                        label: const Text('Help'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}