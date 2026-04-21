// lib/features/home/screens/home_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/scan_model.dart';
import '../../../core/repositories/scan_repository.dart';
import '../../../core/widgets/app_themes.dart';
import '../../../core/constants/app_routes.dart';
import '../../auth/login/services/guest_service.dart';
import 'components/guest_mode_banner.dart';
import 'species/species_grid_widget.dart';
import 'weather/provider/weather_provider.dart';
import '../../../core/services/translation_service.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const HomeScreen({super.key, this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _recentScans = [];
  bool _isLoading = false;
  bool _hasHandledRouteArgs = false;

  late final AnimationController _fadeController;

  final ScanRepository _scanRepository = ScanRepository();
  final GuestService _guestService = GuestService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _initializeGuestService();
    _loadRecentScans();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleRouteArguments());
  }

  Future<void> _initializeGuestService() async {
    await _guestService.initialize();
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['refreshScans'] == true) {
      _loadRecentScans();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleRouteArguments() {
    if (_hasHandledRouteArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;
    _hasHandledRouteArgs = true;
    if (args.containsKey('newScan')) _handleNewScan(args['newScan'] as Map<String, dynamic>);
    if (args['refreshScans'] == true) _loadRecentScans();
  }

  Future<void> _loadRecentScans() async {
    if (_guestService.isGuestMode) {
      if (mounted) setState(() { _recentScans.clear(); _isLoading = false; });
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final allScans = await _scanRepository.getUserScans(limit: 3);
      if (!mounted) return;
      setState(() {
        _recentScans.clear();
        for (final scan in allScans) {
          _recentScans.add(_convertScanToMap(scan));
        }
        _recentScans.sort((a, b) => (b['scanDate'] as DateTime).compareTo(a['scanDate'] as DateTime));
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading recent scans: $e');
      if (mounted) setState(() => _isLoading = false);
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _convertScanToMap(ScanModel scan) {
    return {
      'id': scan.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'diagnosis': scan.diseaseName,
      'diseaseName': scan.diseaseName,   // ← explicit key for ScanCard
      'severity': scan.severity,
      'confidence': scan.confidence.toString(),
      'treatment': scan.treatments.isNotEmpty ? scan.treatments.join('. ') : '',
      'treatments': scan.treatments,
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
      'createdAt': scan.createdAt,
    };
  }

  void _handleNewScan(Map<String, dynamic> newScan) {
    if (_guestService.isGuestMode) return;
    final id = newScan['id']?.toString();
    if (id == null) return;
    if (_recentScans.any((s) => s['id'] == id)) return;
    final enrichedScan = {...newScan};
    if (!enrichedScan.containsKey('imageBase64') && newScan['imagePath'] != null) {
      final file = File(newScan['imagePath']);
      if (file.existsSync()) {
        try {
          enrichedScan['imageBase64'] = base64Encode(file.readAsBytesSync());
        } catch (_) {}
      }
    }
    setState(() {
      _recentScans.insert(0, enrichedScan);
      if (_recentScans.length > 3) _recentScans.removeLast();
    });
  }

  Future<void> _refreshScans() async {
    HapticFeedback.lightImpact();
    await _loadRecentScans();
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider(
      create: (_) => WeatherProvider(),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshScans,
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // ── Top header with weather ──────────────────────────────
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: _HomeHeader(isDark: isDark),
                  ),
                ),

                // ── Guest banner ─────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: ListenableBuilder(
                      listenable: _guestService,
                      builder: (context, _) => GuestModeBanner(guestService: _guestService),
                    ),
                  ),
                ),

                // ── Recent scans ─────────────────────────────────────────
                if (!_guestService.isGuestMode)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeController,
                        child: _RecentScansSection(
                          isDark: isDark,
                          scans: _recentScans,
                          isLoading: _isLoading,
                          onSeeAll: () => Navigator.pushNamed(context, AppRoutes.history),
                          onScanTap: (scan) => Navigator.pushNamed(
                            context,
                            AppRoutes.results,
                            arguments: {'scanData': {...scan, 'isFromHistory': true, 'skipSave': true}},
                          ),
                          onScanFirst: () => Navigator.pushNamed(context, AppRoutes.scan),
                        ),
                      ),
                    ),
                  ),

                // ── Species / feature cards ──────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                  sliver: const SliverToBoxAdapter(child: SpeciesGridWidget()),
                ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Home header with weather in top bar ──────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  final bool isDark;
  const _HomeHeader({required this.isDark});

  Stream<Map<String, String>> _userStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value({'name': 'User'});
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((d) => {
              'name': d.exists ? ((d.data() as Map)['fullName'] ?? 'User') : 'User',
            });
  }

  @override
  @override
  Widget build(BuildContext context) {
    final t = Provider.of<TranslationService>(context, listen: false);
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return Column(
      children: [
        // ── Top bar: weather left, settings right ──────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              // Weather inline
              Expanded(child: Consumer<WeatherProvider>(
                builder: (_, provider, __) {
                  if (provider.hasData) {
                    final w = provider.currentWeather!;
                    final icon = _weatherEmoji(w.conditionText, w.isDay == 1);
                    return Row(
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${w.temperature.toStringAsFixed(0)}°C  ${w.conditionText}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(CupertinoIcons.location_fill,
                                    size: 10, color: AppColors.primary),
                                const SizedBox(width: 3),
                                Text(
                                  w.cityName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  if (provider.isLoading) {
                    return Row(children: [
                      const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                      const SizedBox(width: 8),
                      Text(t.isUrdu ? 'موسم لوڈ ہو رہا ہے…' : 'Loading weather…',
                          style: TextStyle(fontSize: 12, color: captionColor)),
                    ]);
                  }
                  return Row(children: [
                    Icon(CupertinoIcons.cloud, size: 18, color: captionColor),
                    const SizedBox(width: 6),
                    Text(t.isUrdu ? 'موسم دستیاب نہیں' : 'Weather unavailable',
                        style: TextStyle(fontSize: 12, color: captionColor)),
                  ]);
                },
              )),
              // Settings button
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Icon(CupertinoIcons.settings,
                      size: 17,
                      color: isDark ? AppColors.darkCaption : AppColors.lightCaption),
                ),
              ),
              const SizedBox(width: 8),
              // Report Bug button
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.bugReport),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Icon(CupertinoIcons.ant,
                      size: 17,
                      color: isDark ? AppColors.darkCaption : AppColors.lightCaption),
                ),
              ),
            ],
          ),
        ),

        // ── Greeting ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: StreamBuilder<Map<String, String>>(
            stream: _userStream(),
            builder: (context, snap) {
              final firstName = (snap.data?['name'] ?? 'User').split(' ').first;
              final h = DateTime.now().hour;
              final t = Provider.of<TranslationService>(context, listen: false);
              final greeting = h < 12 ? t.get('good_morning') : h < 17 ? t.get('good_afternoon') : t.get('good_evening');
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      '$greeting, $firstName 👋',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _weatherEmoji(String condition, bool isDay) {
    final c = condition.toLowerCase();
    if (c.contains('sunny') || c.contains('clear')) return isDay ? '☀️' : '🌙';
    if (c.contains('partly') || c.contains('cloudy')) return isDay ? '⛅' : '🌤️';
    if (c.contains('overcast')) return '☁️';
    if (c.contains('rain') || c.contains('drizzle')) return '🌧️';
    if (c.contains('thunder') || c.contains('storm')) return '⛈️';
    if (c.contains('snow') || c.contains('sleet')) return '❄️';
    if (c.contains('fog') || c.contains('mist')) return '🌫️';
    return isDay ? '🌤️' : '🌙';
  }
}

