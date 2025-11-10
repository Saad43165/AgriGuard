import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/widgets/glass_card.dart';
import '../models/faq_items.dart';

class FaqListItem extends StatelessWidget {
  final FaqItem faq;
  final int index;
  final Animation<double> fadeAnimation;
  final AnimationController animationController;

  const FaqListItem({
    super.key,
    required this.faq,
    required this.index,
    required this.fadeAnimation,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final double itemSpacing = AppMeasurements.getResponsivePadding(context);

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            ((index * 0.1) + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        )),
        child: GlassCard(
          borderRadius: AppMeasurements.getResponsiveBorderRadius(context),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                padding: EdgeInsets.all(itemSpacing / 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    ],
                  ),
                ),
                child: Icon(
                  faq.category.icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
                ),
              ),
              title: Text(
                faq.question,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                ),
              ),
              subtitle: Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  faq.category.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 12),
                  ),
                ),
              ),
              trailing: Icon(
                Icons.expand_more_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              childrenPadding: EdgeInsets.fromLTRB(
                itemSpacing * 3.5, 0, itemSpacing, itemSpacing,
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    faq.answer,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                      height: 1.5,
                    ),
                  ),
                ),
                if (faq.tags.isNotEmpty) ...[
                  SizedBox(height: itemSpacing),
                  Wrap(
                    spacing: itemSpacing / 2,
                    runSpacing: itemSpacing / 3,
                    children: faq.tags.map((tag) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: itemSpacing / 2,
                        vertical: itemSpacing / 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 11),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}