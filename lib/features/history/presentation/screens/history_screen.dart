import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/severity_indicator.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
        _scaleController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _refreshScans() async {
    HapticFeedback.lightImpact();
    await Future.delayed(AppDurations.mockApiDelay);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.scansRefreshed,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
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

  Future<void> _deleteScan(int index) async {
    final scan = AppMockData.recentScans[index];
    final imagePath =
        scan['imageUrl'] as String?; // Assuming imageUrl is the file path
    if (imagePath != null) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Failed to delete image file: $e');
      }
    }

    setState(() {
      AppMockData.recentScans.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Scan deleted successfully!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
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

  Future<void> _showDeleteConfirmationDialog(int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Scan'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to delete this ResultScreen? This action cannot be undone.',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteScan(index);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 2000, // This ensures the leading widget gets proper width
        leading: Padding(
          padding: const EdgeInsets.only(left: AppMeasurements.defaultPadding),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ShaderMask(
              shaderCallback:
                  (bounds) => LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ).createShader(bounds),
              child: Text(
                'Scan History',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(
              right: AppMeasurements.defaultPadding,
            ),
            height: 50,
            width: 50,
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
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    AppIcons.back,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
        centerTitle: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                Theme.of(context).brightness == Brightness.dark
                    ? [
                      Color(0xFF0F0F23),
                      Color(0xFF16213E),
                      Color(0xFF1A1A2E),
                      Color(0xFF0F0F23),
                    ]
                    : [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surface.withOpacity(0.9),
                      Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      Theme.of(context).colorScheme.surface,
                    ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            ...List.generate(6, (index) => _buildFloatingOrb(index)),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: RefreshIndicator(
                    onRefresh: _refreshScans,
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.2),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(
                        AppMeasurements.smallPadding,
                      ),
                      child: _buildGlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(
                            AppMeasurements.defaultPadding,
                          ),
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.2),
                                            Theme.of(context)
                                                .colorScheme
                                                .secondary
                                                .withOpacity(0.2),
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        AppIcons.logo,
                                        size: AppMeasurements.iconSizeLarge,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        semanticLabel: AppSemantics.logo,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: AppMeasurements.smallPadding,
                                    ),
                                    ShaderMask(
                                      shaderCallback:
                                          (bounds) => LinearGradient(
                                            colors: [
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                            ],
                                          ).createShader(bounds),
                                      child: Text(
                                        AppStrings.recentScans,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: AppMeasurements.extraSmallPadding,
                                    ),
                                    Text(
                                      AppMetadata.appTagline,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                        fontSize: 18,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: AppMeasurements.defaultPadding,
                                ),
                                AppMockData.recentScans.isEmpty
                                    ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 32,
                                        ),
                                        child: Text(
                                          AppStrings.noScansAvailable,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                    )
                                    : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: AppMockData.recentScans.length,
                                      itemBuilder: (context, index) {
                                        final scan =
                                            AppMockData.recentScans[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom:
                                                AppMeasurements.smallPadding,
                                          ),
                                          child: _buildGlassCard(
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () {
                                                  HapticFeedback.lightImpact();
                                                  Navigator.pushNamed(
                                                    context,
                                                    AppRoutes.results,
                                                    arguments: scan,
                                                  );
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    AppMeasurements
                                                        .defaultPadding,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              AppMeasurements
                                                                  .borderRadius,
                                                            ),
                                                        child:
                                                            scan['imageUrl'] !=
                                                                    null
                                                                ? Image.file(
                                                                  File(
                                                                    scan['imageUrl']
                                                                        as String,
                                                                  ),
                                                                  width: 50,
                                                                  height: 50,
                                                                  fit:
                                                                      BoxFit
                                                                          .cover,
                                                                  errorBuilder:
                                                                      (
                                                                        context,
                                                                        error,
                                                                        stackTrace,
                                                                      ) => Container(
                                                                        width:
                                                                            50,
                                                                        height:
                                                                            50,
                                                                        decoration: BoxDecoration(
                                                                          color:
                                                                              Theme.of(
                                                                                context,
                                                                              ).colorScheme.surface,
                                                                          borderRadius: BorderRadius.circular(
                                                                            AppMeasurements.borderRadius,
                                                                          ),
                                                                        ),
                                                                        child: Icon(
                                                                          AppIcons
                                                                              .imageError,
                                                                          color: Theme.of(
                                                                            context,
                                                                          ).colorScheme.onSurface.withOpacity(
                                                                            0.7,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                )
                                                                : Container(
                                                                  width: 50,
                                                                  height: 50,
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        Theme.of(
                                                                          context,
                                                                        ).colorScheme.surface,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          AppMeasurements
                                                                              .borderRadius,
                                                                        ),
                                                                  ),
                                                                  child: Icon(
                                                                    AppIcons
                                                                        .imageError,
                                                                    color: Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .onSurface
                                                                        .withOpacity(
                                                                          0.7,
                                                                        ),
                                                                  ),
                                                                ),
                                                      ),
                                                      const SizedBox(
                                                        width:
                                                            AppMeasurements
                                                                .defaultPadding,
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              scan['result'],
                                                              style: Theme.of(
                                                                context,
                                                              ).textTheme.bodyLarge?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color:
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .onSurface,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height:
                                                                  AppMeasurements
                                                                      .extraSmallPadding,
                                                            ),
                                                            Text(
                                                              scan['timestamp'],
                                                              style: Theme.of(
                                                                context,
                                                              ).textTheme.bodySmall?.copyWith(
                                                                color: Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .onSurface
                                                                    .withOpacity(
                                                                      0.7,
                                                                    ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height:
                                                                  AppMeasurements
                                                                      .extraSmallPadding,
                                                            ),
                                                            SeverityIndicator(
                                                              severity:
                                                                  scan['severity'],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.delete_rounded,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .error,
                                                        ),
                                                        onPressed:
                                                            () =>
                                                                _showDeleteConfirmationDialog(
                                                                  index,
                                                                ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingOrb(int index) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Positioned(
          top: (index * 150.0) % MediaQuery.of(context).size.height,
          left: (index * 100.0) % MediaQuery.of(context).size.width,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 80 + (index * 20.0),
              height: 80 + (index * 20.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }
}
