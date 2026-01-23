// lib/features/home/presentation/screens/home_screen.dart - MAGICAL REDESIGN
import 'dart:convert';
import 'dart:io';

import 'package:agriguard_fyp/features/home/screens/species/species_grid_widget.dart';
import 'package:agriguard_fyp/features/home/screens/weather/provider/weather_provider.dart';
import 'package:agriguard_fyp/features/home/screens/weather/weather_card/weather_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/scan_model.dart';
import '../../../core/repositories/scan_repository.dart';
import '../../../core/widgets/floating_orb.dart';
import '../../auth/Login_Screen/services/guest_service.dart';
import 'bottom_sheet_widgets/scan_options_bottomsheet.dart';
import 'components/all_scans_dialog_content.dart';
import 'components/custom_home_app_bar.dart';
import 'components/first_time_user_guide.dart';
import 'components/guest_mode_banner.dart';
import 'components/loading_section.dart';
import 'components/recent_scan_section.dart';
import '../../../../core/constants/app_measurements.dart';
import 'components/advance_scan_section.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const HomeScreen({super.key, this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _onDeviceScans = [];
  final List<Map<String, dynamic>> _advancedScans = [];
  bool _isFirstTimeUser = true;
  bool _isLoading = false;
  bool _hasHandledRouteArgs = false;

  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final AnimationController _pulseController;
  late final AnimationController _slideController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<Offset> _slideAnimation;

  final ScanRepository _scanRepository = ScanRepository();
  final GuestService _guestService = GuestService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeGuestService();
    _loadFirstTimeUser();
    _loadRecentScans();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleRouteArguments();
    });
  }

  Future<void> _initializeGuestService() async {
    await _guestService.initialize();
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == true) {
      _loadRecentScans();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleRouteArguments() {
    if (_hasHandledRouteArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;
    _hasHandledRouteArgs = true;

    if (args.containsKey('newScan')) {
      final newScan = args['newScan'] as Map<String, dynamic>;
      _handleNewScan(newScan);
    }
    if (args['refreshScans'] == true) {
      _loadRecentScans();
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
  }

  Future<void> _loadFirstTimeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool('isFirstTimeUser');
      if (mounted) {
        setState(() => _isFirstTimeUser = saved ?? true);
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

  Future<void> _loadRecentScans() async {
    if (_guestService.isGuestMode) {
      if (mounted) {
        setState(() {
          _onDeviceScans.clear();
          _advancedScans.clear();
          _isLoading = false;
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final allScans = await _scanRepository.getUserScans(limit: 20);
      if (!mounted) return;

      setState(() {
        _onDeviceScans.clear();
        _advancedScans.clear();

        for (final scan in allScans) {
          final map = _convertScanToMap(scan);
          if (scan.scanType == ScanType.onDevice) {
            _onDeviceScans.add(map);
          } else {
            _advancedScans.add(map);
          }
        }

        _onDeviceScans.sort((a, b) => (b['scanDate'] as DateTime).compareTo(a['scanDate'] as DateTime));
        _advancedScans.sort((a, b) => (b['scanDate'] as DateTime).compareTo(a['scanDate'] as DateTime));
        _isLoading = false;

        if (_onDeviceScans.isEmpty && _advancedScans.isEmpty && !_isFirstTimeUser) {
          _isFirstTimeUser = true;
          _saveFirstTimeUser();
        }
      });
    } catch (e) {
      debugPrint('Error loading recent scans: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load scans', true);
      }
    }
  }

  Map<String, dynamic> _convertScanToMap(ScanModel scan) {
    return {
      'id': scan.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'diagnosis': scan.diseaseName,
      'severity': scan.severity,
      'confidence': scan.confidence.toString(),
      'treatment': scan.treatments.isNotEmpty ? scan.treatments.join('. ') : '',
      'imagePath': scan.imagePath,
      'imageUrl': scan.imageUrl,
      'imageBase64': scan.imageBase64,
      'plantName': scan.plantName,
      'scientificName': scan.scientificName,
      'scanType': scan.scanType.name,
      'analysisSource': scan.analysisSource.name,
      'isAdvanced': scan.isAdvanced,
      'scanDate': scan.scanDate,
      'timestamp': scan.scanDate,
      'symptoms': scan.symptoms,
      'precautions': scan.precautions,
      'rawData': scan.rawData,
      'advancedData': scan.advancedData,
      'diseaseName': scan.diseaseName,
      'createdAt': scan.createdAt,
    };
  }

  Future<void> _refreshScans() async {
    if (_guestService.isGuestMode) {
      _showSnackBar(_guestService.getRestrictionMessage('view_history'), true);
      return;
    }
    HapticFeedback.lightImpact();
    await _loadRecentScans();
    if (mounted) {
      _showSnackBar('Scans refreshed!', false);
    }
  }

  void _handleNewScan(Map<String, dynamic> newScan) {
    if (_guestService.isGuestMode) return;
    final id = newScan['id']?.toString();
    if (id == null) return;

    final isAdvanced = newScan['isAdvanced'] == true || newScan['scanType'] == 'advanced';
    final enrichedScan = {...newScan};

    if (!enrichedScan.containsKey('imageBase64') && newScan['imagePath'] != null) {
      final file = File(newScan['imagePath']);
      if (file.existsSync()) {
        try {
          final bytes = file.readAsBytesSync();
          enrichedScan['imageBase64'] = base64Encode(bytes);
        } catch (e) {
          debugPrint('Failed to read image as base64: $e');
        }
      }
    }

    if (isAdvanced) {
      if (_advancedScans.any((s) => s['id'] == id)) return;
      setState(() => _advancedScans.insert(0, enrichedScan));
    } else {
      if (_onDeviceScans.any((s) => s['id'] == id)) return;
      setState(() => _onDeviceScans.insert(0, enrichedScan));
    }

    if (_isFirstTimeUser) {
      setState(() => _isFirstTimeUser = false);
      _saveFirstTimeUser();
    }
    _showSnackBar('New scan added!', false);
  }

  Future<void> _deleteScan(String? id) async {
    if (id == null || !mounted) return;
    try {
      await _scanRepository.deleteScan(id);
      setState(() {
        _onDeviceScans.removeWhere((s) => s['id'] == id);
        _advancedScans.removeWhere((s) => s['id'] == id);
      });
      _showSnackBar('Scan deleted!', false);
      if (_onDeviceScans.isEmpty && _advancedScans.isEmpty && !_isFirstTimeUser) {
        setState(() => _isFirstTimeUser = true);
        _saveFirstTimeUser();
      }
    } catch (e) {
      _showSnackBar('Failed to delete scan', true);
    }
  }

  void _showSnackBar(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  Future<void> _showOnDeviceScansDialog() async {
    if (_guestService.isGuestMode) {
      _showSnackBar(_guestService.getRestrictionMessage('view_history'), true);
      return;
    }
    HapticFeedback.lightImpact();
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: AllScansDialogContent(
          recentScans: _onDeviceScans,
          onDeleteScan: _deleteScan,
          onShowOptions: _showScanOptionsBottomSheet,
          title: 'On-Device Scans',
        ),
      ),
    );
  }

  Future<void> _showAdvancedScansDialog() async {
    if (_guestService.isGuestMode) {
      _showSnackBar(_guestService.getRestrictionMessage('view_history'), true);
      return;
    }
    HapticFeedback.lightImpact();
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: AllScansDialogContent(
          recentScans: _advancedScans,
          onDeleteScan: _deleteScan,
          onShowOptions: _showScanOptionsBottomSheet,
          title: 'Advanced AI Scans',
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
        onDelete: () => _deleteScan(scan['id'] as String?),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WeatherProvider(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const CustomHomeAppBar(),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [const Color(0xFF0A0E27), const Color(0xFF1A1F3A), const Color(0xFF0F1419)]
                  : [const Color(0xFFF8FAFB), const Color(0xFFE8F5E9), const Color(0xFFF1F8F4)],
            ),
          ),
          child: Stack(
            children: [
              ...List.generate(8, (i) => FloatingOrb(
                index: i,
                maxWidth: MediaQuery.of(context).size.width,
                fadeController: _fadeController,
                scaleAnimation: _scaleAnimation,
              )),
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: _refreshScans,
                  color: Theme.of(context).colorScheme.primary,
                  child: Consumer<WeatherProvider>(
                    builder: (context, weatherProvider, _) {
                      return CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            sliver: SliverToBoxAdapter(
                              child: FadeTransition(
                                opacity: _fadeController,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: ListenableBuilder(
                                    listenable: _guestService,
                                    builder: (context, _) => GuestModeBanner(guestService: _guestService),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                            sliver: SliverToBoxAdapter(
                              child: FadeTransition(
                                opacity: _fadeController,
                                child: const WeatherCard(),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                            sliver: SliverToBoxAdapter(
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: const SpeciesGridWidget(),
                              ),
                            ),
                          ),
                          if (_guestService.isGuestMode)
                            SliverPadding(
                              padding: const EdgeInsets.all(16),
                              sliver: SliverToBoxAdapter(child: _buildGuestModeContent()),
                            )
                          else if (_isLoading)
                            const SliverPadding(
                              padding: EdgeInsets.all(16),
                              sliver: SliverToBoxAdapter(child: LoadingSection()),
                            )
                          else if (_isFirstTimeUser && _onDeviceScans.isEmpty && _advancedScans.isEmpty)
                              SliverPadding(
                                padding: const EdgeInsets.all(16),
                                sliver: SliverToBoxAdapter(
                                  child: FadeTransition(
                                    opacity: _fadeController,
                                    child: const FirstTimeUserGuide(),
                                  ),
                                ),
                              )
                            else ...[
                                if (_onDeviceScans.isNotEmpty)
                                  SliverPadding(
                                    padding: const EdgeInsets.only(top: 24),
                                    sliver: SliverToBoxAdapter(
                                      child: ScaleTransition(
                                        scale: _scaleAnimation,
                                        child: RecentScansSection(
                                          key: const ValueKey('on_device_scans'),
                                          recentScans: _onDeviceScans.take(5).toList(),
                                          scaleAnimation: _scaleAnimation,
                                          onDeleteScan: _deleteScan,
                                          onShowAllScans: _showOnDeviceScansDialog,
                                          onShowOptions: _showScanOptionsBottomSheet,
                                          sectionTitle: 'On-Device Scans',
                                          showAdvancedBadge: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_advancedScans.isNotEmpty)
                                  SliverPadding(
                                    padding: const EdgeInsets.only(top: 24),
                                    sliver: SliverToBoxAdapter(
                                      child: ScaleTransition(
                                        scale: _scaleAnimation,
                                        child: AdvanceScanSection(
                                          advancedScans: _advancedScans,
                                          onShowOptions: _showScanOptionsBottomSheet,
                                          onShowAllAdvancedScans: _showAdvancedScansDialog,
                                          scaleAnimation: _scaleAnimation,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_onDeviceScans.isEmpty && _advancedScans.isEmpty)
                                  SliverPadding(
                                    padding: const EdgeInsets.all(16),
                                    sliver: SliverToBoxAdapter(child: _buildNoScansContent()),
                                  ),
                              ],
                          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestModeContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            Theme.of(context).colorScheme.surface.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, size: 40, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text('History Not Available', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Scan history is only available for registered users.\nSign in to save and view your scans.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoScansContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            Theme.of(context).colorScheme.surface.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.scanner_rounded, size: 56, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 20),
          Text('No Scans Yet', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            'Start scanning your plants to build your history.\nOn-device and advanced scans are shown separately.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}