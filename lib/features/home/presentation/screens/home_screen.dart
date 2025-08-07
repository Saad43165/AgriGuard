import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../Navbar/presentation/nav_bar.dart';
import '../../../Profile/presentation/Components/floating_orb.dart';

import 'components/all_scans_dialog_content.dart';
import 'components/glass_card.dart';
import 'components/recent_scan_section.dart';
import 'components/scan_options_bottomsheet.dart';
import 'components/scan_service.dart';
import 'components/share_results_dialog_content.dart';
import 'components/welcome_section.dart';
import 'components/scan_button.dart';
import 'components/loading_section.dart';
import 'components/first_time_user_guide.dart';

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
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
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
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
        _scaleController.forward();
        _slideController.forward();
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isFirstTimeUser = prefs.getBool('isFirstTimeUser') ?? true;
      });
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
          if (scans.isNotEmpty) {
            _isFirstTimeUser = false;
            _saveFirstTimeUser();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showCustomSnackBar(message: 'Failed to load scans', isError: true);
      }
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
    if (args != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (args.containsKey('newScan') && args['newScan'] is Map<String, dynamic>) {
            final newScan = args['newScan'] as Map<String, dynamic>;
            if (!_recentScans.any((scan) => scan['id'] == newScan['id'])) {
              setState(() {
                _recentScans.insert(0, newScan);
                _isFirstTimeUser = false;
              });
              _saveFirstTimeUser();
              _showCustomSnackBar(message: 'New ResultScreen added successfully!', isError: false);
            }
          }
          if (args.containsKey('refreshScans') && args['refreshScans'] == true) {
            _loadRecentScans();
          }
        }
      });
    }
  }

  Future<void> _refreshScans() async {
    HapticFeedback.lightImpact();
    await _loadRecentScans();
    if (mounted) {
      _showCustomSnackBar(message: 'Scans refreshed successfully!', isError: false);
    }
  }

  void _showCustomSnackBar({required String message, required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isError
                  ? [
                Theme.of(context).colorScheme.error.withOpacity(0.8),
                Theme.of(context).colorScheme.error.withOpacity(0.8),
              ]
                  : [
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                Theme.of(context).colorScheme.secondary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _deleteScan(String id) async {
    final index = _recentScans.indexWhere((scan) => scan['id'] == id);
    if (index != -1) {
      final scan = _recentScans[index];
      final imagePath = scan['imageUrl'] as String?;
      if (imagePath != null && !imagePath.startsWith('assets/')) {
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
        _recentScans.removeAt(index);
        if (_recentScans.isEmpty) {
          _isFirstTimeUser = true;
        }
      });

      await _scanService.deleteScan(id);
      _saveFirstTimeUser();

      if (mounted) {
        _showCustomSnackBar(message: 'Scan deleted successfully!', isError: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String fullName = args?['fullName']?.toString() ?? widget.userData?['fullName']?.toString() ?? 'User';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
              const Color(0xFF0F0F23),
              const Color(0xFF16213E),
              const Color(0xFF1A1A2E),
              const Color(0xFF0F0F23),
            ]
                : [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.background.withOpacity(0.9),
              Theme.of(context).colorScheme.background.withOpacity(0.8),
              Theme.of(context).colorScheme.background,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: RefreshIndicator(
                    onRefresh: _refreshScans,
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - kToolbarHeight - 60),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 32),
                            WelcomeSection(fullName: fullName, isFirstTimeUser: _isFirstTimeUser, scaleAnimation: _scaleAnimation),
                            const SizedBox(height: 32),
                            ScanButton(pulseAnimation: _pulseAnimation),
                            const SizedBox(height: 32),
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
                            const SizedBox(height: 16),
                          ],
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
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 0,
        onTap: (index) {
          if (index != 0 && mounted) {
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
        },
      ),
    );
  }

  Future<void> _showAllScansDialog() async {
    HapticFeedback.lightImpact();
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
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
    try {
      final String shareText = '''
Plant Health Scan Results

Disease: ${scan['diagnosis'] ?? 'Unknown'}
Date: ${scan['timestamp'] ?? 'Unknown'}
Confidence: ${scan['confidence'] ?? 'N/A'}%

Treatment: ${scan['treatment'] ?? 'No treatment available'}

Generated by Plant Health Scanner
''';

      // TODO: Add share_plus package to pubspec.yaml and uncomment
      // import 'package:share_plus/share_plus.dart';
      // await Share.share(shareText);

      showDialog(
        context: context,
        builder: (context) => ShareResultsDialogContent(shareText: shareText),
      );
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar(message: 'Failed to share results', isError: true);
      }
    }
  }
}