// lib/features/home/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _recentScans = [];
  bool _isFirstTimeUser = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('newScan') && !(_recentScans.contains(args['newScan']))) {
      setState(() {
        _recentScans.insert(0, args['newScan'] as Map<String, dynamic>);
        _isFirstTimeUser = false; // User is no longer new after first scan
      });
    }
  }

  Future<void> _refreshScans() async {
    setState(() => _isFirstTimeUser = false);
    await Future.delayed(AppDurations.mockApiDelay);
    if (!mounted) return;

    setState(() {
      _recentScans.addAll([
        {
          'id': '1',
          'imageUrl': 'assets/images/scan_1.jpg',
          'result': 'Healthy',
          'timestamp': 'Today, 10:30 AM',
          'severity': 'None',
        },
        {
          'id': '2',
          'imageUrl': 'assets/images/scan_2.jpg',
          'result': 'Powdery Mildew',
          'timestamp': 'Yesterday, 3:15 PM',
          'severity': 'Medium',
        },
      ]);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.scansRefreshed,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String fullName = args?['fullName'] ?? AppMetadata.appName;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppMetadata.appName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh),
            onPressed: _refreshScans,
            tooltip: AppStrings.refreshScans,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshScans,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWelcomeSection(fullName),
              const SizedBox(height: AppMeasurements.defaultPadding),
              _buildScanButton(),
              const SizedBox(height: AppMeasurements.defaultPadding),
              _buildScanContentSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 0),
    );
  }

  Widget _buildWelcomeSection(String fullName) {
    return Card(
      elevation: AppMeasurements.cardElevation,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
        child: Column(
          children: [
            Icon(
              AppIcons.logo,
              size: AppMeasurements.iconSizeLarge,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: AppMeasurements.smallPadding),
            Text(
              '${AppStrings.welcome}, $fullName!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppMeasurements.extraSmallPadding),
            Text(
              _isFirstTimeUser
                  ? AppStrings.getStartedScan
                  : AppStrings.cropHealthInsights,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return ElevatedButton.icon(
      onPressed: () => Navigator.pushNamed(context, AppRoutes.scan),
      icon: const Icon(AppIcons.scan),
      label: Text(AppStrings.scanPlant),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppMeasurements.smallPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
        ),
      ),
    );
  }

  Widget _buildScanContentSection() {
    if (_isFirstTimeUser) {
      return _buildFirstTimeUserGuide();
    }
    if (_recentScans.isEmpty) {
      return _buildEmptyScansState();
    }
    return _buildRecentScansSection();
  }

  Widget _buildFirstTimeUserGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.howToGetStarted,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppMeasurements.smallPadding),
        _buildGuideStep(
          icon: AppIcons.scan,
          title: '${AppStrings.step} 1. ${AppStrings.scanYourPlant}',
          description: AppStrings.captureClearLeafPhoto,
        ),
        _buildGuideStep(
          icon: Icons.analytics,
          title: '${AppStrings.step} 2. ${AppStrings.getDiagnosis}',
          description: AppStrings.aiAnalyzesSymptoms,
        ),
        _buildGuideStep(
          icon: Icons.medical_services,
          title: '${AppStrings.step} 3. ${AppStrings.viewRecommendations}',
          description: AppStrings.tailoredTreatmentAdvice,
        ),
      ],
    );
  }

  Widget _buildGuideStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppMeasurements.smallPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppMeasurements.smallPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: AppMeasurements.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScansState() {
    return Column(
      children: [
        Icon(
          Icons.search_off,
          size: AppMeasurements.iconSizeLarge,
          color: Theme.of(context).disabledColor,
        ),
        const SizedBox(height: AppMeasurements.smallPadding),
        Text(
          AppStrings.noScansYet,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppMeasurements.extraSmallPadding),
        Text(
          AppStrings.scanFirstPlant,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentScansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.recentScans,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
              child: Text(AppStrings.viewAll),
            ),
          ],
        ),
        const SizedBox(height: AppMeasurements.smallPadding),
        SizedBox(
          height: AppMeasurements.scanCardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentScans.length,
            itemBuilder: (context, index) {
              final scan = _recentScans[index];
              return Container(
                width: AppMeasurements.scanCardWidth,
                margin: const EdgeInsets.only(right: AppMeasurements.smallPadding),
                child: Card(
                  elevation: AppMeasurements.cardElevation,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.results,
                      arguments: scan,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppMeasurements.smallPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                              child: Image.asset(
                                scan['imageUrl'],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Icon(
                                    AppIcons.imageError,
                                    size: AppMeasurements.iconSizeMedium,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppMeasurements.extraSmallPadding),
                          Text(
                            scan['result'],
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            scan['timestamp'],
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}