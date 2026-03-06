// lib/features/support/widgets/faq_category_filters.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: FaqCategory.values.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            bool isSelected = selectedCategory == null;
            return _buildChip(
              context,
              label: 'All',
              icon: Icons.grid_view_rounded,
              isSelected: isSelected,
              isDark: isDark,
              onTap: () => _selectCategory(null),
            );
          }

          FaqCategory category = FaqCategory.values[index - 1];
          bool isSelected = selectedCategory == category;

          return _buildChip(
            context,
            label: category.label,
            icon: category.icon,
            isSelected: isSelected,
            isDark: isDark,
            onTap: () => _selectCategory(category),
          );
        },
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient:
                  isSelected
                      ? LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.8),
                        ],
                      )
                      : null,
              color:
                  isSelected
                      ? null
                      : (isDark ? const Color(0xFF1E1E2E) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.2),
                width: 2,
              ),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color:
                      isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color:
                        isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
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
