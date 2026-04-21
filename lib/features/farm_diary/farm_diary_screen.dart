import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/translation_service.dart';
import '../../core/widgets/app_bar.dart';
import '../../core/widgets/app_themes.dart';
import '../home/screens/species/plant_species.dart';
import 'services/crop_info_service.dart';

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
      builder: (_) => _AddCropSheet(onAdd: _addCrop),
    );
  }

  void _showCropDetail(Map<String, dynamic> crop) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _CropDetailSheet(
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
                              return _CropCard(
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

// ─────────────────────────────────────────────────────────────────────────────
// Crop Card
// ─────────────────────────────────────────────────────────────────────────────
class _CropCard extends StatelessWidget {
  final Map<String, dynamic> crop;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  const _CropCard({required this.crop, required this.onDelete, required this.onTap});

  Color _plantColor(String? plantType) {
    final species = AppSpecies.allSpecies.firstWhere(
      (s) => s.nameEn.toLowerCase() == (plantType ?? '').toLowerCase(),
      orElse: () => AppSpecies.allSpecies.first,
    );
    return species.color;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context, listen: false);
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final plantType = crop['plantType'] as String?;
    final accentColor = _plantColor(plantType);
    final isHealthy = (crop['healthStatus'] as String? ?? 'healthy') == 'healthy';
    final scanCount = (crop['scanCount'] as int?) ?? 0;
    final lastScan = crop['lastScanDate'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 5, height: 110,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(crop['name'] as String? ?? (t.isUrdu ? 'بے نام' : 'Unnamed'),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isHealthy ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 7, height: 7,
                                  decoration: BoxDecoration(
                                      color: isHealthy ? AppColors.success : AppColors.error,
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              Text(isHealthy ? t.get('healthy_status') : t.get('diseased_status'),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                      color: isHealthy ? AppColors.success : AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.local_florist_rounded, size: 13, color: accentColor),
                        const SizedBox(width: 4),
                        Text(t.isUrdu
                            ? AppSpecies.allSpecies.firstWhere(
                                (s) => s.nameEn == plantType,
                                orElse: () => AppSpecies.allSpecies.first).nameUr
                            : (plantType ?? (t.isUrdu ? 'نامعلوم' : 'Unknown')),
                            style: TextStyle(fontSize: 12, color: captionColor, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Icon(Icons.straighten_rounded, size: 13, color: captionColor),
                        const SizedBox(width: 4),
                        Text('${crop['fieldSize'] ?? '-'} ${t.get('acres')}',
                            style: TextStyle(fontSize: 12, color: captionColor)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, size: 13, color: captionColor),
                        const SizedBox(width: 4),
                        Text('$scanCount ${t.get('scans')}',
                            style: TextStyle(fontSize: 12,
                                fontWeight: scanCount > 0 ? FontWeight.w700 : FontWeight.w400,
                                color: scanCount > 0 ? AppColors.primary : captionColor)),
                        if (lastScan != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.schedule_rounded, size: 13, color: captionColor),
                          const SizedBox(width: 4),
                          Text('${t.get('last_activity')}: $lastScan',
                              style: TextStyle(fontSize: 12, color: captionColor)),
                        ],
                      ],
                    ),
                    if ((crop['notes'] as String? ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(crop['notes'] as String,
                          style: TextStyle(fontSize: 12, color: captionColor),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right_rounded, color: captionColor, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Crop Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _AddCropSheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onAdd;
  const _AddCropSheet({required this.onAdd});
  @override
  State<_AddCropSheet> createState() => _AddCropSheetState();
}

class _AddCropSheetState extends State<_AddCropSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _selectedPlant = AppSpecies.allSpecies.first.nameEn;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _sizeCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await widget.onAdd({
      'name': _nameCtrl.text.trim(),
      'plantType': _selectedPlant,
      'fieldSize': _sizeCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      'healthStatus': 'healthy',
      'scanCount': 0,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context, listen: false);
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: borderColor),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(t.get('add_crop_field'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: t.get('crop_name'),
                  prefixIcon: const Icon(Icons.agriculture_rounded, color: AppColors.primary),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _selectedPlant,
                dropdownColor: cardColor,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  labelText: t.get('plant_type'),
                  prefixIcon: const Icon(Icons.local_florist_rounded, color: AppColors.primary),
                ),
                items: AppSpecies.allSpecies.map((s) => DropdownMenuItem(
                  value: s.nameEn,
                  child: Text(t.isUrdu ? s.nameUr : s.nameEn),
                )).toList(),
                onChanged: (v) => setState(() => _selectedPlant = v!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _sizeCtrl,
                style: TextStyle(color: textColor),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '${t.get('field_size')} (${t.get('acres')})',
                  prefixIcon: const Icon(Icons.straighten_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesCtrl,
                style: TextStyle(color: textColor),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: t.get('notes'),
                  prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(t.get('save_crop'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Crop Detail Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _CropDetailSheet extends StatefulWidget {
  final Map<String, dynamic> crop;
  final VoidCallback onDelete;
  final void Function(String status) onUpdateHealth;
  const _CropDetailSheet({required this.crop, required this.onDelete, required this.onUpdateHealth});
  @override
  State<_CropDetailSheet> createState() => _CropDetailSheetState();
}

class _CropDetailSheetState extends State<_CropDetailSheet> {
  late String _healthStatus;

  @override
  void initState() {
    super.initState();
    _healthStatus = widget.crop['healthStatus'] as String? ?? 'healthy';
  }

  Color _plantColor(String? plantType) {
    final species = AppSpecies.allSpecies.firstWhere(
      (s) => s.nameEn.toLowerCase() == (plantType ?? '').toLowerCase(),
      orElse: () => AppSpecies.allSpecies.first,
    );
    return species.color;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final t = Provider.of<TranslationService>(context, listen: false);
    final plantType = widget.crop['plantType'] as String?;
    final accentColor = _plantColor(plantType);
    final isHealthy = _healthStatus == 'healthy';
    final scanCount = (widget.crop['scanCount'] as int?) ?? 0;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: borderColor),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.local_florist_rounded, color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.crop['name'] as String? ?? (t.isUrdu ? 'بے نام' : 'Unnamed'),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                      Text(t.isUrdu
                          ? AppSpecies.allSpecies.firstWhere(
                              (s) => s.nameEn == plantType,
                              orElse: () => AppSpecies.allSpecies.first).nameUr
                          : (plantType ?? (t.isUrdu ? 'نامعلوم' : 'Unknown')),
                          style: TextStyle(fontSize: 13, color: captionColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Scan count prominently
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$scanCount', style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      Text(t.get('scan_count'), style: TextStyle(fontSize: 12, color: captionColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _infoRow(icon: Icons.straighten_rounded, label: t.get('field_size'),
                value: '${widget.crop['fieldSize'] ?? '-'} ${t.get('acres')}', isDark: isDark),
            if ((widget.crop['lastScanDate'] as String?) != null) ...[
              const SizedBox(height: 10),
              _infoRow(icon: Icons.schedule_rounded, label: t.get('last_activity'),
                  value: widget.crop['lastScanDate'] as String, isDark: isDark),
            ],
            if ((widget.crop['notes'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              _infoRow(icon: Icons.notes_rounded, label: t.get('notes'),
                  value: widget.crop['notes'] as String, isDark: isDark),
            ],
            const SizedBox(height: 20),
            Divider(color: borderColor),
            const SizedBox(height: 16),
            Text(t.get('update_health'),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _healthToggleBtn(
                  label: t.get('healthy_status'), icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success, selected: isHealthy,
                  onTap: () { setState(() => _healthStatus = 'healthy'); widget.onUpdateHealth('healthy'); },
                  isDark: isDark,
                )),
                const SizedBox(width: 10),
                Expanded(child: _healthToggleBtn(
                  label: t.get('diseased_status'), icon: Icons.warning_amber_rounded,
                  color: AppColors.error, selected: !isHealthy,
                  onTap: () { setState(() => _healthStatus = 'diseased'); widget.onUpdateHealth('diseased'); },
                  isDark: isDark,
                )),
              ],
            ),
            const SizedBox(height: 16),
            // Get Live Crop Info button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _CropInfoSheet(
                      cropName: widget.crop['name'] as String? ?? '',
                      plantType: widget.crop['plantType'] as String? ?? 'default',
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                label: Text(t.isUrdu ? 'فصل کی معلومات اور بیماری گائیڈ' : 'Get Crop Info & Disease Guide'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () { HapticFeedback.mediumImpact(); widget.onDelete(); },
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                label: Text(t.get('delete_crop'),
                    style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String label, required String value, required bool isDark}) {
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontSize: 13, color: captionColor, fontWeight: FontWeight.w600)),
        Expanded(child: Text(value,
            style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
            maxLines: 2, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _healthToggleBtn({required String label, required IconData icon, required Color color,
      required bool selected, required VoidCallback onTap, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? color : (isDark ? AppColors.darkCaption : AppColors.lightCaption)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: selected ? color : (isDark ? AppColors.darkCaption : AppColors.lightCaption),
            )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Crop Info Sheet — fetches live data from Groq AI with offline fallback
// ─────────────────────────────────────────────────────────────────────────────
class _CropInfoSheet extends StatefulWidget {
  final String cropName;
  final String plantType;
  const _CropInfoSheet({required this.cropName, required this.plantType});
  @override
  State<_CropInfoSheet> createState() => _CropInfoSheetState();
}

class _CropInfoSheetState extends State<_CropInfoSheet> {
  Map<String, dynamic>? _info;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInfo();
  }

  Future<void> _fetchInfo() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await CropInfoService.getCropInfo(widget.cropName, widget.plantType);
      if (mounted) setState(() { _info = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = t.isUrdu ? 'معلومات لوڈ نہیں ہوئیں' : 'Failed to load info'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E);
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final t = Provider.of<TranslationService>(context, listen: false);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: border)),
        ),
        child: Column(
          children: [
            // Handle + header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Container(width: 36, height: 4,
                      decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.cropName, style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800, color: textColor)),
                            Row(children: [
                              Text(widget.plantType, style: TextStyle(fontSize: 12, color: captionColor)),
                              if (_info != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _info!['source'] == 'live'
                                        ? AppColors.primary.withValues(alpha: 0.1)
                                        : AppColors.warning.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(
                                      _info!['source'] == 'live' ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                                      size: 10,
                                      color: _info!['source'] == 'live' ? AppColors.primary : AppColors.warning,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _info!['source'] == 'live' ? t.isUrdu ? 'لائیو ڈیٹا' : 'Live Data' : t.isUrdu ? 'آف لائن' : 'Offline',
                                      style: TextStyle(
                                        fontSize: 9, fontWeight: FontWeight.w700,
                                        color: _info!['source'] == 'live' ? AppColors.primary : AppColors.warning,
                                      ),
                                    ),
                                  ]),
                                ),
                              ],
                            ]),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
                        onPressed: _fetchInfo,
                        tooltip: t.isUrdu ? 'تازہ کریں' : 'Refresh',
                      ),
                    ],
                  ),
                  Divider(height: 20, color: border),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                      const SizedBox(height: 12),
                      Text(t.isUrdu ? 'فصل کی معلومات حاصل کی جا رہی ہیں…' : 'Fetching crop information…', style: TextStyle(fontSize: 13, color: captionColor)),
                      const SizedBox(height: 4),
                      Text(t.isUrdu ? 'AI سے جڑ رہے ہیں…' : 'Connecting to AI…', style: TextStyle(fontSize: 11, color: captionColor)),
                    ]))
                  : _error != null
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                          const SizedBox(height: 12),
                          Text(_error!, style: TextStyle(color: captionColor)),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _fetchInfo, child: Text(t.isUrdu ? 'دوبارہ کوشش کریں' : 'Retry')),
                        ]))
                      : _buildInfoContent(scrollCtrl, isDark, textColor, captionColor, border),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoContent(ScrollController ctrl, bool isDark, Color textColor, Color captionColor, Color border) {
    final t = Provider.of<TranslationService>(context, listen: false);
    final info = _info!;
    final diseases = (info['commonDiseases'] as List<dynamic>?) ?? [];
    final tips = (info['tips'] as List<dynamic>?) ?? [];

    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        // Description
        _infoCard(isDark, border, Icons.info_outline_rounded, t.isUrdu ? 'اس فصل کے بارے میں' : 'About This Crop',
            info['description']?.toString() ?? '', textColor, captionColor),
        const SizedBox(height: 12),

        // Growing info grid
        _gridCard(isDark, border, [
          ('🌱', t.isUrdu ? 'موسم' : 'Season', info['growingSeason']?.toString() ?? '-'),
          ('💧', t.isUrdu ? 'پانی' : 'Water', info['waterNeeds']?.toString() ?? '-'),
          ('🌍', t.isUrdu ? 'مٹی' : 'Soil', info['soilType']?.toString() ?? '-'),
          ('⏱️', t.isUrdu ? 'کٹائی' : 'Harvest', info['harvestTime']?.toString() ?? '-'),
          ('📦', t.isUrdu ? 'پیداوار/ایکڑ' : 'Yield/Acre', info['yieldPerAcre']?.toString() ?? '-'),
        ], textColor, captionColor),
        const SizedBox(height: 12),

        // Common diseases
        if (diseases.isNotEmpty) ...[
          Text(t.isUrdu ? 'عام بیماریاں' : 'Common Diseases', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 8),
          ...diseases.map((d) {
            final disease = d as Map<String, dynamic>;
            final severity = disease['severity']?.toString() ?? 'medium';
            final sevColor = severity == 'high' ? AppColors.error
                : severity == 'medium' ? AppColors.warning
                : AppColors.primary;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: sevColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(severity.toUpperCase(), style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800, color: sevColor)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(disease['name']?.toString() ?? '', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: textColor))),
                  ]),
                  const SizedBox(height: 8),
                  _diseaseRow(Icons.visibility_outlined, t.isUrdu ? 'علامات' : 'Symptoms',
                      disease['symptoms']?.toString() ?? '', captionColor),
                  const SizedBox(height: 6),
                  _diseaseRow(Icons.healing_rounded, t.isUrdu ? 'علاج' : 'Treatment',
                      disease['treatment']?.toString() ?? '', AppColors.primary),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
        ],

        // Pest management
        if (info['pestManagement'] != null) ...[
          _infoCard(isDark, border, Icons.bug_report_outlined, t.isUrdu ? 'کیڑوں کا انتظام' : 'Pest Management',
              info['pestManagement'].toString(), textColor, captionColor),
          const SizedBox(height: 12),
        ],

        // Tips
        if (tips.isNotEmpty) ...[
          Text(t.isUrdu ? 'زرعی تجاویز' : 'Farming Tips', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: tips.asMap().entries.map((e) => Padding(
                padding: EdgeInsets.only(bottom: e.key < tips.length - 1 ? 10 : 0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text('${e.key + 1}', style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.value.toString(), style: TextStyle(
                    fontSize: 13, color: textColor, height: 1.4))),
                ]),
              )).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoCard(bool isDark, Color border, IconData icon, String title, String content,
      Color textColor, Color captionColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.primary, size: 15),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]),
          const SizedBox(height: 6),
          Text(content, style: TextStyle(fontSize: 13, color: captionColor, height: 1.5)),
        ],
      ),
    );
  }

  Widget _gridCard(bool isDark, Color border, List<(String, String, String)> items,
      Color textColor, Color captionColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Wrap(
        spacing: 12, runSpacing: 12,
        children: items.map((item) => SizedBox(
          width: (MediaQuery.of(context).size.width - 80) / 2,
          child: Row(children: [
            Text(item.$1, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.$2, style: TextStyle(fontSize: 10, color: captionColor, fontWeight: FontWeight.w600)),
                Text(item.$3, style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w600),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            )),
          ]),
        )).toList(),
      ),
    );
  }

  Widget _diseaseRow(IconData icon, String label, String value, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 6),
      Text('$label: ', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568), height: 1.4))),
    ]);
  }
}



