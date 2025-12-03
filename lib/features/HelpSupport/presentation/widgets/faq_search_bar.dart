import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_measurements.dart';


class FaqSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearchChanged;
  final VoidCallback onClear;

  const FaqSearchBar({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final double itemSpacing = AppMeasurements.getResponsivePadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: itemSpacing),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            size: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
          ),
          SizedBox(width: itemSpacing / 2),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onSearchChanged(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
              decoration: InputDecoration(
                hintText: 'Search FAQs...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: itemSpacing, // Add horizontal padding
                  vertical: itemSpacing,
                ),
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
              ),
              onPressed: () {
                onClear();
                HapticFeedback.lightImpact();
              },
            ),
        ],
      ),
    );
  }
}