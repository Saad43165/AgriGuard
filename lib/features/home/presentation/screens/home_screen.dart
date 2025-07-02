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
        final Map<String, dynamic> scan = Map<String, dynamic>.from(
          jsonDecode(scanJson) as Map,
        );
        scans.add(scan);
      } catch (e) {
        debugPrint('Error parsing scan: $e');
      }
    }
    return scans;
  }

  Future<void> saveScan(Map<String, dynamic> scan) async {
    final prefs = await SharedPreferences.getInstance();
    final scansJson = prefs.getStringList('recent_scans') ?? [];

    scansJson.insert(0, jsonEncode(scan));

    if (scansJson.length > 10) {
      scansJson.removeRange(10, scansJson.length);
    }

    await prefs.setStringList('recent_scans', scansJson);
  }

  Future<void> deleteScan(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final scansJson = prefs.getStringList('recent_scans') ?? [];
    final updatedScans =
    scansJson.where((json) {
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
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (args.containsKey('newScan') &&
              args['newScan'] is Map<String, dynamic>) {
            final newScan = args['newScan'] as Map<String, dynamic>;
            if (!_recentScans.any((scan) => scan['id'] == newScan['id'])) {
              setState(() {
                _recentScans.insert(0, newScan);
                _isFirstTimeUser = false;
              });
              _saveFirstTimeUser();
              _showCustomSnackBar(
                message: 'New scan added successfully!',
                isError: false,
              );
            }
          }

          if (args.containsKey('refreshScans') &&
              args['refreshScans'] == true) {
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
      _showCustomSnackBar(
        message: 'Scans refreshed successfully!',
        isError: false,
      );
    }
  }

  void _showCustomSnackBar({required String message, required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
              isError
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

      await ScanService().deleteScan(id);
      _saveFirstTimeUser();

      if (mounted) {
        _showCustomSnackBar(
          message: 'Scan deleted successfully!',
          isError: false,
        );
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog(String id) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Scan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete this scan? This action cannot be undone.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
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
    final String fullName = args?['fullName']?.toString() ?? 'User';

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
                            _buildWelcomeSection(fullName),
                            const SizedBox(height: 32),
                            _buildScanButton(),
                            const SizedBox(height: 32),
                            _isLoading
                                ? _buildLoadingSection()
                                : _buildScanContentSection(),
                            const SizedBox(height: 16), // Extra space at bottom
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
                Navigator.pushNamed(context, '/scan');
                break;
              case 2:
                Navigator.pushNamed(
                  context,
                  '/profile',
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
          mainAxisSize: MainAxisSize.min,
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
          mainAxisSize: MainAxisSize.min,
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
                Icons.eco_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.onPrimary,
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
                'Welcome, $fullName!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isFirstTimeUser
                  ? 'Get started by scanning your first plant!'
                  : 'Your crop health insights await you.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
                  Navigator.pushNamed(context, '/scan');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Scan Plant',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_recentScans.isEmpty) _buildFirstTimeUserGuide(),
        if (_recentScans.isNotEmpty) _buildRecentScansSection(),
      ],
    );
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
              'How to Get Started',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildGuideStep(
            icon: Icons.camera_alt_rounded,
            title: 'Step 1. Scan Your Plant',
            description: 'Capture a clear photo of the leaf showing symptoms',
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          _buildGuideStep(
            icon: Icons.analytics_rounded,
            title: 'Step 2. Get Diagnosis',
            description: 'Our AI analyzes the symptoms and identifies the disease',
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 20),
          _buildGuideStep(
            icon: Icons.medical_services_rounded,
            title: 'Step 3. View Recommendations',
            description: 'Receive tailored treatment advice for your plant',
            color: Theme.of(context).colorScheme.tertiary ?? Theme.of(context).colorScheme.error,
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
            ),
            border: Border.all(color: color.withOpacity(0.5), width: 1),
          ),
          child: Icon(icon, color: color, size: 20),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
                  'Recent Scans',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                    onTap: () => _showAllScansDialog(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'View All',
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

  Future<void> _showAllScansDialog() async {
    HapticFeedback.lightImpact();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(

          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(16),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface.withOpacity(0.9),
                  Theme.of(context).colorScheme.surface.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'All Recent Scans',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildAllScansList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllScansList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _recentScans.length,
      itemBuilder: (context, index) {
        final scan = _recentScans[index];
        return Dismissible(
          key: Key(scan['id']?.toString() ?? index.toString()),
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.error.withOpacity(0.3),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Icon(
              Icons.delete_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          confirmDismiss: (direction) async {
            HapticFeedback.mediumImpact();
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Delete Scan'),
                content: const Text(
                  'Are you sure you want to delete this scan?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            _deleteScan(scan['id']?.toString() ?? '');
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.02),
                ],
              ),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: scan['imageUrl'] != null
                      ? Image.file(
                    File(scan['imageUrl']),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.local_florist_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                      : Icon(
                    Icons.local_florist_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              title: Text(
                scan['diagnosis'] ?? 'Unknown Disease',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                scan['timestamp'] ?? 'Unknown Date',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                onPressed: () => _showScanOptionsBottomSheet(scan),
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, '/results', arguments: scan);
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showScanOptionsBottomSheet(Map<String, dynamic> scan) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(1),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.visibility_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/results', arguments: scan);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.share_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: const Text('Share Results'),
                onTap: () {
                  Navigator.pop(context);
                  _shareResults(scan);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('Delete Scan'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(scan['id']?.toString() ?? '');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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

      // Note: You would need to add share_plus package to pubspec.yaml
      // and import 'package:share_plus/share_plus.dart';
      // Share.share(shareText);

      // For now, we'll just show the text in a dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share Results'),
          content: SingleChildScrollView(child: Text(shareText)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar(message: 'Failed to share results', isError: true);
      }
    }
  }

  Widget _buildScanCard(Map<String, dynamic> scan, int index) {
    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
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
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/results', arguments: scan);
                },
                onLongPress: () => _showScanOptionsBottomSheet(scan),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: scan['imageUrl'] != null
                                ? Image.file(
                              File(scan['imageUrl']),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(
                                  Icons.local_florist_rounded,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            )
                                : Center(
                              child: Icon(
                                Icons.local_florist_rounded,
                                size: 32,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              scan['diagnosis'] ?? 'Unknown Disease',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              scan['timestamp'] ?? 'Unknown Date',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            if (scan['confidence'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: _getConfidenceColor(scan['confidence']).withOpacity(0.2),
                                  ),
                                  child: Text(
                                    '${scan['confidence']}% confidence',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _getConfidenceColor(scan['confidence']),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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

  Color _getConfidenceColor(dynamic confidence) {
    final double conf = double.tryParse(confidence.toString()) ?? 0;
    if (conf >= 80) {
      return Colors.green;
    } else if (conf >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}