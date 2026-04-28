// lib/features/farm_diary/farm_diary_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/translation_service.dart';
import '../../core/widgets/app_bar.dart';
import '../../core/widgets/app_themes.dart';
import '../home/screens/species/plant_species.dart';
import 'widgets/add_crop_sheet.dart';
import 'widgets/crop_card.dart';
import 'widgets/crop_detail_sheet.dart';

class FarmDiaryScreen extends StatefulWidget {
  const FarmDiaryScreen({super.key});
  @override
  State<FarmDiaryScreen> createState() => _FarmDiaryScreenState();
}

class _FarmDiaryScreenState extends State<FarmDiaryScreen>
    with TickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _crops = [];
  String _searchQuery = '';
  String _sortBy = 'date';
  String _statusFilter = 'all';
  final _searchCtrl = TextEditingController();
  late AnimationController _headerAnimCtrl;
  late Animation<double> _headerAnim;

  @override
  void initState() {
    super.initState();
    _headerAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _headerAnim =
        CurvedAnimation(parent: _headerAnimCtrl, curve: Curves.easeOut);
    _loadCrops();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _headerAnimCtrl.dispose();
    super.dispose();
  }

  String? get _uid => _auth.currentUser?.uid;

  List<Map<String, dynamic>> get _filteredCrops {
    var list = List<Map<String, dynamic>>.from(_crops);
    if (_statusFilter == 'healthy') {
      list = list
          .where((c) =>
      (c['healthStatus'] as String? ?? 'healthy') == 'healthy')
          .toList();
    } else if (_statusFilter == 'diseased') {
      list = list
          .where((c) =>
      (c['healthStatus'] as String? ?? 'healthy') != 'healthy')
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((c) =>
      (c['name'] as String? ?? '').toLowerCase().contains(q) ||
          (c['plantType'] as String? ?? '').toLowerCase().contains(q))
          .toList();
    }
    if (_sortBy == 'name') {
      list.sort(
              (a, b) => (a['name'] as String).compareTo(b['name'] as String));
    } else if (_sortBy == 'size') {
      list.sort((a, b) =>
          (double.tryParse(b['fieldSize'] ?? '0') ?? 0)
              .compareTo(double.tryParse(a['fieldSize'] ?? '0') ?? 0));
    }
    return list;
  }

  int get _healthyCrops => _crops
      .where((c) =>
  (c['healthStatus'] as String? ?? 'healthy') == 'healthy')
      .length;
  int get _diseasedCrops => _crops.length - _healthyCrops;

  double get _totalArea {
    double total = 0;
    for (final c in _crops) {
      total += double.tryParse((c['fieldSize'] as String? ?? '0')) ?? 0;
    }
    return total;
  }

  Future<void> _loadCrops() async {
    if (_uid == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final snap = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('crops')
          .orderBy('createdAt', descending: true)
          .get();
      if (mounted) {
        setState(() {
          _crops =
              snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          _isLoading = false;
        });
        _headerAnimCtrl.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addCrop(Map<String, dynamic> data) async {
    if (_uid == null) return;
    final t = Provider.of<TranslationService>(context, listen: false);
    try {
      final ref = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('crops')
          .add({...data, 'createdAt': FieldValue.serverTimestamp()});
      setState(() => _crops.insert(0, {'id': ref.id, ...data}));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(t.isUrdu ? 'فصل کامیابی سے شامل ہوئی' : 'Crop added successfully'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t.isUrdu ? 'ناکام: $e' : 'Failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  Future<void> _deleteCrop(String id) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('crops')
          .doc(id)
          .delete();
      setState(() => _crops.removeWhere((c) => c['id'] == id));
    } catch (_) {}
  }

  Future<void> _updateCropHealth(String id, String status) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('crops')
          .doc(id)
          .update({'healthStatus': status});
      setState(() {
        final idx = _crops.indexWhere((c) => c['id'] == id);
        if (idx != -1) _crops[idx]['healthStatus'] = status;
      });
    } catch (_) {}
  }

  void _showAddCropSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCropSheet(onAdd: _addCrop),
    );
  }

  void _showCropDetail(Map<String, dynamic> crop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CropDetailSheet(
        crop: crop,
        onDelete: () {
          Navigator.pop(context);
          _deleteCrop(crop['id'] as String);
        },
        onUpdateHealth: (status) =>
            _updateCropHealth(crop['id'] as String, status),
      ),
    );
  }

  void _showSortMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context, listen: false);
    final sheetBg =
    isDark ? const Color(0xFF0F1923) : const Color(0xFFFAFBFC);
    final textColor =
    isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final borderColor = isDark
        ? const Color(0xFF1E3A5F).withValues(alpha: 0.6)
        : const Color(0xFFE2E8F0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t.isUrdu ? 'ترتیب دیں' : 'Sort Crops By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _sortTile(ctx, Icons.schedule_rounded,
                t.isUrdu ? 'تاریخ (نئی پہلے)' : 'Date Created', 'date',
                textColor, borderColor, isDark),
            const SizedBox(height: 8),
            _sortTile(ctx, Icons.sort_by_alpha_rounded,
                t.isUrdu ? 'نام (A-Z)' : 'Name (A–Z)', 'name',
                textColor, borderColor, isDark),
            const SizedBox(height: 8),
            _sortTile(ctx, Icons.straighten_rounded,
                t.isUrdu ? 'رقبہ (بڑا پہلے)' : 'Field Size (Largest)', 'size',
                textColor, borderColor, isDark),
          ],
        ),
      ),
    );
  }

  Widget _sortTile(BuildContext ctx, IconData icon, String label, String value,
      Color textColor, Color borderColor, bool isDark) {
    final isSelected = _sortBy == value;
    final inputBg =
    isDark ? const Color(0xFF111C28) : const Color(0xFFF0F4F8);
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(ctx);
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : inputBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.3)
                : borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isSelected ? AppColors.primary : textColor.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : textColor,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);
    final bg = isDark ? const Color(0xFF080E17) : const Color(0xFFF4F7FB);

    return Scaffold(
      backgroundColor: bg,
      body: _isLoading
          ? _buildLoadingState(isDark)
          : CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Custom Sliver AppBar ──────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: bg,
            elevation: 0,
            automaticallyImplyLeading: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroHeader(isDark, t),
              collapseMode: CollapseMode.parallax,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                color: isDark
                    ? const Color(0xFF1E3A5F).withValues(alpha: 0.4)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _showSortMenu,
                icon: Icon(Icons.tune_rounded,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    size: 20),
                tooltip: t.isUrdu ? 'ترتیب' : 'Sort',
              ),
              IconButton(
                onPressed: _loadCrops,
                icon: Icon(Icons.refresh_rounded,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    size: 20),
                tooltip: t.isUrdu ? 'تازہ کریں' : 'Refresh',
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Stats Bar ─────────────────────────────────────────
          if (_crops.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildStatsBar(isDark, t),
              ),
            ),

          // ── Search Bar ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _buildSearchBar(isDark, t),
            ),
          ),

          // ── Content ───────────────────────────────────────────
          _filteredCrops.isEmpty
              ? SliverFillRemaining(
            child: _buildEmptyState(isDark, t),
          )
              : SliverPadding(
            padding:
            const EdgeInsets.fromLTRB(16, 14, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                  final crop = _filteredCrops[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CropCard(
                      crop: crop,
                      onTap: () => _showCropDetail(crop),
                      onDelete: () =>
                          _deleteCrop(crop['id'] as String),
                    ),
                  );
                },
                childCount: _filteredCrops.length,
              ),
            ),
          ),
        ],
      ),

      // ── FAB ──────────────────────────────────────────────────────────
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
        onPressed: _showAddCropSheet,
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          t.isUrdu ? 'فصل شامل کریں' : 'Add Crop',
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14),
        ),
        extendedPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    final bg = isDark ? const Color(0xFF080E17) : const Color(0xFFF4F7FB);
    return Scaffold(
      backgroundColor: bg,
      body: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF10B981),
          strokeWidth: 2.5,
          strokeCap: StrokeCap.round,
        ),
      ),
    );
  }

  Widget _buildHeroHeader(bool isDark, TranslationService t) {
    final textColor =
    isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final captionColor =
    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final cardBg = isDark ? const Color(0xFF1A2535) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF1E3A5F).withValues(alpha: 0.6)
        : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _headerAnim,
      builder: (context, child) => Opacity(
        opacity: _headerAnim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - _headerAnim.value)),
          child: child,
        ),
      ),
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 20,
          right: 20,
          bottom: 16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                            const Color(0xFF10B981).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.circle,
                                size: 6, color: Color(0xFF10B981)),
                            const SizedBox(width: 5),
                            Text(
                              t.isUrdu ? 'لائیو ٹریکنگ' : 'Live Tracking',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t.isUrdu ? 'کھیت ڈائری' : 'Farm Diary',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.isUrdu
                        ? '${_crops.length} فصلیں • ${_totalArea.toStringAsFixed(1)} ایکڑ'
                        : '${_crops.length} crops • ${_totalArea.toStringAsFixed(1)} acres',
                    style: TextStyle(fontSize: 13, color: captionColor),
                  ),
                ],
              ),
            ),

            // Quick stats mini cards
            if (_crops.isNotEmpty) ...[
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _miniStatCard(
                    '$_healthyCrops',
                    t.isUrdu ? 'صحتمند' : 'Healthy',
                    Icons.check_circle_outline_rounded,
                    const Color(0xFF10B981),
                    cardBg,
                    borderColor,
                  ),
                  const SizedBox(height: 8),
                  _miniStatCard(
                    '$_diseasedCrops',
                    t.isUrdu ? 'بیمار' : 'Diseased',
                    Icons.warning_amber_rounded,
                    const Color(0xFFEF4444),
                    cardBg,
                    borderColor,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniStatCard(String value, String label, IconData icon, Color color,
      Color cardBg, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1)),
              Text(label,
                  style: TextStyle(
                      fontSize: 9,
                      color: color.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(bool isDark, TranslationService t) {
    final cardBg = isDark ? const Color(0xFF1A2535) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF1E3A5F).withValues(alpha: 0.6)
        : const Color(0xFFE2E8F0);
    final textColor =
    isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final captionColor =
    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final filters = [
      ('all', t.isUrdu ? 'سب' : 'All', Icons.grid_view_rounded,
      const Color(0xFF3B82F6), '${_crops.length}'),
      ('healthy', t.isUrdu ? 'صحتمند' : 'Healthy',
      Icons.check_circle_outline_rounded, const Color(0xFF10B981),
      '$_healthyCrops'),
      ('diseased', t.isUrdu ? 'بیمار' : 'Diseased',
      Icons.warning_amber_rounded, const Color(0xFFEF4444),
      '$_diseasedCrops'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: filters.asMap().entries.map((entry) {
          final i = entry.key;
          final f = entry.value;
          final isSelected = _statusFilter == f.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _statusFilter = f.$1);
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? f.$4.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? f.$4.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(f.$3,
                        size: 18,
                        color: isSelected
                            ? f.$4
                            : captionColor.withValues(alpha: 0.6)),
                    const SizedBox(height: 5),
                    Text(
                      f.$5,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? f.$4 : textColor,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f.$2,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? f.$4 : captionColor,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, TranslationService t) {
    final cardBg = isDark ? const Color(0xFF1A2535) : Colors.white;
    final inputBg =
    isDark ? const Color(0xFF111C28) : const Color(0xFFF0F4F8);
    final textColor =
    isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final captionColor =
    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final borderColor = isDark
        ? const Color(0xFF1E3A5F).withValues(alpha: 0.6)
        : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        style: TextStyle(color: textColor, fontSize: 14),
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: t.isUrdu
              ? 'فصل یا پودے کی قسم تلاش کریں...'
              : 'Search crops or species...',
          hintStyle: TextStyle(color: captionColor, fontSize: 13.5),
          prefixIcon: Icon(Icons.search_rounded,
              color: const Color(0xFF10B981).withValues(alpha: 0.8), size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon:
            Icon(Icons.clear_rounded, color: captionColor, size: 18),
            onPressed: () {
              _searchCtrl.clear();
              setState(() => _searchQuery = '');
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, TranslationService t) {
    final textColor =
    isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final captionColor =
    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final cardBg = isDark ? const Color(0xFF1A2535) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF1E3A5F).withValues(alpha: 0.6)
        : const Color(0xFFE2E8F0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.2),
                    const Color(0xFF10B981).withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🌱', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t.isUrdu ? 'ابھی کوئی فصل نہیں' : 'No Crops Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.isUrdu
                  ? 'اپنی پہلی فصل شامل کریں اور ٹریک کریں'
                  : 'Add your first crop field to start tracking',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: captionColor, height: 1.5),
            ),
            const SizedBox(height: 28),

            // Step cards
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _emptyStep(
                    '1',
                    Icons.add_circle_rounded,
                    t.isUrdu ? '"فصل شامل کریں" دبائیں' : 'Tap "Add Crop" button',
                    t.isUrdu
                        ? 'کوئی بھی پودا یا فصل درج کریں'
                        : 'Register any plant or crop species',
                    const Color(0xFF10B981),
                    textColor,
                    captionColor,
                  ),
                  const SizedBox(height: 14),
                  _emptyStep(
                    '2',
                    Icons.local_florist_rounded,
                    t.isUrdu ? 'فصل کا انتخاب کریں' : 'Choose your species',
                    t.isUrdu
                        ? 'موجودہ فہرست سے یا اپنا نام درج کریں'
                        : 'Pick from the list or enter a custom species',
                    const Color(0xFF3B82F6),
                    textColor,
                    captionColor,
                  ),
                  const SizedBox(height: 14),
                  _emptyStep(
                    '3',
                    Icons.monitor_heart_rounded,
                    t.isUrdu ? 'AI سے معلومات حاصل کریں' : 'Get AI-powered insights',
                    t.isUrdu
                        ? 'بیماریاں، ٹپس اور فصل کی مکمل رہنمائی'
                        : 'Disease guides, tips & crop intelligence',
                    const Color(0xFF8B5CF6),
                    textColor,
                    captionColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            GestureDetector(
              onTap: _showAddCropSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      t.isUrdu ? 'پہلی فصل شامل کریں' : 'Add Your First Crop',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
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

  Widget _emptyStep(String number, IconData icon, String title, String desc,
      Color color, Color textColor, Color captionColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  )),
              const SizedBox(height: 2),
              Text(desc,
                  style: TextStyle(
                      fontSize: 11.5, color: captionColor, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}