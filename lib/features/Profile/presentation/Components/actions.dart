import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ← ADD THIS IMPORT
import '../../../../../core/constants/app_measurements.dart';
import '../../../../../core/constants/app_routes.dart';
import '../../utils/profile_image_manager.dart';
import 'logout_confirmation_dialog_content.dart';

class ProfileActions extends StatelessWidget {
  final EdgeInsets padding;

  const ProfileActions({
    super.key,
    required this.padding,
  });

  // ← ADD THIS LOGOUT METHOD
  Future<void> _logout(BuildContext context) async {
    try {
      // Clear any pending images
      ProfileImageManager.clearPendingImage();

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Navigate to login screen and clear ALL routes
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
              (route) => false, // This clears ALL routes from stack
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'icon': Icons.history_rounded,
        'title': 'Scan History',
        'subtitle': 'View your past scans',
        'gradient': [
          Theme.of(context).colorScheme.primary.withOpacity(0.15),
          Theme.of(context).colorScheme.primary.withOpacity(0.08),
        ],
        'iconColor': Theme.of(context).colorScheme.primary,
        'onTap': () => Navigator.pushNamed(context, AppRoutes.history),
      },
      {
        'icon': Icons.help_outline_rounded,
        'title': 'Help & Support',
        'subtitle': 'Get assistance',
        'gradient': [
          Theme.of(context).colorScheme.secondary.withOpacity(0.15),
          Theme.of(context).colorScheme.secondary.withOpacity(0.08),
        ],
        'iconColor': Theme.of(context).colorScheme.secondary,
        'onTap': () => Navigator.pushNamed(context, AppRoutes.help),
      },
      {
        'icon': Icons.settings_rounded,
        'title': 'Settings',
        'subtitle': 'Customize your app',
        'gradient': [
          Colors.purple.withOpacity(0.15),
          Colors.purple.withOpacity(0.08),
        ],
        'iconColor': Colors.purple,
        'onTap': () => Navigator.pushNamed(context, AppRoutes.settings),
      },
      {
        'icon': Icons.logout_rounded,
        'title': 'Logout',
        'subtitle': 'Sign out of your account',
        'gradient': [
          Theme.of(context).colorScheme.error.withOpacity(0.15),
          Theme.of(context).colorScheme.error.withOpacity(0.08),
        ],
        'iconColor': Theme.of(context).colorScheme.error,
        'onTap': () => showDialog(
          context: context,
          builder: (context) => LogoutConfirmationDialogContent(
            // ← FIXED: Use the proper logout method
            onConfirm: () => _logout(context),
          ),
        ),
      },
    ];

    return Container(
      // REMOVED horizontal margin - now uses full width
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context) * 1.5,
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(AppMeasurements.smallPadding),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.apps_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: AppMeasurements.getResponsiveFontSize(
                      context,
                      baseSize: 16,
                    ),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Action Items
          ...actions.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;
            final isLast = index == actions.length - 1;
            return _buildActionTile(action, context, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildActionTile(
      Map<String, dynamic> action,
      BuildContext context,
      bool isLast,
      ) {
    final iconColor = action['iconColor'] as Color;
    final gradient = action['gradient'] as List<Color>;

    return Semantics(
      label: 'Action: ${action['title']}',
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppMeasurements.getResponsiveSmallPadding(context),
          vertical: AppMeasurements.getResponsiveExtraSmallPadding(context) * 0.5,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(
              AppMeasurements.getResponsiveBorderRadius(context),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              action['onTap']();
            },
            child: Container(
              padding: EdgeInsets.all(
                AppMeasurements.getResponsiveSmallPadding(context),
              ),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    padding: EdgeInsets.all(
                      AppMeasurements.getResponsiveSmallPadding(context),
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: iconColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      action['icon'],
                      color: iconColor,
                      size: AppMeasurements.getResponsiveIconSizeMedium(context) * 0.8,
                    ),
                  ),

                  SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action['title'],
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: AppMeasurements.getResponsiveFontSize(
                              context,
                              baseSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          action['subtitle'],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            fontSize: AppMeasurements.getResponsiveFontSize(
                              context,
                              baseSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow Icon
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: iconColor,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}