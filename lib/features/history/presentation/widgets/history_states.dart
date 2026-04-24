// history_states.dart
//
// Contains shared state widgets for the history screen:
//   - HistoryLoadingState   (spinner shown while fetching scans)
//   - HistoryErrorState     (retry UI shown on fetch failure)
//   - HistoryNoResultsState (shown when search / filter returns nothing)
//
// Note: HistoryLoadingDialog was removed from this file.
// It is now a private _LoadingDialog class inside history_screen.dart,
// as it was only ever used there and had no value as a separate widget.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/services/translation_service.dart';
import '../../../../../core/widgets/app_themes.dart';

class HistoryLoadingState extends StatelessWidget {
  const HistoryLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<TranslationService>(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            t.isUrdu
                ? 'آپ کے اسکینز لوڈ ہو رہے ہیں...'
                : 'Loading your scans...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const HistoryErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<TranslationService>(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .error
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 64, color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 24),
            Text(
              t.isUrdu ? 'اسکینز لوڈ کرنے میں ناکامی' : 'Failed to load scans',
              style:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              t.isUrdu
                  ? 'براہ کرم اپنا کنکشن چیک کریں اور دوبارہ کوشش کریں'
                  : 'Please check your connection and try again',
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                t.isUrdu ? 'دوبارہ کوشش کریں' : 'Try Again',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryNoResultsState extends StatelessWidget {
  final VoidCallback onClearFilters;
  const HistoryNoResultsState({super.key, required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              t.isUrdu ? 'کوئی نتیجہ نہیں ملا' : 'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkOnSurface
                    : AppColors.lightOnSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.isUrdu
                  ? 'اپنی تلاش یا فلٹر تبدیل کریں'
                  : 'Try adjusting your search or filter',
              style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkCaption
                      : AppColors.lightCaption),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: Text(t.isUrdu ? 'فلٹر صاف کریں' : 'Clear filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side:
                const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}