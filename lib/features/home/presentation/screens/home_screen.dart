import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Navbar/presentation/nav_bar.dart';
import '../../../Profile/presentation/Components/floating_orb.dart';
import 'components/all_scans_dialog_content.dart';
import 'components/recent_scan_section.dart';
import 'components/scan_options_bottomsheet.dart';
import 'components/scan_service.dart';
import 'components/share_results_dialog_content.dart';
import 'components/welcome_section.dart';
import 'components/scan_button.dart';
import 'components/loading_section.dart';
import 'components/first_time_user_guide.dart';
import '../../../../core/constants/app_measurements.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const HomeScreen({super.key, this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _recentScans = [];
  bool _isFirstTimeUser = true;
  bool _isLoading = false;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  final ScanService _scanService = ScanService();

  @override
  void initState() {
    super.initState();
    _loadFirstTimeUser();
    _loadRecentScans();
    _initializeAnimations();
  }

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

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _isFirstTimeUser = prefs.getBool('isFirstTimeUser') ?? true);
    }
  }

  Future<void> _loadRecentScans() async {
    setState(() => _isLoading = true);
    try {
      final scans = await _scanService.fetchRecentScans();
      if (mounted) {
        setState(() {
          _recentScans.clear();
          _recentScans.addAll(scans);
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

  Future<void> _deleteScan(String id) async {
    try {
      await _scanService.deleteScan(id);
      setState(() {
        _recentScans.removeWhere((scan) => scan['id'] == id);
        _isFirstTimeUser = _recentScans.isEmpty;
      });
      if (mounted) _showSnackBar('Scan deleted!', false);
    } catch (e) {
      if (mounted) _showSnackBar('Failed to delete scan: $e', true);
    }
  }
  Future<void> _saveFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTimeUser', _isFirstTimeUser);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (args.containsKey('newScan')) {
          _handleNewScan(args['newScan'] as Map<String, dynamic>);
        }
        if (args.containsKey('refreshScans') && args['refreshScans'] == true) {
          _loadRecentScans();
        }
      });
    }
  }

  void _handleNewScan(Map<String, dynamic> newScan) {
    if (!_recentScans.any((scan) => scan['id'] == newScan['id'])) {
      setState(() {
        _recentScans.insert(0, newScan);
        _isFirstTimeUser = false;
      });
      _saveFirstTimeUser();
      _showSnackBar('New scan added successfully!', false);
    }
  }

  Future<void> _refreshScans() async {
    HapticFeedback.lightImpact();
    await _loadRecentScans();
    if (mounted) _showSnackBar('Scans refreshed!', false);
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
        ),
      ),
    );
  }


  Future<void> _deleteImageFile(String? imagePath) async {
    if (imagePath != null && !imagePath.startsWith('assets/')) {
      try {
        final file = File(imagePath);
        if (await file.exists()) await file.delete();
      } catch (e) {
        debugPrint('Failed to delete image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = widget.userData?['fullName']?.toString() ?? 'User';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
              const Color(0xFF0F0F23),
              const Color(0xFF16213E),
              const Color(0xFF1A1A2E),
            ]
                : [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.background.withOpacity(0.9),
            ],
          ),
        ),
        child: Stack(
          children: [
            ...List.generate(
              8,
                  (index) => FloatingOrb(
                index: index,
                maxWidth: MediaQuery.of(context).size.width,
                fadeController: _fadeController,
                scaleAnimation: _scaleAnimation,
              ),
            ),
            SafeArea(
              child: RefreshIndicator(
                onRefresh: _refreshScans,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(
                    AppMeasurements.getResponsivePadding(context),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: AppMeasurements.getResponsivePadding(context),
                      ),
                      WelcomeSection(
                        isFirstTimeUser: _isFirstTimeUser,
                        scaleAnimation: _scaleAnimation,
                      ),
                      SizedBox(
                        height: AppMeasurements.getResponsivePadding(context),
                      ),
                      ScanButton(
                      ),
                      SizedBox(
                        height: AppMeasurements.getResponsivePadding(context),
                      ),
                      _isLoading
                          ? const LoadingSection()
                          : _recentScans.isEmpty
                          ? const FirstTimeUserGuide()
                          : RecentScansSection(
                        recentScans: _recentScans,
                        scaleAnimation: _scaleAnimation,
                        onDeleteScan: _deleteScan,
                        onShowAllScans: _showAllScansDialog,
                        onShowOptions: _showScanOptionsBottomSheet,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 0,
        onTap: (index) => _handleNavTap(index, context),
      ),
    );
  }

  void _handleNavTap(int index, BuildContext context) {
    if (index == 0) return;
    HapticFeedback.lightImpact();
    switch (index) {
      case 1:
        Navigator.pushNamed(context, '/ResultScreen');
        break;
      case 2:
        Navigator.pushNamed(context, '/profile', arguments: widget.userData);
        break;
    }
  }

  Future<void> _showAllScansDialog() async {
    HapticFeedback.lightImpact();
    await showDialog(
      context: context,
      builder: (context) => Dialog(
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
    HapticFeedback.lightImpact();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ScanOptionsBottomSheet(
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

    showDialog(
      context: context,
      builder: (context) => ShareResultsDialogContent(shareText: shareText),
    );
  }
}