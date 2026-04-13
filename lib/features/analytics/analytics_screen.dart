import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/repositories/scan_repository.dart';
import '../../core/models/scan_model.dart';
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
    final bg = isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F7FF);
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
        ),
        title: Text('Analytics', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _scans.isEmpty
              ? _buildEmptyState(textColor, captionColor)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryRow(cardColor, textColor, captionColor, borderColor),
                      const SizedBox(height: 20),
                      _buildTopDiseases(cardColor, textColor, captionColor, borderColor),
                      const SizedBox(height: 20),
                      _buildPlantBreakdown(cardColor, textColor, captionColor, borderColor),
                      const SizedBox(height: 20),
                      _buildMonthlyActivity(cardColor, textColor, captionColor, borderColor),
                      const SizedBox(height: 20),
                      _buildMostAffected(cardColor, textColor, captionColor, borderColor),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color captionColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bar_chart_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text('No data yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 8),
          Text('Scan some plants to see analytics', style: TextStyle(fontSize: 14, color: captionColor)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(Color card, Color text, Color caption, Color border) {
    final items = [
      ('Total Scans', '$_total', Icons.document_scanner_rounded, AppColors.primary),
      ('Healthy', '${_healthyPct.toStringAsFixed(0)}%', Icons.eco_rounded, AppColors.success),
      ('Diseased\nThis Month', '$_thisMonthDiseased', Icons.warning_rounded, AppColors.warning),
    ];
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: item == items.last ? 0 : 8),
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

  Widget _buildTopDiseases(Color card, Color text, Color caption, Color border) {
    final diseases = _topDiseases;
    if (diseases.isEmpty) return const SizedBox.shrink();
    final maxVal = diseases.values.reduce((a, b) => a > b ? a : b);
    final colors = [AppColors.error, AppColors.warning, AppColors.info, AppColors.secondary, AppColors.primary];

    return _buildCard(
      card: card, border: border,
      title: 'Top Diseases', icon: Icons.bug_report_rounded, textColor: text,
      child: Column(
        children: diseases.entries.toList().asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final pct = maxVal == 0 ? 0.0 : e.value / maxVal;
          final color = colors[i % colors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
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
                      height: 8, width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      height: 8,
                      width: constraints.maxWidth * pct,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
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

  Widget _buildPlantBreakdown(Color card, Color text, Color caption, Color border) {
    final plants = _plantBreakdown;
    if (plants.isEmpty) return const SizedBox.shrink();
    final total = plants.values.fold(0, (a, b) => a + b);

    return _buildCard(
      card: card, border: border,
      title: 'Plant Health Breakdown', icon: Icons.local_florist_rounded, textColor: text,
      child: Column(
        children: plants.entries.map((e) {
          final pct = total == 0 ? 0.0 : e.value / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(e.key, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: text))),
                Text('${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(width: 8),
                Text('(${e.value})', style: TextStyle(fontSize: 12, color: caption)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyActivity(Color card, Color text, Color caption, Color border) {
    final monthly = _monthlyActivity;
    if (monthly.isEmpty) return const SizedBox.shrink();
    final maxVal = monthly.values.fold(0, (a, b) => a > b ? a : b);

    return _buildCard(
      card: card, border: border,
      title: 'Monthly Activity (Last 6 Months)', icon: Icons.calendar_month_rounded, textColor: text,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: monthly.entries.map((e) {
          final pct = maxVal == 0 ? 0.0 : e.value / maxVal;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  Text('${e.value}', style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    height: 60 * pct + 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
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
    );
  }

  Widget _buildMostAffected(Color card, Color text, Color caption, Color border) {
    return _buildCard(
      card: card, border: border,
      title: 'Most Affected Plant', icon: Icons.warning_amber_rounded, textColor: text,
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
                Text('Most disease detections', style: TextStyle(
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
