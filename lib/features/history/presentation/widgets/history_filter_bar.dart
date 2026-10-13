import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_fyp/core/services/translation_service.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';

class HistorySearchBar extends StatelessWidget {
  final bool isDark;
  final String searchQuery;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const HistorySearchBar({
    super.key,
    required this.isDark,
    required this.searchQuery,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<TranslationService>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.5,
          ),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: TextStyle(
            color:
            isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: t.get('ui_search_by_plant_or_disease'),
            hintStyle: TextStyle(
              color: isDark
                  ? AppColors.darkCaption
                  : AppColors.lightCaption,
              fontSize: 14,
            ),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.primary, size: 20),
            suffixIcon: searchQuery.isNotEmpty
                ? GestureDetector(
              onTap: () => onChanged(''),
              child: Icon(
                Icons.close_rounded,
                color: isDark
                    ? AppColors.darkCaption
                    : AppColors.lightCaption,
                size: 18,
              ),
            )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }
}

class HistoryFilterChips extends StatelessWidget {
  final bool isDark;
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;

  const HistoryFilterChips({
    super.key,
    required this.isDark,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<TranslationService>(context);
    final filters = [
      ('all', t.get('ui_all')),
      ('healthy', t.get('ui_healthy')),
      ('diseased', t.get('ui_diseased')),
      ('high', t.get('ui_high_severity')),
    ];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters.map((f) {
          final isSelected = activeFilter == f.$1;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onFilterChanged(f.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                      ? AppColors.darkCard
                      : AppColors.lightCard),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                        ? AppColors.darkOnSurface
                        : AppColors.lightOnSurface),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}