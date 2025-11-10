import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_measurements.dart';
import '../models/faq_category.dart';

class FaqCategoryFilters extends StatelessWidget {
  final FaqCategory? selectedCategory;
  final Function(FaqCategory?) onCategorySelected;

  const FaqCategoryFilters({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  void _selectCategory(FaqCategory? category) {
    onCategorySelected(category);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final double itemSpacing = AppMeasurements.getResponsivePadding(context);

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: itemSpacing),
        itemCount: FaqCategory.values.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            bool isSelected = selectedCategory == null;
            return Padding(
              padding: EdgeInsets.only(right: itemSpacing / 2),
              child: FilterChip(
                selected: isSelected,
                label: Text('All'),
                avatar: Icon(
                  Icons.apps_rounded,
                  size: 18,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                onSelected: (_) => _selectCategory(null),
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }

          FaqCategory category = FaqCategory.values[index - 1];
          bool isSelected = selectedCategory == category;

          return Padding(
            padding: EdgeInsets.only(right: itemSpacing / 2),
            child: FilterChip(
              selected: isSelected,
              label: Text(category.label),
              avatar: Icon(
                category.icon,
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              onSelected: (_) => _selectCategory(category),
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          );
        },
      ),
    );
  }
}