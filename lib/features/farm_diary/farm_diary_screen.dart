import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/translation_service.dart';
import '../../core/widgets/app_bar.dart';
import '../../core/widgets/app_themes.dart';
import '../home/screens/species/plant_species.dart';
import 'services/crop_info_service.dart';
import 'widgets/add_crop_sheet.dart';
import 'widgets/crop_card.dart';
import 'widgets/crop_detail_sheet.dart';

class FarmDiaryScreen extends StatefulWidget {
  const FarmDiaryScreen({super.key});
  @override
  State<FarmDiaryScreen> createState() => _FarmDiaryScreenState();
}

class _FarmDiaryScreenState extends State<FarmDiaryScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  bool _guidanceDismissed = false;
  List<Map<String, dynamic>> _crops = [];
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String? get _uid => _auth.currentUser?.uid;

  List<Map<String, dynamic>> get _filteredCrops {
    if (_searchQuery.isEmpty) return _crops;
    final q = _searchQuery.toLowerCase();
    return _crops.where((c) =>
        (c['name'] as String? ?? '').toLowerCase().contains(q) ||
        (c['plantType'] as String? ?? '').toLowerCase().contains(q)).toList();
  }

  int get _totalScans => _crops.fold(0, (sum, c) => sum + ((c['scanCount'] as int?) ?? 0));
  int get _healthyCrops => _crops.where((c) => (c['healthStatus'] as String? ?? 'healthy') == 'healthy').length;
  int get _diseasedCrops => _crops.length - _healthyCrops;

  double get _totalArea {
    double total = 0;
    for (final c in _crops) {
      final size = double.tryParse((c['fieldSize'] as String? ?? '0')) ?? 0;
      total += size;
    }
    return total;
  }

  Future<void> _loadCrops() async {
    if (_uid == null) { setState(() => _isLoading = false); return; }
    setState(() => _isLoading = true);
    try {
      final snap = await _firestore.collection('users').doc(_uid).collection('crops')
          .orderBy('createdAt', descending: true).get();
      if (mounted) {
        setState(() {
          _crops = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addCrop(Map<String, dynamic> data) async {
    if (_uid == null) return;
    final t = Provider.of<TranslationService>(context, listen: false);
    try {
      final ref = await _firestore.collection('users').doc(_uid).collection('crops')
          .add({...data, 'createdAt': FieldValue.serverTimestamp()});
      setState(() => _crops.insert(0, {'id': ref.id, ...data}));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t.get('add_crop')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t.isUrdu ? 'ناکام: $e' : 'Failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Future<void> _deleteCrop(String id) async {
    if (_uid == null) return;
    try {
      await _firestore.collection('users').doc(_uid).collection('crops').doc(id).delete();
      setState(() => _crops.removeWhere((c) => c['id'] == id));
    } catch (_) {}
  }

  Future<void> _updateCropHealth(String id, String status) async {
    if (_uid == null) return;
    try {
      await _firestore.collection('users').doc(_uid).collection('crops').doc(id)
          .update({'healthStatus': status});
      setState(() {
        final idx = _crops.indexWhere((c) => c['id'] == id);
        if (idx != -1) _crops[idx]['healthStatus'] = status;
      });
    } catch (_) {}
  }

  void _showAddCropSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => AddCropSheet(onAdd: _addCrop),
    );
  }

  void _showCropDetail(Map<String, dynamic> crop) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => CropDetailSheet(
        crop: crop,
        onDelete: () { Navigator.pop(context); _deleteCrop(crop['id'] as String); },
        onUpdateHealth: (status) => _updateCropHealth(crop['id'] as String, status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AgriAppBar(
        title: t.get('farm_diary'),
        actions: [
          AppBarIconButton(
            icon: Icons.refresh_rounded,
            onPressed: _loadCrops,
            tooltip: t.isUrdu ? 'تازہ کریں' : 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCropSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(t.get('add_crop'), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                if (!_guidanceDismissed) _buildGuidanceBanner(isDark, t),
                if (_crops.isNotEmpty) _buildStatsBar(isDark, t),
                _buildSearchBar(isDark, t, borderColor),
                Expanded(
                  child: _filteredCrops.isEmpty
                      ? _buildEmptyState(isDark, t)
                      : RefreshIndicator(
                          onRefresh: _loadCrops,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _filteredCrops.length,
                            itemBuilder: (ctx, i) {
                              final crop = _filteredCrops[i];
                              return CropCard(
                                crop: crop,
                                onTap: () => _showCropDetail(crop),
                                onDelete: () => _deleteCrop(crop['id'] as String),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildGuidanceBanner(bool isDark, TranslationService t) {
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.agriculture_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(t.get('farm_diary_guidance'),
                style: TextStyle(fontSize: 13, color: textColor, height: 1.4)),
          ),
          GestureDetector(
            onTap: () => setState(() => _guidanceDismissed = true),
            child: const Icon(Icons.close_rounded, size: 18, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(bool isDark, TranslationService t) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          _statItem(icon: Icons.agriculture_rounded, label: t.get('total_crops'),
              value: '${_crops.length}', color: AppColors.primary, isDark: isDark),
          _statDivider(isDark),
          _statItem(icon: Icons.straighten_rounded, label: t.get('total_area'),
              value: _totalArea.toStringAsFixed(1), color: AppColors.info, isDark: isDark),
          _statDivider(isDark),
          _statItem(icon: Icons.check_circle_outline_rounded, label: t.get('healthy_crops'),
              value: '$_healthyCrops', color: AppColors.success, isDark: isDark),
          _statDivider(isDark),
          _statItem(icon: Icons.warning_amber_rounded, label: t.get('diseased_crops'),
              value: '$_diseasedCrops', color: AppColors.error, isDark: isDark),
        ],
      ),
    );
  }

  Widget _statItem({required IconData icon, required String label, required String value,
      required Color color, required bool isDark}) {
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
          Text(label, style: TextStyle(fontSize: 9, color: captionColor),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _statDivider(bool isDark) => Container(
      width: 1, height: 36,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder);

  Widget _buildSearchBar(bool isDark, TranslationService t, Color borderColor) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: TextField(
          controller: _searchCtrl,
          style: TextStyle(color: textColor, fontSize: 14),
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: '${t.get('crop_name')}...',
            hintStyle: TextStyle(
                color: isDark ? AppColors.darkCaption : AppColors.lightCaption, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded,
                        color: isDark ? AppColors.darkCaption : AppColors.lightCaption, size: 18),
                    onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); })
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, TranslationService t) {
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final steps = [
      (Icons.add_circle_outline_rounded, t.get('no_crops_guidance_step1')),
      (Icons.local_florist_rounded, t.get('no_crops_guidance_step2')),
      (Icons.monitor_heart_rounded, t.get('no_crops_guidance_step3')),
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.agriculture_rounded, size: 52, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(t.get('no_crops_guidance_title'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: steps.asMap().entries.map((entry) => Padding(
                  padding: EdgeInsets.only(bottom: entry.key < steps.length - 1 ? 14 : 0),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(entry.value.$1, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(entry.value.$2,
                          style: TextStyle(fontSize: 13, color: captionColor, height: 1.4))),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
