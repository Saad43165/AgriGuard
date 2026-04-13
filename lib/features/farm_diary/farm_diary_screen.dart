import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/translation_service.dart';
import '../../core/widgets/app_themes.dart';
import '../home/screens/species/plant_species.dart';

class FarmDiaryScreen extends StatefulWidget {
  const FarmDiaryScreen({super.key});

  @override
  State<FarmDiaryScreen> createState() => _FarmDiaryScreenState();
}

class _FarmDiaryScreenState extends State<FarmDiaryScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isLoading = true;
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
    return _crops
        .where((c) =>
            (c['name'] as String? ?? '').toLowerCase().contains(q) ||
            (c['plantType'] as String? ?? '').toLowerCase().contains(q))
        .toList();
  }

  int get _totalScans =>
      _crops.fold(0, (sum, c) => sum + ((c['scanCount'] as int?) ?? 0));

  int get _healthyCrops =>
      _crops.where((c) => (c['healthStatus'] as String? ?? 'healthy') == 'healthy').length;

  int get _diseasedCrops => _crops.length - _healthyCrops;

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
      final ref = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('crops')
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
          content: Text('Failed: $e'),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCropSheet(onAdd: _addCrop),
    );
  }

  void _showCropDetail(Map<String, dynamic> crop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CropDetailSheet(
        crop: crop,
        onDelete: () {
          Navigator.pop(context);
          _deleteCrop(crop['id'] as String);
        },
        onUpdateHealth: (status) {
          _updateCropHealth(crop['id'] as String, status);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);
    final bg = isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F7FF);
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          t.get('farm_diary'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadCrops,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCropSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(t.get('add_crop'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Stats bar
                if (_crops.isNotEmpty) _buildStatsBar(isDark, t),
                // Search bar
                _buildSearchBar(isDark, t, borderColor),
                // List
                Expanded(
                  child: _filteredCrops.isEmpty
                      ? _buildEmptyState(textColor, t)
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
                                onDelete: () =>
                                    _deleteCrop(crop['id'] as String),
                              );
                            },
                          ),
                        ),
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
          _statItem(
            icon: Icons.agriculture_rounded,
            label: t.get('total_crops'),
            value: '${_crops.length}',
            color: AppColors.primary,
            isDark: isDark,
          ),
          _statDivider(isDark),
          _statItem(
            icon: Icons.qr_code_scanner_rounded,
            label: t.get('scan_count'),
            value: '$_totalScans',
            color: AppColors.info,
            isDark: isDark,
          ),
          _statDivider(isDark),
          _statItem(
            icon: Icons.check_circle_outline_rounded,
            label: t.get('healthy_crops'),
            value: '$_healthyCrops',
            color: AppColors.success,
            isDark: isDark,
          ),
          _statDivider(isDark),
          _statItem(
            icon: Icons.warning_amber_rounded,
            label: t.get('diseased_crops'),
            value: '$_diseasedCrops',
            color: AppColors.error,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
          Text(label,
              style: TextStyle(fontSize: 9, color: captionColor),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _statDivider(bool isDark) => Container(
        width: 1,
        height: 36,
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      );

  Widget _buildSearchBar(
      bool isDark, TranslationService t, Color borderColor) {
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
                color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
                fontSize: 14),
            prefixIcon:
                const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded,
                        color: isDark
                            ? AppColors.darkCaption
                            : AppColors.lightCaption,
                        size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, TranslationService t) {
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
            child: const Icon(Icons.agriculture_rounded,
                size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(t.get('no_crops'),
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first crop/field',
            style: TextStyle(
                fontSize: 14,
                color: AppColors.lightCaption),
          ),
        ],
      ),
    );
  }
}

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
            // Colored left border
            Container(
              width: 5,
              height: 110,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
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
                          child: Text(
                            crop['name'] as String? ?? 'Unnamed',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textColor),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isHealthy ? AppColors.success : AppColors.error)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isHealthy
                                      ? AppColors.success
                                      : AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isHealthy ? 'Healthy' : 'Diseased',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isHealthy
                                        ? AppColors.success
                                        : AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.local_florist_rounded,
                            size: 13, color: accentColor),
                        const SizedBox(width: 4),
                        Text(plantType ?? 'Unknown',
                            style: TextStyle(
                                fontSize: 12,
                                color: captionColor,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Icon(Icons.straighten_rounded,
                            size: 13, color: captionColor),
                        const SizedBox(width: 4),
                        Text('${crop['fieldSize'] ?? '-'} acres',
                            style: TextStyle(fontSize: 12, color: captionColor)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.qr_code_scanner_rounded,
                            size: 13, color: captionColor),
                        const SizedBox(width: 4),
                        Text('$scanCount scans',
                            style: TextStyle(fontSize: 12, color: captionColor)),
                        if (lastScan != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.schedule_rounded,
                              size: 13, color: captionColor),
                          const SizedBox(width: 4),
                          Text(lastScan,
                              style:
                                  TextStyle(fontSize: 12, color: captionColor)),
                        ],
                      ],
                    ),
                    if ((crop['notes'] as String? ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        crop['notes'] as String,
                        style: TextStyle(fontSize: 12, color: captionColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right_rounded,
                  color: captionColor, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

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
    _nameCtrl.dispose();
    _sizeCtrl.dispose();
    _notesCtrl.dispose();
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
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85),
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Add Crop / Field',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textColor)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(
                  labelText: 'Crop Name',
                  prefixIcon:
                      Icon(Icons.agriculture_rounded, color: AppColors.primary),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _selectedPlant,
                dropdownColor: cardColor,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Plant Type',
                  prefixIcon: Icon(Icons.local_florist_rounded,
                      color: AppColors.primary),
                ),
                items: AppSpecies.allSpecies
                    .map((s) => DropdownMenuItem(
                          value: s.nameEn,
                          child: Text(s.nameEn),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedPlant = v!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _sizeCtrl,
                style: TextStyle(color: textColor),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Field Size (acres)',
                  prefixIcon:
                      Icon(Icons.straighten_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesCtrl,
                style: TextStyle(color: textColor),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon:
                      Icon(Icons.notes_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Save Crop',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
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
// Crop Detail Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _CropDetailSheet extends StatefulWidget {
  final Map<String, dynamic> crop;
  final VoidCallback onDelete;
  final void Function(String status) onUpdateHealth;

  const _CropDetailSheet({
    required this.crop,
    required this.onDelete,
    required this.onUpdateHealth,
  });

  @override
  State<_CropDetailSheet> createState() => _CropDetailSheetState();
}

class _CropDetailSheetState extends State<_CropDetailSheet> {
  late String _healthStatus;

  @override
  void initState() {
    super.initState();
    _healthStatus =
        widget.crop['healthStatus'] as String? ?? 'healthy';
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
    final textColor =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor =
        isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final t = Provider.of<TranslationService>(context, listen: false);

    final plantType = widget.crop['plantType'] as String?;
    final accentColor = _plantColor(plantType);
    final isHealthy = _healthStatus == 'healthy';

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85),
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
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.agriculture_rounded,
                      color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.crop['name'] as String? ?? 'Unnamed',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor),
                      ),
                      Text(
                        plantType ?? 'Unknown',
                        style: TextStyle(
                            fontSize: 13,
                            color: captionColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Info rows
            _infoRow(
              icon: Icons.straighten_rounded,
              label: t.get('field_size'),
              value: '${widget.crop['fieldSize'] ?? '-'} acres',
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _infoRow(
              icon: Icons.qr_code_scanner_rounded,
              label: t.get('scan_count'),
              value: '${(widget.crop['scanCount'] as int?) ?? 0}',
              isDark: isDark,
            ),
            if ((widget.crop['notes'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              _infoRow(
                icon: Icons.notes_rounded,
                label: t.get('notes'),
                value: widget.crop['notes'] as String,
                isDark: isDark,
              ),
            ],

            const SizedBox(height: 20),
            Divider(color: borderColor),
            const SizedBox(height: 16),

            // Health status toggle
            Text(
              t.get('update_health'),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _healthToggleBtn(
                    label: 'Healthy',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    selected: isHealthy,
                    onTap: () {
                      setState(() => _healthStatus = 'healthy');
                      widget.onUpdateHealth('healthy');
                    },
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _healthToggleBtn(
                    label: 'Diseased',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.error,
                    selected: !isHealthy,
                    onTap: () {
                      setState(() => _healthStatus = 'diseased');
                      widget.onUpdateHealth('diseased');
                    },
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Delete button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onDelete();
                },
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 18),
                label: Text(
                  t.get('delete_crop'),
                  style: const TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
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

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final textColor =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor =
        isDark ? AppColors.darkCaption : AppColors.lightCaption;
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(
                fontSize: 13,
                color: captionColor,
                fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _healthToggleBtn({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
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
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected
                    ? color
                    : (isDark ? AppColors.darkCaption : AppColors.lightCaption),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
