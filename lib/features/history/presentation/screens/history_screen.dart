// lib/features/history/presentation/screens/history_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/severity_indicator.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future<void> _refreshScans() async {
    await Future.delayed(AppDurations.mockApiDelay);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.scansRefreshed,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary, // Replaced AppColors.textLight
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
        ),
        duration: AppDurations.snackBarDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Scan History'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshScans,
        color: Theme.of(context).colorScheme.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Column(
                children: [
                  Icon(
                    AppIcons.logo,
                    size: AppMeasurements.iconSizeLarge,
                    color: Theme.of(context).colorScheme.primary,
                    semanticLabel: AppSemantics.logo,
                  ),
                  SizedBox(height: AppMeasurements.smallPadding),
                  Text(
                    AppStrings.recentScans,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppMeasurements.extraSmallPadding),
                  Text(
                    AppMetadata.appTagline,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: AppMeasurements.defaultPadding),

              // Scan List
              AppMockData.recentScans.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    AppStrings.noScansAvailable,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: AppMockData.recentScans.length,
                itemBuilder: (context, index) {
                  final scan = AppMockData.recentScans[index];
                  return Card(
                    elevation: AppMeasurements.cardElevation,
                    margin: const EdgeInsets.only(bottom: AppMeasurements.smallPadding),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                        child: Image.asset(
                          scan['image'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 50,
                            height: 50,
                            color: Theme.of(context).colorScheme.surface,
                            child: Icon(
                              AppIcons.imageError,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        scan['result'],
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scan['timestamp'],
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: AppMeasurements.extraSmallPadding),
                          SeverityIndicator(severity: scan['severity']),
                        ],
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.results,
                          arguments: scan,
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),

    );
  }
}