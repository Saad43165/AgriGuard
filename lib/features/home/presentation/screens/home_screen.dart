import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Navbar/presentation/nav_bar.dart';
import '../../../Profile/presentation/Components/floating_orb.dart';
import '../Species_widgets/species_grid_widget.dart' show SpeciesGridWidget;
import 'components/all_scans_dialog_content.dart';
import 'components/first_time_user_guide.dart';
import 'components/loading_section.dart';
import 'components/recent_scan_section.dart';
import 'components/scan_options_bottomsheet.dart';
import 'components/scan_service.dart';
import 'components/share_results_dialog_content.dart';
import 'components/welcome_section.dart';
import '../../../../core/constants/app_measurements.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const HomeScreen({super.key, this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  /* --------------------------------------------------------------------- *
   *  State
   * --------------------------------------------------------------------- */
  final List<Map<String, dynamic>> _recentScans = [];
  bool _isFirstTimeUser = true;
  bool _isLoading = false;
  bool _hasHandledArgs = false;

  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _pulseAnimation;

  final ScanService _scanService = ScanService();

  /* --------------------------------------------------------------------- *
   *  Lifecycle
   * --------------------------------------------------------------------- */
  @override
  void initState() {
    super.initState();
    _loadFirstTimeUser();
    _loadRecentScans();
    _initializeAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_hasHandledArgs) return;
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

    _hasHandledArgs = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (args.containsKey('newScan')) {
        _handleNewScan(args['newScan'] as Map<String, dynamic>);
      }
      if (args['refreshScans'] == true) {
        _loadRecentScans();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /* --------------------------------------------------------------------- *
   *  Animations
   * --------------------------------------------------------------------- */
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  /* --------------------------------------------------------------------- *
   *  Persistence
   * --------------------------------------------------------------------- */
  Future<void> _loadFirstTimeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(
                () => _isFirstTimeUser = prefs.getBool('isFirstTimeUser') ?? true);
      }
    } catch (e) {
      debugPrint('SharedPreferences error: $e');
    }
  }

  Future<void> _saveFirstTimeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstTimeUser', _isFirstTimeUser);
    } catch (e) {
      debugPrint('Failed to save first-time flag: $e');
    }
  }

  /* --------------------------------------------------------------------- *
   *  Data loading
   * --------------------------------------------------------------------- */
  Future<void> _loadRecentScans() async {
    setState(() => _isLoading = true);
    try {
      final scans = await _scanService.fetchRecentScans();
      if (mounted) {
        setState(() {
          _recentScans
            ..clear()
            ..addAll(scans);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load scans: $e', true);
      }
    }
  }

  Future<void> _refreshScans() async {
    HapticFeedback.lightImpact();
    await _loadRecentScans();
    if (mounted) _showSnackBar('Scans refreshed!', false);
  }

  /* --------------------------------------------------------------------- *
   *  Scan handling
   * --------------------------------------------------------------------- */
  void _handleNewScan(Map<String, dynamic> newScan) {
    final id = newScan['id']?.toString();
    if (id == null || _recentScans.any((s) => s['id']?.toString() == id)) {
      return;
    }

    setState(() {
      _recentScans.insert(0, newScan);
      _isFirstTimeUser = false;
    });
    _saveFirstTimeUser();
    _showSnackBar('New scan added!', false);
  }

  Future<void> _deleteScan(String id) async {
    final scan =
    _recentScans.firstWhereOrNull((s) => s['id']?.toString() == id);
    try {
      await _scanService.deleteScan(id);
      await _deleteImageFile(scan?['imagePath'] as String?);

      setState(() {
        _recentScans.removeWhere((s) => s['id']?.toString() == id);
        _isFirstTimeUser = _recentScans.isEmpty && _isFirstTimeUser;
      });
      _showSnackBar('Scan deleted!', false);
    } catch (e) {
      _showSnackBar('Failed to delete scan: $e', true);
    }
  }

  Future<void> _deleteImageFile(String? imagePath) async {
    if (imagePath == null || imagePath.startsWith('assets/')) return;
    try {
      final file = File(imagePath);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Failed to delete image: $e');
    }
  }

  /* --------------------------------------------------------------------- *
   *  UI helpers
   * --------------------------------------------------------------------- */
  void _showSnackBar(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
        ),
      ),
    );
  }

  /* --------------------------------------------------------------------- *
   *  Navigation
   * --------------------------------------------------------------------- */
  static const int _navHome = 0;
  static const int _navResults = 1;
  static const int _navProfile = 2;

  void _handleNavTap(int index) {
    if (index == _navHome) return;
    HapticFeedback.lightImpact();

    switch (index) {
      case _navResults:
        Navigator.pushNamed(context, '/ResultScreen');
        break;
      case _navProfile:
        Navigator.pushNamed(context, '/profile', arguments: widget.userData);
        break;
    }
  }

  /* --------------------------------------------------------------------- *
   *  Bottom sheets / dialogs
   * --------------------------------------------------------------------- */
  Future<void> _showAllScansDialog() async {
    HapticFeedback.lightImpact();
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(
          AppMeasurements.getResponsivePadding(context),
        ),
        child: AllScansDialogContent(
          recentScans: _recentScans,
          onDeleteScan: _deleteScan,
          onShowOptions: _showScanOptionsBottomSheet,
        ),
      ),
    );
  }

  Future<void> _showScanOptionsBottomSheet(Map<String, dynamic> scan) async {
    if (!mounted) return;
    HapticFeedback.mediumImpact();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ScanOptionsBottomSheet(
        scan: scan,
        onDelete: () => _deleteScan(scan['id']?.toString() ?? ''),
        onShare: () => _shareResults(scan),
      ),
    );
  }

  Future<void> _shareResults(Map<String, dynamic> scan) async {
    final shareText = '''
Plant Health Scan Results

Disease: ${scan['diagnosis'] ?? 'Unknown'}
Date: ${scan['timestamp'] ?? 'Unknown'}
Confidence: ${scan['confidence'] ?? 'N/A'}%

Treatment: ${scan['treatment'] ?? 'No treatment available'}
''';

    await showDialog(
      context: context,
      builder: (_) => ShareResultsDialogContent(shareText: shareText),
    );
  }

  /* --------------------------------------------------------------------- *
   *  Build
   * --------------------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [
              Color(0xFF0F0F23),
              Color(0xFF16213E),
              Color(0xFF1A1A2E),
            ]
                : [
              Theme.of(context).colorScheme.background,
              Theme.of(context)
                  .colorScheme
                  .background
                  .withOpacity(0.9),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Floating orbs
            ...List.generate(
              8,
                  (i) => FloatingOrb(
                key: ValueKey('orb_$i'),
                index: i,
                maxWidth: MediaQuery.of(context).size.width,
                fadeController: _fadeController,
                scaleAnimation: _scaleAnimation,
              ),
            ),

            // Main content
            SafeArea(
              child: RefreshIndicator(
                onRefresh: _refreshScans,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        padding,
                        padding * 0.5,
                        padding,
                        0,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Welcome
                          WelcomeSection(
                            isFirstTimeUser: _isFirstTimeUser,
                            scaleAnimation: _scaleAnimation,
                          ),
                          SizedBox(height: padding * 0.8),

                          // Species Grid
                          const SpeciesGridWidget(),
                          SizedBox(height: padding * 0.8),

                          // Content
                          if (_isLoading)
                            const LoadingSection()
                          else if (_isFirstTimeUser && _recentScans.isEmpty)
                            const FirstTimeUserGuide()
                          else
                            RecentScansSection(
                              key: const ValueKey('recent_scans'),
                              recentScans: _recentScans,
                              scaleAnimation: _scaleAnimation,
                              onDeleteScan: _deleteScan,
                              onShowAllScans: _showAllScansDialog,
                              onShowOptions: _showScanOptionsBottomSheet,
                            ),

                          // Bottom padding for FAB
                          SizedBox(height: padding + 80),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // FAB
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _navHome,
        onTap: _handleNavTap,
      ),
    );
  }
}

/* --------------------------------------------------------------------- *
 *  Helper extension
 * --------------------------------------------------------------------- */
extension IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}