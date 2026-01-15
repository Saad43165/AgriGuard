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

    final currentScans = _selectedTab == 'onDevice' ? _onDeviceScans : _advancedScans;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
              currentScans.isEmpty ? 'No scans found' : 'Refreshed successfully',
              style: TextStyle(
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
        margin: EdgeInsets.all(16),
      ),
    );
  }

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
      'data': scan['advancedData'] ?? scan['rawData']?['data'] ?? {
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                Color(0xFF1A1F3A).withOpacity(0.95),
                Color(0xFF0F172A).withOpacity(0.95),
              ]
                  : [
                Color(0xFFFAFAFA).withOpacity(0.95),
                Color(0xFFF5F5F5).withOpacity(0.95),
              ],
            ),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ).createShader(bounds),
          child: Text(
            'Scan History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        leading: Padding(
          padding: EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: _refreshScans,
                tooltip: 'Refresh',
              ),
            ),
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
              Color(0xFF0A0E27),
              Color(0xFF1A1F3A),
              Color(0xFF0F172A),
            ]
                : [
              Color(0xFFFAFAFA),
              Color(0xFFF5F5F5),
              Color(0xFFFFFFFF),
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
                    SizedBox(height: 8),

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

                    SizedBox(height: 16),

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

                    SizedBox(height: 16),

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
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            padding: EdgeInsets.all(20),
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
          SizedBox(height: 24),
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
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
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
            SizedBox(height: 24),
            Text(
              'Failed to load scans',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Please check your connection and try again',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _loadUserScans,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.refresh_rounded),
              label: Text('Try Again', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(int index) async {
    final scan = _currentScans[index];
    final diagnosis = scan['diagnosis']?.toString() ?? 'this scan';

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Text('Delete Scan?', style: TextStyle(fontSize: 20)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$diagnosis"? This action cannot be undone.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Cancel', style: TextStyle(fontSize: 15)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteScan(index);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Delete', style: TextStyle(fontSize: 15)),
          ),
        ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Scan deleted successfully', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: Duration(seconds: 2),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting scan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Failed to delete scan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}