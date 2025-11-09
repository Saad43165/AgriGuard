import 'package:agriguard_fyp/features/history/presentation/widgets/history_appbar.dart';
import 'package:agriguard_fyp/features/history/presentation/widgets/history_empty_state.dart';
import 'package:agriguard_fyp/features/history/presentation/widgets/history_list_view.dart';
import 'package:agriguard_fyp/features/history/presentation/widgets/history_measurements.dart';
import 'package:agriguard_fyp/features/history/presentation/widgets/history_theme_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
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
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HistoryMeasurements.snackBarBorderRadius),
        ),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(HistoryMeasurements.snackBarMargin),
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
                          child: _buildHeader(),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          HistoryMeasurements.contentPaddingHorizontal,
                          HistoryMeasurements.contentPaddingTop,
                          HistoryMeasurements.contentPaddingHorizontal,
                          HistoryMeasurements.contentPaddingBottom,
                        ),
                        sliver: _buildContent(),
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

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        HistoryMeasurements.headerMarginHorizontal,
        HistoryMeasurements.headerMarginTop,
        HistoryMeasurements.headerMarginHorizontal,
        HistoryMeasurements.headerMarginBottom,
      ),
      padding: const EdgeInsets.all(HistoryMeasurements.headerPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(HistoryMeasurements.headerBorderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(HistoryMeasurements.headerIconPadding),
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
              size: HistoryMeasurements.headerIconSize,
              color: Theme.of(context).brightness == Brightness.light
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.9)
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: HistoryMeasurements.headerSpacing),
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
              ),
            ),
          ),
          const SizedBox(height: HistoryMeasurements.headerSmallSpacing),
          Text(
            'Your crop health scans',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          if (_userScans.isNotEmpty) ...[
            const SizedBox(height: HistoryMeasurements.headerSpacing),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: HistoryMeasurements.scanCountBadgePadding,
                vertical: HistoryMeasurements.scanCountBadgeVerticalPadding,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  HistoryMeasurements.scanCountBadgeBorderRadius,
                ),
              ),
              child: Text(
                '${_userScans.length} ${_userScans.length == 1 ? 'scan' : 'scans'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary.withOpacity(1),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return SliverToBoxAdapter(child: _buildLoadingState());
    }

    if (_hasError) {
      return SliverToBoxAdapter(child: _buildErrorState());
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

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(HistoryMeasurements.loadingPadding),
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

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(HistoryMeasurements.errorPadding),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: HistoryMeasurements.errorIconSize,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: HistoryMeasurements.errorSpacing),
          Text(
            'Failed to load scans',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: HistoryMeasurements.errorSmallSpacing),
          Text(
            'Check your connection',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: HistoryMeasurements.errorButtonSpacing),
          FilledButton.icon(
            onPressed: _loadUserScans,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
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
          borderRadius: BorderRadius.circular(HistoryMeasurements.dialogBorderRadius),
        ),
        title: const Text('Delete Scan?'),
        content: Text('Delete "$diagnosis"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteScan(index);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
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
            content: const Text('Scan deleted'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(HistoryMeasurements.snackBarBorderRadius),
            ),
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(HistoryMeasurements.snackBarMargin),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(HistoryMeasurements.snackBarBorderRadius),
            ),
            margin: const EdgeInsets.all(HistoryMeasurements.snackBarMargin),
          ),
        );
      }
    }
  }
}