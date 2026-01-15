import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_measurements.dart';

class AppBarContent extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final double elevation;
  final double topPadding;
  final Widget? leading;

  const AppBarContent({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.elevation = 0,
    this.topPadding = 8.0,
    this.leading, Widget? trailing,
  });

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: elevation,
        centerTitle: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Custom Back Button on LEFT SIDE (only if showBackButton AND no leading provided)
            if (showBackButton && leading == null)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    ],
                  ),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (onBackPressed != null) {
                        onBackPressed!();
                      } else {
                        Navigator.maybePop(context);
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.all(padding * 0.5),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: AppMeasurements.getResponsiveIconSizeMedium(context),
                      ),
                    ),
                  ),
                ),
              )
            else if (leading != null)
              leading!
            else
              Container(width: 50), // Spacer to maintain layout

            // Title in Center with Gradient
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ).createShader(bounds),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 26),
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Actions or Empty Spacer on RIGHT SIDE
            if (actions != null && actions!.isNotEmpty)
              Row(
                children: actions!,
              )
            else
              Container(width: 50), // Spacer to maintain layout
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8.0);
}