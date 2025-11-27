import 'package:agriguard_fyp/features/history/presentation/widgets/history_appbar.dart';
import 'package:agriguard_fyp/features/history/presentation/widgets/history_empty_state.dart';
import 'package:agriguard_fyp/features/history/presentation/widgets/history_list_view.dart';
import 'package:agriguard_fyp/features/history/presentation/widgets/history_theme_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_measurements.dart'; // ← ADD THIS IMPORT
import '../../history/presentation/widgets/floating_orb.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  List<Map<String, dynamic>> _userScans = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserScans();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
        _scaleController.forward();
      }
    });
  }

  Future<void> _loadUserScans() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scans')
          .orderBy('timestamp', descending: true)
          .get();

      final List<Map<String, dynamic>> scans = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final scanData = data['scanData'] as Map<String, dynamic>?;
        final Map<String, dynamic> resolved = scanData ?? data;

        if (resolved['diagnosis'] == null) continue;

        String confidenceStr = '0';
        final conf = resolved['confidence'];
        if (conf is num) {
          confidenceStr = conf.toStringAsFixed(0);
        } else if (conf is String) {
          final numValue = num.tryParse(conf);
          confidenceStr = numValue != null ? numValue.toStringAsFixed(0) : '0';
        }

        final originalTimestamp = data['timestamp'];

        scans.add({
          'id': doc.id,
          'diagnosis': resolved['diagnosis']?.toString() ?? 'Unknown Disease',
          'severity': resolved['severity']?.toString() ?? 'Unknown',
          'confidence': confidenceStr,
          'treatment': resolved['treatment']?.toString() ?? 'No treatment',
          'imagePath': resolved['imagePath']?.toString() ?? '',
          'cropType': resolved['cropType']?.toString() ?? 'Unknown',
          'plantName': resolved['plantName']?.toString() ?? 'Unknown',
          'originalTimestamp': originalTimestamp,
        });
      }

      if (mounted) {
        setState(() {
          _userScans = scans;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _refreshScans() async {
    HapticFeedback.lightImpact();
    await _loadUserScans();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _userScans.isEmpty ? 'No scans found' : 'Refreshed',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
        ),
        duration: const Duration(seconds: 2),
        margin: EdgeInsets.all(AppMeasurements.getResponsiveSmallPadding(context)),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = AppMeasurements.getResponsivePadding(context);
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);
    final isLargeScreen = AppMeasurements.isLargeScreen(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const HistoryAppBar(title: 'Scan History'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: HistoryThemeConfig.getBackgroundGradient(isDark),
          ),
        ),
        child: Stack(
          children: [
            ...List.generate(
              4,
                  (index) => FloatingOrb(
                index: index,
                fadeController: _fadeController,
                scaleAnimation: _scaleAnimation,
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: RefreshIndicator(
                  onRefresh: _refreshScans,
                  color: Theme.of(context).colorScheme.primary,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildHeader(context),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          padding,
                          smallPadding,
                          padding,
                          padding,
                        ),
                        sliver: _buildContent(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);
    final isLargeScreen = AppMeasurements.isLargeScreen(context);

    return Container(
      margin: EdgeInsets.fromLTRB(
        padding,
        isLargeScreen ? padding * 1.5 : padding,
        padding,
        smallPadding,
      ),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context) * 1.5,
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(smallPadding),
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
              Icons.history_rounded,
              size: AppMeasurements.getResponsiveIconSizeLarge(context) * 0.7,
              color: Theme.of(context).brightness == Brightness.light
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.9)
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: smallPadding),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ).createShader(bounds),
            child: Text(
              'Scan History',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: AppMeasurements.getResponsiveFontSize(
                  context,
                  baseSize: isLargeScreen ? 28 : 24,
                ),
              ),
            ),
          ),
          SizedBox(height: smallPadding / 2),
          Text(
            'Your crop health scans',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: AppMeasurements.getResponsiveFontSize(
                context,
                baseSize: isLargeScreen ? 16 : 14,
              ),
            ),
          ),
          if (_userScans.isNotEmpty) ...[
            SizedBox(height: smallPadding),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: smallPadding,
                vertical: smallPadding / 2,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  AppMeasurements.getResponsiveBorderRadius(context) * 2,
                ),
              ),
              child: Text(
                '${_userScans.length} ${_userScans.length == 1 ? 'scan' : 'scans'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary.withOpacity(1),
                  fontSize: AppMeasurements.getResponsiveFontSize(
                    context,
                    baseSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);

    if (_isLoading) {
      return SliverToBoxAdapter(child: _buildLoadingState(context));
    }

    if (_hasError) {
      return SliverToBoxAdapter(child: _buildErrorState(context));
    }

    if (_userScans.isEmpty) {
      return const SliverToBoxAdapter(child: HistoryEmptyState());
    }

    return SliverToBoxAdapter(
      child: HistoryListView(
        scans: _userScans,
        onDelete: _showDeleteConfirmationDialog,
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppMeasurements.getResponsivePadding(context)),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);
    final isLargeScreen = AppMeasurements.isLargeScreen(context);

    return Container(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: AppMeasurements.getResponsiveIconSizeLarge(context),
            color: Theme.of(context).colorScheme.error,
          ),
          SizedBox(height: smallPadding),
          Text(
            'Failed to load scans',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: AppMeasurements.getResponsiveFontSize(
                context,
                baseSize: isLargeScreen ? 22 : 18,
              ),
            ),
          ),
          SizedBox(height: smallPadding / 2),
          Text(
            'Check your connection',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: AppMeasurements.getResponsiveFontSize(
                context,
                baseSize: 14,
              ),
            ),
          ),
          SizedBox(height: smallPadding),
          FilledButton.icon(
            onPressed: _loadUserScans,
            icon: Icon(Icons.refresh_rounded,
                size: AppMeasurements.getResponsiveIconSizeSmall(context)),
            label: Text(
              'Try Again',
              style: TextStyle(
                fontSize: AppMeasurements.getResponsiveFontSize(
                  context,
                  baseSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(int index) async {
    final scan = _userScans[index];
    final diagnosis = scan['diagnosis']?.toString() ?? 'this scan';

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
        ),
        title: Text(
          'Delete Scan?',
          style: TextStyle(
            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
          ),
        ),
        content: Text(
          'Delete "$diagnosis"? This cannot be undone.',
          style: TextStyle(
            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteScan(index);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              'Delete',
              style: TextStyle(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteScan(int index) async {
    try {
      final scan = _userScans[index];
      final scanId = scan['id'] as String?;
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null || scanId == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scans')
          .doc(scanId)
          .delete();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'scanCount': FieldValue.increment(-1),
      });

      if (mounted) {
        setState(() {
          _userScans.removeAt(index);
        });

        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scan deleted',
              style: TextStyle(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppMeasurements.getResponsiveBorderRadius(context),
              ),
            ),
            duration: const Duration(seconds: 2),
            margin: EdgeInsets.all(AppMeasurements.getResponsiveSmallPadding(context)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete',
              style: TextStyle(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppMeasurements.getResponsiveBorderRadius(context),
              ),
            ),
            margin: EdgeInsets.all(AppMeasurements.getResponsiveSmallPadding(context)),
          ),
        );
      }
    }
  }
}