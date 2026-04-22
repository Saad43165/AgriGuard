import 'package:agriguard_fyp/features/history/presentation/utils/history_csv_generator.dart';
import 'package:agriguard_fyp/features/history/presentation/utils/history_pdf_generator.dart';
import 'package:agriguard_fyp/features/history/presentation/widgets/export_option_dialog.dart';
import 'package:agriguard_fyp/features/history/presentation/widgets/export_success_dialog.dart';
import 'package:agriguard_fyp/features/history/presentation/widgets/history_appbar.dart';
import 'package:agriguard_fyp/features/history/presentation/widgets/history_appbar_actions.dart';
import 'package:agriguard_fyp/features/history/presentation/widgets/history_empty_state.dart';
import 'package:agriguard_fyp/features/history/presentation/widgets/history_scan_card.dart';
import 'package:agriguard_fyp/features/history/presentation/widgets/history_stats_card.dart';
import 'package:agriguard_fyp/features/history/presentation/widgets/history_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/services/translation_service.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_themes.dart';
import '../../auth/login/services/guest_service.dart';
import '../../result_screen/presentation/results_screen.dart';
import '../../advance_result_screen/advanced_result_screen.dart';
import '../../../../core/repositories/scan_repository.dart';

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

  List<Map<String, dynamic>> _onDeviceScans = [];
  List<Map<String, dynamic>> _advancedScans = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _selectedTab = 'onDevice';
  late final ScanRepository _scanRepository;

  // Search & Filter state
  String _searchQuery = '';
  String _activeFilter = 'all'; // 'all', 'healthy', 'diseased', 'high'
  final TextEditingController _searchController = TextEditingController();

  // Guest mode
  final GuestService _guestService = GuestService();
  bool _isGuestMode = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scanRepository = ScanRepository();
    _initGuest();
  }

  Future<void> _initGuest() async {
    await _guestService.initialize();
    if (mounted) {
      setState(() => _isGuestMode = _guestService.isGuestMode);
      if (!_isGuestMode) _loadUserScans();
    }
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

      final onDeviceScans = await _scanRepository.getOnDeviceScans();
      final advancedScans = await _scanRepository.getAdvancedScans();

      final List<Map<String, dynamic>> onDeviceUiScans = [];
      final List<Map<String, dynamic>> advancedUiScans = [];

      for (final scan in onDeviceScans) {
        onDeviceUiScans.add(scan.toHistoryMap());
      }

      for (final scan in advancedScans) {
        advancedUiScans.add(scan.toHistoryMap());
      }

      if (mounted) {
        setState(() {
          _onDeviceScans = onDeviceUiScans;
          _advancedScans = advancedUiScans;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading scans: $e');
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

    final currentScans =
    _selectedTab == 'onDevice' ? _onDeviceScans : _advancedScans;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              currentScans.isEmpty ? 'No scans found' : 'Refreshed successfully',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ==================== EXPORT FUNCTIONALITY ====================

  Future<void> _exportHistory() async {
    // Check if there are any scans to export
    if (_onDeviceScans.isEmpty && _advancedScans.isEmpty) {
      _showErrorSnackBar('No scans to export. Scan some plants first!');
      return;
    }

    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (context) => ExportOptionsDialog(
        onPdfExport: _exportAsPdf,
        onCsvExport: _exportAsCsv,
      ),
    );
  }

  Future<void> _exportAsPdf() async {
    try {
      HapticFeedback.mediumImpact();

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildLoadingDialog('Generating PDF...'),
      );

      final file = await HistoryPdfGenerator.generateHistoryPdf(
        onDeviceScans: _onDeviceScans,
        advancedScans: _advancedScans,
      );

      if (mounted) Navigator.pop(context); // Close loading

      // Show success dialog
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => ExportSuccessDialog(
            file: file,
            fileType: 'PDF',
            scanCount: _onDeviceScans.length + _advancedScans.length,
          ),
        );
      }
    } catch (e) {
      debugPrint('PDF generation error: $e');
      if (mounted) Navigator.pop(context); // Close loading

      if (mounted) {
        _showErrorDialog('Failed to Generate PDF', e.toString());
      }
    }
  }

  Future<void> _exportAsCsv() async {
    try {
      HapticFeedback.mediumImpact();

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildLoadingDialog('Generating CSV...'),
      );

      final file = await HistoryCsvGenerator.generateHistoryCsv(
        onDeviceScans: _onDeviceScans,
        advancedScans: _advancedScans,
      );

      if (mounted) Navigator.pop(context); // Close loading

      // Show success dialog
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => ExportSuccessDialog(
            file: file,
            fileType: 'CSV',
            scanCount: _onDeviceScans.length + _advancedScans.length,
          ),
        );
      }
    } catch (e) {
      debugPrint('CSV generation error: $e');
      if (mounted) Navigator.pop(context); // Close loading

      if (mounted) {
        _showErrorDialog('Failed to Generate CSV', e.toString());
      }
    }
  }

  // ==================== END EXPORT FUNCTIONALITY ====================

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _currentScans {
    return _selectedTab == 'onDevice' ? _onDeviceScans : _advancedScans;
  }

  List<Map<String, dynamic>> get _filteredScans {
    var scans = _currentScans;
    // Apply search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      scans = scans.where((s) {
        final plant = (s['plantName'] ?? '').toString().toLowerCase();
        final disease = (s['diseaseName'] ?? s['diagnosis'] ?? '').toString().toLowerCase();
        return plant.contains(q) || disease.contains(q);
      }).toList();
    }
    // Apply filter
    switch (_activeFilter) {
      case 'healthy':
        scans = scans.where((s) {
          final d = (s['diseaseName'] ?? s['diagnosis'] ?? '').toString().toLowerCase();
          return d.contains('healthy');
        }).toList();
        break;
      case 'diseased':
        scans = scans.where((s) {
          final d = (s['diseaseName'] ?? s['diagnosis'] ?? '').toString().toLowerCase();
          return !d.contains('healthy');
        }).toList();
        break;
      case 'high':
        scans = scans.where((s) {
          final sev = (s['severity'] ?? '').toString().toLowerCase();
          return sev == 'high' || sev == 'severe' || sev == 'critical';
        }).toList();
        break;
    }
    return scans;
  }

  void _onScanTap(int index) {
    final scan = _currentScans[index];

    if (scan['isAdvanced'] == true) {
      _openAdvancedScan(scan);
    } else {
      _openOnDeviceScan(scan);
    }
  }

  void _openOnDeviceScan(Map<String, dynamic> scan) {
    final scanData = {
      ...scan,
      'isFromHistory': true,
      'skipSave': true,
      'alreadySaved': true,
      'originalId': scan['id'],
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(scanData: scanData),
      ),
    );
  }

  void _openAdvancedScan(Map<String, dynamic> scan) {
    final analysisResult = {
      'source': scan['analysisSource']?.toString() ?? 'Groq',
      'data': scan['advancedData'] ??
          scan['rawData']?['data'] ??
          {
            'plant': scan['plantName'] ?? 'Unknown Plant',
            'disease': scan['diseaseName'] ?? scan['diagnosis'] ?? 'Unknown Disease',
            'confidence': scan['confidence'] ?? '0',
            'severity': scan['severity'] ?? 'Medium',
            'symptoms': scan['symptoms'] ?? [],
            'remediation': scan['treatments'] ?? scan['remediation'] ?? [],
            'precautions': scan['precautions'] ?? [],
          },
      'success': true,
      'hasDiseaseInfo': true,
      'scanId': scan['id'],
    };

    final originalScanData = {
      'imagePath': scan['imagePath'],
      'imageUrl': scan['imageUrl'],
      'imageBase64': scan['imageBase64'],
      'isFromHistory': true,
      'skipSave': true,
      'alreadySaved': true,
      'id': scan['id'],
      'originalId': scan['id'],
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvancedResultsScreen(
          analysisResult: analysisResult,
          originalScanData: originalScanData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context, listen: false);

    // ── Guest mode — show lock screen ─────────────────────────────────────
    if (_isGuestMode) {
      return _GuestHistoryBlock(isDark: isDark, t: t);
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: HistoryAppBar(
        title: t.isUrdu ? 'اسکین ہسٹری' : 'Scan History',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: HistoryAppBarAction(
              icon: Icons.file_download_rounded,
              onPressed: _exportHistory,
              tooltip: 'Export History',
            ),
          ),
          HistoryAppBarAction(
            icon: Icons.refresh_rounded,
            onPressed: _refreshScans,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Stats Card
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: HistoryStatsCard(
                        totalScans: _onDeviceScans.length + _advancedScans.length,
                        onDeviceCount: _onDeviceScans.length,
                        advancedCount: _advancedScans.length,
                        isLoading: _isLoading,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tab Selector
                    HistoryTabSelector(
                      selectedTab: _selectedTab,
                      onDeviceCount: _onDeviceScans.length,
                      advancedCount: _advancedScans.length,
                      onTabChanged: (tab) {
                        setState(() => _selectedTab = tab);
                        HapticFeedback.selectionClick();
                      },
                    ),

                    const SizedBox(height: 12),

                    // Search Bar
                    _buildSearchBar(isDark),

                    const SizedBox(height: 8),

                    // Filter Chips
                    _buildFilterChips(isDark),

                    const SizedBox(height: 4),

                    // Result count
                    if (!_isLoading && !_hasError)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Text(
                          'Showing ${_filteredScans.length} of ${_currentScans.length} scans',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
                          ),
                        ),
                      ),

                    const SizedBox(height: 4),

                    // Content
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshScans,
                        color: Theme.of(context).colorScheme.primary,
                        child: _buildContent(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_currentScans.isEmpty) {
      return HistoryEmptyStateWidget(
        isAdvanced: _selectedTab == 'advanced',
      );
    }

    if (_filteredScans.isEmpty) {
      return _buildNoResultsState();
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredScans.length,
      itemBuilder: (context, index) {
        return HistoryScanCard(
          scan: _filteredScans[index],
          index: index,
          onTap: () => _onFilteredScanTap(index),
          onDelete: () => _showDeleteConfirmationDialogForScan(_filteredScans[index]),
        );
      },
    );
  }

  void _onFilteredScanTap(int index) {
    final scan = _filteredScans[index];
    if (scan['isAdvanced'] == true) {
      _openAdvancedScan(scan);
    } else {
      _openOnDeviceScan(scan);
    }
  }

  Widget _buildSearchBar(bool isDark) {
    final t = Provider.of<TranslationService>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.5,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(
            color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: t.isUrdu ? 'پودے یا بیماری سے تلاش کریں...' : 'Search by plant or disease...',
            hintStyle: TextStyle(
              color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
              fontSize: 14,
            ),
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(Icons.close_rounded,
                        color: isDark ? AppColors.darkCaption : AppColors.lightCaption, size: 18),
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final t = Provider.of<TranslationService>(context, listen: false);
    final filters = [
      ('all', t.isUrdu ? 'سب' : 'All'),
      ('healthy', t.isUrdu ? 'صحت مند' : 'Healthy'),
      ('diseased', t.isUrdu ? 'بیمار' : 'Diseased'),
      ('high', t.isUrdu ? 'زیادہ شدت' : 'High Severity'),
    ];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters.map((f) {
          final isSelected = _activeFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _activeFilter = f.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCard : AppColors.lightCard),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNoResultsState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context, listen: false);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              t.isUrdu ? 'کوئی نتیجہ نہیں ملا' : 'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.isUrdu ? 'اپنی تلاش یا فلٹر تبدیل کریں' : 'Try adjusting your search or filter',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _activeFilter = 'all';
                });
              },
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: Text(t.isUrdu ? 'فلٹر صاف کریں' : 'Clear filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final t = Provider.of<TranslationService>(context, listen: false);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            t.isUrdu ? 'آپ کے اسکینز لوڈ ہو رہے ہیں...' : 'Loading your scans...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final t = Provider.of<TranslationService>(context, listen: false);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t.isUrdu ? 'اسکینز لوڈ کرنے میں ناکامی' : 'Failed to load scans',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please check your connection and try again',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _loadUserScans,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(t.isUrdu ? 'دوبارہ کوشش کریں' : 'Try Again', style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DIALOG BUILDERS ====================

  Widget _buildLoadingDialog(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Please wait...',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.error_outline_rounded, size: 36, color: AppColors.error),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Close', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialogForScan(Map<String, dynamic> scan) async {
    final diagnosis = scan['diagnosis']?.toString() ?? 'this scan';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded, size: 40, color: AppColors.error),
              ),
              const SizedBox(height: 20),
              Text('Delete Scan?',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20,
                      color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface)),
              const SizedBox(height: 10),
              Text('Are you sure you want to delete "$diagnosis"? This cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14,
                      color: isDark ? AppColors.darkCaption : AppColors.lightCaption)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        _deleteScanById(scan['id'] as String?);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteScanById(String? scanId) async {
    if (scanId == null) return;
    try {
      await _scanRepository.deleteScan(scanId);
      setState(() {
        _onDeviceScans.removeWhere((s) => s['id'] == scanId);
        _advancedScans.removeWhere((s) => s['id'] == scanId);
      });
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Scan deleted successfully', style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete scan'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // ==================== DELETE FUNCTIONALITY ====================

  Future<void> _showDeleteConfirmationDialog(int index) async {
    final scan = _currentScans[index];
    final diagnosis = scan['diagnosis']?.toString() ?? 'this scan';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete_outline_rounded, size: 32, color: AppColors.error),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete Scan?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "$diagnosis"? This cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        _deleteScan(index);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteScan(int index) async {
    try {
      final scan = _currentScans[index];
      final scanId = scan['id'] as String?;

      if (scanId != null) {
        await _scanRepository.deleteScan(scanId);

        setState(() {
          if (_selectedTab == 'onDevice') {
            _onDeviceScans.removeAt(index);
          } else {
            _advancedScans.removeAt(index);
          }
        });

        HapticFeedback.mediumImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Scan deleted successfully',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting scan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  'Failed to delete scan',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}

class _GuestHistoryBlock extends StatelessWidget {
  final bool isDark;
  final TranslationService t;

  const _GuestHistoryBlock({required this.isDark, required this.t});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.isUrdu ? 'اسکین ہسٹری' : 'Scan History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t.isUrdu ? 'ہسٹری دستیاب نہیں' : 'History Unavailable',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t.isUrdu
                    ? 'اپنی اسکین ہسٹری دیکھنے کے لیے براہ کرم لاگ ان کریں'
                    : 'Please log in to view your scan history',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  ),
                  icon: const Icon(Icons.login_rounded),
                  label: Text(
                    t.isUrdu ? 'لاگ ان کریں' : 'Log In',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
}

