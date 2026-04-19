import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/repositories/scan_repository.dart';
import '../../core/models/scan_model.dart';
import '../../core/services/translation_service.dart';
import '../../core/widgets/app_bar.dart';
import '../../core/widgets/app_themes.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ScanRepository _repo = ScanRepository();
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
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Computed stats ──────────────────────────────────────────────────────
  int get _total => _scans.length;

  int get _healthyCount => _scans.where((s) =>
      s.diseaseName.toLowerCase().contains('healthy')).length;

  double get _healthyPct => _total == 0 ? 0 : (_healthyCount / _total * 100);

  int get _thisMonthDiseased {
    final now = DateTime.now();
    return _scans.where((s) =>
        s.scanDate.month == now.month &&
        s.scanDate.year == now.year &&
        !s.diseaseName.toLowerCase().contains('healthy')).length;
  }

  int get _lastMonthDiseased {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    return _scans.where((s) =>
        s.scanDate.month == lastMonth.month &&
        s.scanDate.year == lastMonth.year &&
        !s.diseaseName.toLowerCase().contains('healthy')).length;
  }

  // Disease rate trend compared to last month
  String _diseaseTrend(TranslationService t) {
    if (_lastMonthDiseased == 0 && _thisMonthDiseased == 0) return t.get('trend_same');
    if (_thisMonthDiseased > _lastMonthDiseased) return t.get('trend_up');
    if (_thisMonthDiseased < _lastMonthDiseased) return t.get('trend_down');
    return t.get('trend_same');
  }

  Color _trendColor() {
    if (_thisMonthDiseased > _lastMonthDiseased) return AppColors.error;
    if (_thisMonthDiseased < _lastMonthDiseased) return AppColors.success;
    return AppColors.warning;
  }

  // Scan streak: consecutive days with at least one scan
  int get _scanStreak {
    if (_scans.isEmpty) return 0;
    final days = _scans.map((s) =>
        DateTime(s.scanDate.year, s.scanDate.month, s.scanDate.day)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime check = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
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
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
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
      final key = DateFormat('MMM').format(month);
      map[key] = 0;
    }
    for (final s in _scans) {
      final diff = (now.year - s.scanDate.year) * 12 + now.month - s.scanDate.month;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _scans.isEmpty
              ? _buildEmptyState(textColor, captionColor, cardColor, borderColor, t)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildGuidanceBanner(cardColor, textColor, captionColor, borderColor, t),
                      const SizedBox(height: 16),
                      _buildSummaryRow(cardColor, textColor, captionColor, borderColor, t),
                      const SizedBox(height: 16),
                      _buildHealthAndStreak(cardColor, textColor, captionColor, borderColor, t),
                      const SizedBox(height: 16),
                      _buildTopDiseases(cardColor, textColor, captionColor, borderColor, t),
                      const SizedBox(height: 16),
                      _buildPlantBreakdown(cardColor, textColor, captionColor, borderColor, t),
                      const SizedBox(height: 16),
                      _buildMonthlyActivity(cardColor, textColor, captionColor, borderColor, t),
                      const SizedBox(height: 16),
                      _buildMostAffected(cardColor, textColor, captionColor, borderColor, t),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildGuidanceBanner(Color card, Color text, Color caption, Color border, TranslationService t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(t.get('analytics_guidance'),
                style: TextStyle(fontSize: 13, color: text, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color captionColor, Color card, Color border, TranslationService t) {
    return Center(
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
              child: const Icon(Icons.bar_chart_rounded, size: 52, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(t.get('no_data_yet'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 10),
            Text(t.get('scan_plants_to_see'),
                style: TextStyle(fontSize: 14, color: captionColor), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Text(t.get('analytics_guidance'),
                  style: TextStyle(fontSize: 13, color: captionColor, height: 1.5),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(Color card, Color text, Color caption, Color border, TranslationService t) {
    final items = [
      (t.get('total_scans'), '$_total', Icons.document_scanner_rounded, AppColors.primary),
      (t.get('healthy_pct'), '${_healthyPct.toStringAsFixed(0)}%', Icons.eco_rounded, AppColors.success),
      (t.get('diseased_this_month'), '$_thisMonthDiseased', Icons.warning_rounded, AppColors.warning),
    ];
    return Row(
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < items.length - 1 ? 8 : 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.$3, color: item.$4, size: 22),
                const SizedBox(height: 8),
                Text(item.$2, style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, color: item.$4)),
                const SizedBox(height: 4),
                Text(item.$1, style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: caption)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHealthAndStreak(Color card, Color text, Color caption, Color border, TranslationService t) {
    final trendText = _diseaseTrend(t);
    final trendColor = _trendColor();
    final streak = _scanStreak;

    return Row(
      children: [
        // Health Score with ring
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                Text(t.get('health_score'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: caption)),
                const SizedBox(height: 12),
                SizedBox(
                  width: 72, height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _healthyPct / 100,
                        strokeWidth: 7,
                        backgroundColor: AppColors.error.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _healthyPct >= 70 ? AppColors.success : _healthyPct >= 40 ? AppColors.warning : AppColors.error,
                        ),
                      ),
                      Text('${_healthyPct.toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: text)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Disease Rate Trend
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.get('disease_rate'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: caption)),
                const SizedBox(height: 8),
                Text('$_thisMonthDiseased',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: trendColor)),
                const SizedBox(height: 4),
                Text(trendText,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: trendColor)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Scan Streak
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.get('scan_streak'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: caption)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$streak',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.secondary)),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('🔥', style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
                Text(t.get('days_scanning'),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: caption)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopDiseases(Color card, Color text, Color caption, Color border, TranslationService t) {
    final diseases = _topDiseases;
    if (diseases.isEmpty) return const SizedBox.shrink();
    final maxVal = diseases.values.reduce((a, b) => a > b ? a : b);
    final colors = [AppColors.error, AppColors.warning, AppColors.info, AppColors.secondary, AppColors.primary];

    return _buildCard(
      card: card, border: border,
      title: t.get('top_diseases'), icon: Icons.bug_report_rounded, textColor: text,
      child: Column(
        children: diseases.entries.toList().asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final pct = maxVal == 0 ? 0.0 : e.value / maxVal;
          final color = colors[i % colors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(e.key, style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: text),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text('${e.value}', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                  ],
                ),
                const SizedBox(height: 6),
                LayoutBuilder(builder: (ctx, constraints) {
                  return Stack(children: [
                    Container(
                      height: 10, width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      height: 10,
                      width: constraints.maxWidth * pct,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ]);
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlantBreakdown(Color card, Color text, Color caption, Color border, TranslationService t) {
    final plants = _plantBreakdown;
    if (plants.isEmpty) return const SizedBox.shrink();
    final total = plants.values.fold(0, (a, b) => a + b);

    return _buildCard(
      card: card, border: border,
      title: t.get('plant_health_breakdown'), icon: Icons.local_florist_rounded, textColor: text,
      child: Column(
        children: plants.entries.map((e) {
          final pct = total == 0 ? 0.0 : e.value / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(e.key, style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: text))),
                Text('${(pct * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(width: 8),
                Text('(${e.value})', style: TextStyle(fontSize: 12, color: caption)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyActivity(Color card, Color text, Color caption, Color border, TranslationService t) {
    final monthly = _monthlyActivity;
    if (monthly.isEmpty) return const SizedBox.shrink();
    final maxVal = monthly.values.fold(0, (a, b) => a > b ? a : b);

    return _buildCard(
      card: card, border: border,
      title: t.get('monthly_activity_6'), icon: Icons.calendar_month_rounded, textColor: text,
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: monthly.entries.map((e) {
            final pct = maxVal == 0 ? 0.0 : e.value / maxVal;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${e.value}', style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      height: 80 * pct + 4,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(e.key, style: TextStyle(fontSize: 10, color: caption)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMostAffected(Color card, Color text, Color caption, Color border, TranslationService t) {
    return _buildCard(
      card: card, border: border,
      title: t.get('most_affected_plant'), icon: Icons.warning_amber_rounded, textColor: text,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.eco_rounded, color: AppColors.error, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_mostAffectedPlant, style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: text)),
                const SizedBox(height: 4),
                Text(t.get('most_disease_detections'), style: TextStyle(
                    fontSize: 13, color: caption)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required Color card,
    required Color border,
    required String title,
    required IconData icon,
    required Color textColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
