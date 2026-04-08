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
import '../../../core/constants/app_routes.dart';
import '../../auth/Login_Screen/services/guest_service.dart';
import 'PdfDialogs/scan_options_bottomsheet.dart';
import 'components/all_scans_dialog_content.dart';
import 'components/custom_home_app_bar.dart';
import 'components/first_time_user_guide.dart';
import 'components/guest_mode_banner.dart';
import 'components/loading_section.dart';
import 'components/recent_scan_section.dart';
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
  int _scanFeedIndex = 0; // 0=On-device, 1=Advanced

  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final AnimationController _slideController;
  late final Animation<double> _scaleAnimation;
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

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
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
              // Keep background motion subtle (Home must stay fast).
              ...List.generate(3, (i) => FloatingOrb(
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
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
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
                            padding: const EdgeInsets.fromLTRB(10, 14, 10, 0),
                            sliver: SliverToBoxAdapter(
                              child: FadeTransition(
                                opacity: _fadeController,
                                child: _QuickActionsCard(
                                  isGuest: _guestService.isGuestMode,
                                  onQuickScan: _showScanChoiceDialog,
                                  onOpenHistory: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pushNamed(context, AppRoutes.history);
                                  },
                                  onOpenAdvanced: () {
                                    HapticFeedback.lightImpact();
                                    _openScanFlow(startAdvanced: true);
                                  },
                                  onOpenHelp: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pushNamed(context, AppRoutes.help);
                                  },
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                            sliver: SliverToBoxAdapter(
                              child: FadeTransition(
                                opacity: _fadeController,
                                child: const WeatherCard(),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                            sliver: SliverToBoxAdapter(
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: const SpeciesGridWidget(),
                              ),
                            ),
                          ),
                          if (!_guestService.isGuestMode)
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(10, 18, 10, 0),
                              sliver: SliverToBoxAdapter(
                                child: FadeTransition(
                                  opacity: _fadeController,
                                  child: _ScanFeedToggle(
                                    selectedIndex: _scanFeedIndex,
                                    onChanged: (v) => setState(() => _scanFeedIndex = v),
                                    onDeviceCount: _onDeviceScans.length,
                                    advancedCount: _advancedScans.length,
                                  ),
                                ),
                              ),
                            ),
                          if (_guestService.isGuestMode)
                            SliverPadding(
                              padding: const EdgeInsets.all(10),
                              sliver: SliverToBoxAdapter(child: _buildGuestModeContent()),
                            )
                          else if (_isLoading)
                            const SliverPadding(
                              padding: EdgeInsets.all(10),
                              sliver: SliverToBoxAdapter(child: LoadingSection()),
                            )
                          else if (_isFirstTimeUser && _onDeviceScans.isEmpty && _advancedScans.isEmpty)
                              SliverPadding(
                                padding: const EdgeInsets.all(10),
                                sliver: SliverToBoxAdapter(
                                  child: FadeTransition(
                                    opacity: _fadeController,
                                    child: const FirstTimeUserGuide(),
                                  ),
                                ),
                              )
                            else ...[
                                if (_scanFeedIndex == 0 && _onDeviceScans.isNotEmpty)
                                  SliverPadding(
                                    padding: const EdgeInsets.only(top: 10),
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
                                if (_scanFeedIndex == 1 && _advancedScans.isNotEmpty)
                                  SliverPadding(
                                    padding: const EdgeInsets.only(top: 10),
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
                                    padding: const EdgeInsets.all(10),
                                    sliver: SliverToBoxAdapter(child: _buildNoScansContent()),
                                  ),
                                if (_scanFeedIndex == 0 && _onDeviceScans.isEmpty && _advancedScans.isNotEmpty)
                                  SliverPadding(
                                    padding: const EdgeInsets.all(10),
                                    sliver: SliverToBoxAdapter(
                                      child: _EmptyStateCard(
                                        title: 'No on-device scans yet',
                                        subtitle: 'Try scanning offline, or switch to Advanced scans.',
                                        icon: Icons.qr_code_scanner_rounded,
                                      ),
                                    ),
                                  ),
                                if (_scanFeedIndex == 1 && _advancedScans.isEmpty && _onDeviceScans.isNotEmpty)
                                  SliverPadding(
                                    padding: const EdgeInsets.all(10),
                                    sliver: SliverToBoxAdapter(
                                      child: _EmptyStateCard(
                                        title: 'No advanced scans yet',
                                        subtitle: 'Try Advanced scan for deeper analysis.',
                                        icon: Icons.auto_awesome_rounded,
                                      ),
                                    ),
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

  void _openScanFlow({required bool startAdvanced}) {
    Navigator.pushNamed(
      context,
      AppRoutes.scan,
      arguments: {
        'startOnDevice': !startAdvanced,
        'startAdvanced': startAdvanced,
      },
    );
  }

  void _showScanChoiceDialog() {
    final theme = Theme.of(context);
    final isGuest = _guestService.isGuestMode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ScanModeButton(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'On-device scan',
                    subtitle: 'Fast and works offline',
                    primary: theme.colorScheme.primary,
                    onTap: () {
                      Navigator.pop(context);
                      _openScanFlow(startAdvanced: false);
                    },
                  ),
                  const SizedBox(height: 10),
                  _ScanModeButton(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Advanced scan',
                    subtitle: isGuest
                        ? 'Locked in guest mode'
                        : 'Cloud analysis with deeper insights',
                    primary: theme.colorScheme.secondary,
                    onTap: isGuest
                        ? null
                        : () {
                            Navigator.pop(context);
                            _openScanFlow(startAdvanced: true);
                          },
                    isLocked: isGuest,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnDeviceScanCta extends StatelessWidget {
  final VoidCallback onTap;
  const _OnDeviceScanCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          height: 78,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary.withOpacity(isDark ? 0.85 : 0.92),
                secondary.withOpacity(isDark ? 0.55 : 0.75),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(isDark ? 0.28 : 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.16 : 0.22)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isDark ? 0.16 : 0.20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Scan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Offline • Fast • Works without internet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.88),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  final bool isGuest;
  final VoidCallback onQuickScan;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenAdvanced;
  final VoidCallback onOpenHelp;

  const _QuickActionsCard({
    required this.isGuest,
    required this.onQuickScan,
    required this.onOpenHistory,
    required this.onOpenAdvanced,
    required this.onOpenHelp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(isDark ? 0.55 : 0.90),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _PrimaryScanCta(
            onTap: onQuickScan,
            title: 'Quick Scan',
            subtitle: 'Choose On-device or Advanced',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionMini(
                  icon: Icons.history_rounded,
                  label: 'History',
                  onTap: onOpenHistory,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionMini(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Advanced Scan',
                  onTap: isGuest ? null : onOpenAdvanced,
                  badge: isGuest ? 'Locked' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _QuickActionMini(
            icon: Icons.help_outline_rounded,
            label: 'Support & Help',
            onTap: onOpenHelp,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _PrimaryScanCta extends StatelessWidget {
  final VoidCallback onTap;
  final String title;
  final String subtitle;

  const _PrimaryScanCta({
    required this.onTap,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          height: 78,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary.withOpacity(isDark ? 0.85 : 0.92),
                secondary.withOpacity(isDark ? 0.55 : 0.75),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(isDark ? 0.28 : 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.16 : 0.22)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isDark ? 0.16 : 0.20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.88),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionMini extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? badge;
  final bool fullWidth;

  const _QuickActionMini({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final disabled = onTap == null;

    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(isDark ? 0.22 : 0.50),
            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.10)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: disabled ? theme.disabledColor : theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: disabled ? theme.disabledColor : null,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: theme.colorScheme.error.withOpacity(0.12),
                    border: Border.all(color: theme.colorScheme.error.withOpacity(0.20)),
                  ),
                  child: Text(
                    badge!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (fullWidth) {
      return SizedBox(width: double.infinity, child: card);
    }
    return card;
  }
}

class _ScanModeButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color primary;
  final VoidCallback? onTap;
  final bool isLocked;

  const _ScanModeButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: disabled
                ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.45)
                : primary.withOpacity(0.10),
            border: Border.all(
              color: disabled ? theme.disabledColor.withOpacity(0.3) : primary.withOpacity(0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: disabled ? theme.disabledColor.withOpacity(0.16) : primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: disabled ? theme.disabledColor : primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: disabled ? theme.disabledColor : null,
                            ),
                          ),
                        ),
                        if (isLocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: theme.colorScheme.error.withOpacity(0.12),
                            ),
                            child: Text(
                              'Locked',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: disabled
                            ? theme.disabledColor
                            : theme.colorScheme.onSurface.withOpacity(0.72),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: disabled ? theme.disabledColor : primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  const _SectionShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: theme.colorScheme.surface.withOpacity(isDark ? 0.55 : 0.90),
          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.16 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.70),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _SectionTrailingButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SectionTrailingButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onTap == null;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: disabled ? theme.disabledColor : theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ScanFeedToggle extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final int onDeviceCount;
  final int advancedCount;

  const _ScanFeedToggle({
    required this.selectedIndex,
    required this.onChanged,
    required this.onDeviceCount,
    required this.advancedCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(isDark ? 0.55 : 0.90),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              selected: selectedIndex == 0,
              label: 'On-device ($onDeviceCount)',
              icon: Icons.qr_code_scanner_rounded,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SegmentButton(
              selected: selectedIndex == 1,
              label: 'Advanced ($advancedCount)',
              icon: Icons.auto_awesome_rounded,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected ? primary.withOpacity(0.14) : Colors.transparent,
            border: Border.all(
              color: selected ? primary.withOpacity(0.40) : theme.colorScheme.onSurface.withOpacity(0.10),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: selected ? primary : theme.colorScheme.onSurface.withOpacity(0.75)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: selected ? primary : theme.colorScheme.onSurface.withOpacity(0.78),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: theme.colorScheme.surface.withOpacity(isDark ? 0.55 : 0.90),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.18)),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.70),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}