import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/glass_card.dart';
import 'logout_confirmation_dialog_content.dart';

class ProfileActions extends StatelessWidget {
  final EdgeInsets padding;

  const ProfileActions({
    super.key,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'icon': Icons.history_rounded,
        'title': 'Scan History',
        'onTap': () => Navigator.pushNamed(context, AppRoutes.history),
      },
      {
        'icon': Icons.help_outline_rounded,
        'title': 'Help & Support',
        'onTap': () => Navigator.pushNamed(context, AppRoutes.help),
      },
      {
        'icon': Icons.settings_rounded,
        'title': 'Settings',
        'onTap': () => Navigator.pushNamed(context, AppRoutes.settings),
      },
      {
        'icon': Icons.logout_rounded,
        'title': 'Logout',
        'color': Theme.of(context).colorScheme.error,
        'onTap': () => showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: LogoutConfirmationDialogContent(
              onConfirm: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
            ),
          ),
        ),
      },
    ];

    return GlassCard(
      child: Column(
        children: actions.map((action) => _buildActionTile(action, context)).toList(),
      ),
    );
  }

  Widget _buildActionTile(Map<String, dynamic> action, BuildContext context) {
    final isLast = action['title'] == 'Logout';
    final color = action['color'] as Color? ?? Theme.of(context).colorScheme.primary;
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);

    return Semantics(
      label: 'Action: ${action['title']}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            action['onTap']();
          },
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(smallPadding),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                  ),
                  child: Icon(
                    action['icon'],
                    color: color,
                    size: AppMeasurements.getResponsiveIconSizeSmall(context),
                  ),
                ),
                SizedBox(width: smallPadding),
                Expanded(
                  child: Text(
                    action['title'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color.withOpacity(0.5),
                  size: AppMeasurements.getResponsiveIconSizeSmall(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}