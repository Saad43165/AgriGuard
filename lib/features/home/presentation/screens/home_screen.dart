import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/nav_bar.dart';

class ScanService {
  Future<List<Map<String, dynamic>>> fetchRecentScans() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    final prefs = await SharedPreferences.getInstance();
    final scansJson = prefs.getStringList('recent_scans') ?? [];

    List<Map<String, dynamic>> scans = [];
    for (String scanJson in scansJson) {
      try {
        // Parse the JSON string into a Map (assuming proper serialization)
        final Map<String, dynamic> scan = Map<String, dynamic>.from(
          jsonDecode(scanJson) as Map, // Requires `import 'dart:convert';`
        );
        scans.add(scan);
      } catch (e) {
        debugPrint('Error parsing scan: $e');
      }
    }
    return scans;
  }

  // Add method to save scan with proper JSON serialization
  Future<void> saveScan(Map<String, dynamic> scan) async {
    final prefs = await SharedPreferences.getInstance();
    final scansJson = prefs.getStringList('recent_scans') ?? [];

    // Add new scan to beginning of list with JSON encoding
    scansJson.insert(0, jsonEncode(scan)); // Requires `import 'dart:convert';`

    // Keep only last 10 scans
    if (scansJson.length > 10) {
      scansJson.removeRange(10, scansJson.length);
    }

    await prefs.setStringList('recent_scans', scansJson);
  }

  // Add method to delete scan
  Future<void> deleteScan(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final scansJson = prefs.getStringList('recent_scans') ?? [];
    final updatedScans = scansJson.where((json) {
      final scan = jsonDecode(json) as Map<String, dynamic>;
      return scan['id'] != id;
    }).toList();
    await prefs.setStringList('recent_scans', updatedScans);
  }
}

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
      final scans = await ScanService().fetchRecentScans();
      if (mounted) {
        setState(() {
          _recentScans.clear();
          _recentScans.addAll(scans);
          // If we have scans, user is no longer first time
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
        debugPrint('Failed to load scans: $e');
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

    if (args != null && args.containsKey('newScan') && args['newScan'] is Map<String, dynamic>) {
      final newScan = args['newScan'] as Map<String, dynamic>;

      if (!_recentScans.any((scan) => scan['id'] == newScan['id']) && mounted) {
        setState(() {
          _recentScans.insert(0, newScan);
          _isFirstTimeUser = false; // User is no longer first time after first scan
        });
        _saveFirstTimeUser();

        // Save the scan persistently
        ScanService().saveScan(newScan);

        // Show success message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showCustomSnackBar(message: 'New scan added successfully!', isError: false);
          }
        });
      }
    }

    // Handle returning from scan screen - refresh scans
    if (args != null && args.containsKey('refreshScans') && args['refreshScans'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRecentScans();
      });
    }
  }

  Future<void> _refreshScans() async {
    HapticFeedback.lightImpact();
    await _loadRecentScans();

    if (mounted) {
      _showCustomSnackBar(message: AppStrings.scansRefreshed, isError: false);
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
      if (imagePath != null) {
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
      });
      await ScanService().deleteScan(id);

      _showCustomSnackBar(message: 'Scan deleted successfully!', isError: false);
    }
  }

  Future<void> _showDeleteConfirmationDialog(String id) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Scan'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this scan? This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteScan(id);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String fullName = args?['fullName']?.toString() ?? AppMetadata.appName;

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
            ...List.generate(8, (index) => _buildFloatingOrb(index)),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: RefreshIndicator(
                    onRefresh: _refreshScans,
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 32),
                          _buildWelcomeSection(fullName),
                          const SizedBox(height: 32),
                          _buildScanButton(),
                          const SizedBox(height: 32),
                          _isLoading
                              ? _buildLoadingSection()
                              : _buildScanContentSection(),
                        ],
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
                Navigator.pushNamed(context, AppRoutes.scan);
                break;
              case 2:
                Navigator.pushNamed(
                  context,
                  AppRoutes.profile,
                  arguments: widget.userData,
                );
                break;
            }
          }
        },
      ),
    );
  }

  Widget _buildLoadingSection() {
    return _buildGlassCard(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading your scans...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingOrb(int index) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Positioned(
          top: (index * 120.0) % MediaQuery.of(context).size.height,
          left: (index * 80.0) % MediaQuery.of(context).size.width,
          child: Transform.scale(
            scale: _scaleAnimation.value * (0.8 + (index * 0.1)),
            child: Container(
              width: 60 + (index * 15.0),
              height: 60 + (index * 15.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (index.isEven
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary)
                        .withOpacity(0.15),
                    (index.isEven
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary)
                        .withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.background.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String fullName) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: _buildGlassCard(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.9),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.9),
                  ],
                ),
              ),
              child: Icon(
                AppIcons.logo,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ).createShader(bounds),
              child: Text(
                '${AppStrings.welcome}, $fullName!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isFirstTimeUser
                  ? AppStrings.getStartedScan
                  : AppStrings.cropHealthInsights,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pushNamed(context, AppRoutes.scan);
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                        ),
                        child: Icon(
                          AppIcons.scan,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        AppStrings.scanPlant,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanContentSection() {
    if (_recentScans.isEmpty) {
      return _buildFirstTimeUserGuide(); // Show guidelines when no scans
    }
    return _buildRecentScansSection();
  }

  Widget _buildFirstTimeUserGuide() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ).createShader(bounds),
            child: Text(
              AppStrings.howToGetStarted,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildGuideStep(
            icon: AppIcons.scan,
            title: '${AppStrings.step} 1. ${AppStrings.scanYourPlant}',
            description: AppStrings.captureClearLeafPhoto,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          _buildGuideStep(
            icon: Icons.analytics_rounded,
            title: '${AppStrings.step} 2. ${AppStrings.getDiagnosis}',
            description: AppStrings.aiAnalyzesSymptoms,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 20),
          _buildGuideStep(
            icon: Icons.medical_services_rounded,
            title: '${AppStrings.step} 3. ${AppStrings.viewRecommendations}',
            description: AppStrings.tailoredTreatmentAdvice,
            color: Theme.of(context).colorScheme.error,
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
            ),
            border: Border.all(color: color.withOpacity(0.5), width: 1),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyScansState() {
    return _buildGlassCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                ],
              ),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.noScansYet,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.scanFirstPlant,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGlassCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ).createShader(bounds),
                child: Text(
                  AppStrings.recentScans,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 22,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    ],
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(context, AppRoutes.history);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        AppStrings.viewAll,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentScans.length,
            itemBuilder: (context, index) {
              final scan = _recentScans[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                child: _buildScanCard(scan, index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScanCard(Map<String, dynamic> scan, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.background.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, AppRoutes.results, arguments: scan);
            },
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: scan['imageUrl']?.toString().startsWith('assets/') == true
                                ? Image.asset(
                              scan['imageUrl']?.toString() ?? 'assets/images/placeholder.jpg',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                                child: Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            )
                                : Image.file(
                              File(scan['imageUrl']?.toString() ?? ''),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                                child: Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        scan['result']?.toString() ?? 'Unknown Disease',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(scan['timestamp']?.toString() ?? ''),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    onPressed: () => _showDeleteConfirmationDialog(scan['id'] as String),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}