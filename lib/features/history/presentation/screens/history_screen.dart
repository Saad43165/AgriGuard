import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/severity_indicator.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
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
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF00D4AA),
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
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: const Color(0xFF00D4AA),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D4AA),
          secondary: Color(0xFF6C63FF),
          surface: Color(0xFF1A1A2E),
          background: Color(0xFF16213E),
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.only(left: AppMeasurements.defaultPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  Colors.cyan.withOpacity(0.2),
                  Colors.purple.withOpacity(0.2),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: const Padding(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    AppIcons.back,
                    color: Color(0xFF00D4AA),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)],
            ).createShader(bounds),
            child: const Text(
              'Scan History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          centerTitle: true,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F0F23),
                Color(0xFF16213E),
                Color(0xFF1A1A2E),
                Color(0xFF0F0F23),
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
                      color: const Color(0xFF00D4AA),
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
                        child: _buildGlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
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
                                              const Color(0xFF00D4AA).withOpacity(0.2),
                                              const Color(0xFF6C63FF).withOpacity(0.2),
                                            ],
                                          ),
                                        ),
                                        child: Icon(
                                          AppIcons.logo,
                                          size: AppMeasurements.iconSizeLarge,
                                          color: const Color(0xFF00D4AA),
                                          semanticLabel: AppSemantics.logo,
                                        ),
                                      ),
                                      const SizedBox(height: AppMeasurements.smallPadding),
                                      ShaderMask(
                                        shaderCallback: (bounds) => const LinearGradient(
                                          colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)],
                                        ).createShader(bounds),
                                        child: Text(
                                          AppStrings.recentScans,
                                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: AppMeasurements.extraSmallPadding),
                                      Text(
                                        AppMetadata.appTagline,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 18,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppMeasurements.defaultPadding),
                                  AppMockData.recentScans.isEmpty
                                      ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 32),
                                      child: Text(
                                        AppStrings.noScansAvailable,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  )
                                      : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: AppMockData.recentScans.length,
                                    itemBuilder: (context, index) {
                                      final scan = AppMockData.recentScans[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: AppMeasurements.smallPadding),
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
                                                padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
                                                child: Row(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                                                      child: Image.asset(
                                                        scan['image'],
                                                        width: 50,
                                                        height: 50,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) => Container(
                                                          width: 50,
                                                          height: 50,
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF1A1A2E),
                                                            borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                                                          ),
                                                          child: Icon(
                                                            AppIcons.imageError,
                                                            color: Colors.white.withOpacity(0.7),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: AppMeasurements.defaultPadding),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            scan['result'],
                                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                              fontWeight: FontWeight.w500,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                          const SizedBox(height: AppMeasurements.extraSmallPadding),
                                                          Text(
                                                            scan['timestamp'],
                                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                              color: Colors.white.withOpacity(0.7),
                                                            ),
                                                          ),
                                                          const SizedBox(height: AppMeasurements.extraSmallPadding),
                                                          SeverityIndicator(severity: scan['severity']),
                                                        ],
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.chevron_right_rounded,
                                                      color: Colors.white.withOpacity(0.5),
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
                    Colors.cyan.withOpacity(0.1),
                    Colors.purple.withOpacity(0.05),
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
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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