// ── Recent scans section ──────────────────────────────────────────────────────
class _RecentScansSection extends StatelessWidget {
  final bool isDark;
  final List<Map<String, dynamic>> scans;
  final bool isLoading;
  final VoidCallback onSeeAll;
  final void Function(Map<String, dynamic>) onScanTap;
  final VoidCallback onScanFirst;

  const _RecentScansSection({
    required this.isDark,
    required this.scans,
    required this.isLoading,
    required this.onSeeAll,
    required this.onScanTap,
    required this.onScanFirst,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final t = Provider.of<TranslationService>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              t.get('recent_scans'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            if (scans.isNotEmpty)
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  t.get('see_all'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
            ),
          )
        else if (scans.isEmpty)
          _EmptyScansState(isDark: isDark, onScanFirst: onScanFirst)
        else
          ...scans.map((scan) => _ScanCard(
                scan: scan,
                isDark: isDark,
                onTap: () => onScanTap(scan),
              )),
      ],
    );
  }
}

// ── Individual scan card ──────────────────────────────────────────────────────
class _ScanCard extends StatelessWidget {
  final Map<String, dynamic> scan;
  final bool isDark;
  final VoidCallback onTap;

  const _ScanCard({required this.scan, required this.isDark, required this.onTap});

  Widget _buildImage() {
    final imagePath = scan['imagePath'] as String?;
    final imageUrl = scan['imageUrl'] as String?;
    final imageBase64 = scan['imageBase64'] as String?;

    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, width: 64, height: 64,
            errorBuilder: (_, __, ___) => _placeholder());
      }
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(imageUrl, fit: BoxFit.cover, width: 64, height: 64,
          errorBuilder: (_, __, ___) => _placeholder());
    }
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        return Image.memory(base64Decode(imageBase64), fit: BoxFit.cover, width: 64, height: 64,
            errorBuilder: (_, __, ___) => _placeholder());
      } catch (_) {}
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        width: 64, height: 64,
        color: AppColors.primary.withValues(alpha: 0.1),
        child: const Icon(CupertinoIcons.leaf_arrow_circlepath,
            color: AppColors.primary, size: 28),
      );

  @override
  Widget build(BuildContext context) {
    final plantName = scan['plantName']?.toString() ?? 'Unknown Plant';
    final diseaseName = scan['diseaseName']?.toString() ??
        scan['diagnosis']?.toString() ?? 'Healthy';
    final isHealthy = diseaseName.toLowerCase().contains('healthy');
    final diseaseColor = isHealthy ? AppColors.primary : AppColors.error;
    final isAdvanced = scan['isAdvanced'] as bool? ?? false;
    final t = Provider.of<TranslationService>(context, listen: false);

    // Translated display values
    final displayPlant = t.translatePlant(plantName);
    final displayDisease = isHealthy
        ? (t.isUrdu ? 'صحت مند' : 'Healthy')
        : t.translateDisease(diseaseName);
    final severity = scan['severity']?.toString() ?? '';
    final displaySeverity = t.translateSeverity(severity);

    final scanDate = scan['scanDate'];
    String dateStr = '';
    if (scanDate is DateTime) {
      final now = DateTime.now();
      final diff = now.difference(scanDate);
      if (diff.inDays == 0) {
        dateStr = t.isUrdu ? 'آج' : 'Today';
      } else if (diff.inDays == 1) {
        dateStr = t.isUrdu ? 'کل' : 'Yesterday';
      } else if (diff.inDays < 7) {
        dateStr = t.isUrdu ? '${diff.inDays} دن پہلے' : '${diff.inDays}d ago';
      } else {
        dateStr = '${scanDate.day}/${scanDate.month}/${scanDate.year}';
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            // Scan image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImage(),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayPlant,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        isHealthy
                            ? CupertinoIcons.checkmark_seal_fill
                            : CupertinoIcons.exclamationmark_triangle_fill,
                        size: 12,
                        color: diseaseColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          displayDisease,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: diseaseColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(CupertinoIcons.clock,
                            size: 10,
                            color: isDark ? AppColors.darkCaption : AppColors.lightCaption),
                        const SizedBox(width: 3),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
                          ),
                        ),
                        if (isAdvanced) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('AI',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.secondary)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyScansState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onScanFirst;

  const _EmptyScansState({required this.isDark, required this.onScanFirst});

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<TranslationService>(context, listen: false);
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E);
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          // Top green banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Column(
              children: [
                // Animated plant icon with rings
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: const Icon(CupertinoIcons.leaf_arrow_circlepath,
                          size: 22, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  t.isUrdu ? 'ابھی تک کوئی اسکین نہیں' : 'No scans yet',
                  style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800,
                    color: textColor, letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    t.isUrdu
                        ? 'اپنے پودے کی تصویر لیں اور فوری بیماری کی تشخیص حاصل کریں'
                        : 'Take a photo of your plant leaf and get instant disease diagnosis',
                    style: TextStyle(fontSize: 12, color: captionColor, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Steps row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _Step(number: '1', label: t.isUrdu ? 'تصویر لیں' : 'Take photo', isDark: isDark),
                _StepArrow(isDark: isDark),
                _Step(number: '2', label: t.isUrdu ? 'AI تجزیہ' : 'AI analysis', isDark: isDark),
                _StepArrow(isDark: isDark),
                _Step(number: '3', label: t.isUrdu ? 'نتائج دیکھیں' : 'Get results', isDark: isDark),
              ],
            ),
          ),

          // CTA button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onScanFirst,
                icon: const Icon(CupertinoIcons.camera_fill, size: 16),
                label: Text(t.isUrdu ? 'پہلا پودا اسکین کریں' : 'Scan Your First Plant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number, label;
  final bool isDark;
  const _Step({required this.number, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle),
            child: Center(
              child: Text(number,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: captionColor),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StepArrow extends StatelessWidget {
  final bool isDark;
  const _StepArrow({required this.isDark});
  @override
  Widget build(BuildContext context) => Icon(
    CupertinoIcons.chevron_right,
    size: 14,
    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
  );
}





