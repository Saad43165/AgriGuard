import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/repositories/scan_repository.dart';
import '../../core/models/scan_model.dart';
import '../../core/services/translation_service.dart';
import '../../core/widgets/app_bar.dart';
import '../../core/widgets/app_themes.dart';

// ── Section widgets ──────────────────────────────────────────────────────────
import 'widgets/analytics_guidance_banner.dart';
import 'widgets/analytics_summary_cards.dart';
import 'widgets/analytics_health_streak.dart';
import 'widgets/analytics_top_diseases.dart';
import 'widgets/analytics_plant_breakdown.dart';
import 'widgets/analytics_monthly_activity.dart';
import 'widgets/analytics_most_affected.dart';
import 'widgets/analytics_empty_state.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _repo = ScanRepository();
  bool _isLoading = true;
  List<ScanModel> _scans = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final scans = await _repo.getUserScans(limit: 500);
      if (mounted) setState(() { _scans = scans; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Computed properties ──────────────────────────────────────────────────

  int get _total => _scans.length;

  int get _healthyCount =>
      _scans.where((s) => s.diseaseName.toLowerCase().contains('healthy')).length;

  double get _healthyPct =>
      _total == 0 ? 0 : (_healthyCount / _total * 100);

  int get _thisMonthDiseased {
    final now = DateTime.now();
    return _scans.where((s) =>
        s.scanDate.month == now.month &&
        s.scanDate.year == now.year &&
        !s.diseaseName.toLowerCase().contains('healthy')).length;
  }

  int get _lastMonthDiseased {
    final now = DateTime.now();
    final last = DateTime(now.year, now.month - 1);
    return _scans.where((s) =>
        s.scanDate.month == last.month &&
        s.scanDate.year == last.year &&
        !s.diseaseName.toLowerCase().contains('healthy')).length;
  }

  int get _scanStreak {
    if (_scans.isEmpty) return 0;
    final days = _scans
        .map((s) => DateTime(s.scanDate.year, s.scanDate.month, s.scanDate.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime check = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    for (final day in days) {
      if (day == check) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else if (day.isBefore(check)) {
        break;
      }
    }
    return streak;
  }

  Map<String, int> get _topDiseases {
    final map = <String, int>{};
    for (final s in _scans) {
      if (!s.diseaseName.toLowerCase().contains('healthy')) {
        map[s.diseaseName] = (map[s.diseaseName] ?? 0) + 1;
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(5));
  }

  Map<String, int> get _plantBreakdown {
    final map = <String, int>{};
    for (final s in _scans) {
      map[s.plantName] = (map[s.plantName] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> get _monthlyActivity {
    final map = <String, int>{};
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      map[DateFormat('MMM').format(month)] = 0;
    }
    for (final s in _scans) {
      final diff =
          (now.year - s.scanDate.year) * 12 + now.month - s.scanDate.month;
      if (diff >= 0 && diff < 6) {
        final key = DateFormat('MMM').format(s.scanDate);
        map[key] = (map[key] ?? 0) + 1;
      }
    }
    return map;
  }

  String get _mostAffectedPlant {
    final map = <String, int>{};
    for (final s in _scans) {
      if (!s.diseaseName.toLowerCase().contains('healthy')) {
        map[s.plantName] = (map[s.plantName] ?? 0) + 1;
      }
    }
    if (map.isEmpty) return 'None';
    return map.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg         = isDark ? AppColors.darkBg        : AppColors.lightBg;
    final cardColor  = isDark ? AppColors.darkCard      : AppColors.lightCard;
    final textColor  = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final borderColor  = isDark ? AppColors.darkBorder  : AppColors.lightBorder;
    final t = Provider.of<TranslationService>(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AgriAppBar(
        title: t.get('analytics_title'),
        actions: [
          AppBarIconButton(
            icon: Icons.refresh_rounded,
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _scans.isEmpty
              ? AnalyticsEmptyState(
                  textColor: textColor,
                  captionColor: captionColor,
                  card: cardColor,
                  border: borderColor,
                  t: t,
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    children: [
                      AnalyticsGuidanceBanner(text: textColor, t: t),
                      const SizedBox(height: 16),

                      AnalyticsSummaryCards(
                        total: _total,
                        healthyPct: _healthyPct,
                        diseasedThisMonth: _thisMonthDiseased,
                        card: cardColor,
                        border: borderColor,
                        text: textColor,
                        caption: captionColor,
                        t: t,
                      ),
                      const SizedBox(height: 16),

                      AnalyticsHealthStreak(
                        healthyPct: _healthyPct,
                        thisMonthDiseased: _thisMonthDiseased,
                        lastMonthDiseased: _lastMonthDiseased,
                        scanStreak: _scanStreak,
                        card: cardColor,
                        border: borderColor,
                        text: textColor,
                        caption: captionColor,
                        t: t,
                      ),
                      const SizedBox(height: 16),

                      AnalyticsTopDiseases(
                        diseases: _topDiseases,
                        card: cardColor,
                        border: borderColor,
                        text: textColor,
                        caption: captionColor,
                        t: t,
                      ),
                      const SizedBox(height: 16),

                      AnalyticsPlantBreakdown(
                        plants: _plantBreakdown,
                        card: cardColor,
                        border: borderColor,
                        text: textColor,
                        caption: captionColor,
                        t: t,
                      ),
                      const SizedBox(height: 16),

                      AnalyticsMonthlyActivity(
                        monthly: _monthlyActivity,
                        card: cardColor,
                        border: borderColor,
                        text: textColor,
                        caption: captionColor,
                        t: t,
                      ),
                      const SizedBox(height: 16),

                      AnalyticsMostAffected(
                        mostAffectedPlant: _mostAffectedPlant,
                        card: cardColor,
                        border: borderColor,
                        text: textColor,
                        caption: captionColor,
                        t: t,
                      ),
                    ],
                  ),
                ),
    );
  }
}