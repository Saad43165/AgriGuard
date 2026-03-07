// lib/features/history/presentation/screens/history_screen.dart
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
import 'package:flutter/services.dart';
import '../../../core/widgets/floating_orb.dart';
import '../../ResultScreen/presentation/results_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scanRepository = ScanRepository();
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
    super.dispose();
  }

  List<Map<String, dynamic>> get _currentScans {
    return _selectedTab == 'onDevice' ? _onDeviceScans : _advancedScans;
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
      'source': scan['analysisSource']?.toString() ?? 'Gemini',
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: HistoryAppBar(
        title: 'Scan History',
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              const Color(0xFF0A0E27),
              const Color(0xFF1A1F3A),
              const Color(0xFF0F172A),
            ]
                : [
              const Color(0xFFFAFAFA),
              const Color(0xFFF5F5F5),
              const Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Floating orbs
            ...List.generate(
              3,
                  (i) => FloatingOrb(
                index: i,
                maxWidth: size.width,
                fadeController: _fadeController,
                scaleAnimation: _scaleAnimation,
              ),
            ),

            SafeArea(
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

                    const SizedBox(height: 16),

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
          ],
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

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _currentScans.length,
      itemBuilder: (context, index) {
        return HistoryScanCard(
          scan: _currentScans[index],
          index: index,
          onTap: () => _onScanTap(index),
          onDelete: () => _showDeleteConfirmationDialog(index),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
            'Loading your scans...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Failed to load scans',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please check your connection and try again',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
              label: const Text('Try Again', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DIALOG BUILDERS ====================

  Widget _buildLoadingDialog(String message) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF1E1E2E), const Color(0xFF16213E)]
                : [Colors.white, const Color(0xFFF8F9FF)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please wait...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [const Color(0xFF1E1E2E), const Color(0xFF16213E)]
                  : [Colors.white, const Color(0xFFFFF8F8)],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: Colors.red.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
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

  // ==================== DELETE FUNCTIONALITY ====================

  Future<void> _showDeleteConfirmationDialog(int index) async {
    final scan = _currentScans[index];
    final diagnosis = scan['diagnosis']?.toString() ?? 'this scan';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                const Color(0xFF1E1E2E),
                const Color(0xFF16213E),
              ]
                  : [
                Colors.white,
                const Color(0xFFF8F9FF),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade400,
                      Colors.red.shade600,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                  ],
                ).createShader(bounds),
                child: const Text(
                  'Delete Scan?',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                'Are you sure you want to delete "$diagnosis"? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Delete Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        _deleteScan(index);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade400,
                              Colors.red.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.delete_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
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