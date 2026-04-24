import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/app_themes.dart';
import '../../home/screens/species/plant_species.dart';

class AddCropSheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onAdd;
  const AddCropSheet({super.key, required this.onAdd});
  @override
  State<AddCropSheet> createState() => _AddCropSheetState();
}

class _AddCropSheetState extends State<AddCropSheet> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  late String _selectedPlant;
  bool _isSaving = false;
  bool _showPlantPicker = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _selectedPlant = AppSpecies.allSpecies.first.nameEn;
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sizeCtrl.dispose();
    _notesCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  PlantSpecies get _selectedSpecies => AppSpecies.allSpecies.firstWhere(
        (s) => s.nameEn == _selectedPlant,
        orElse: () => AppSpecies.allSpecies.first,
      );

  void _togglePlantPicker() {
    setState(() => _showPlantPicker = !_showPlantPicker);
    if (_showPlantPicker) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
    }
    HapticFeedback.selectionClick();
  }

  void _selectPlant(String name) {
    setState(() {
      _selectedPlant = name;
      _showPlantPicker = false;
    });
    _animCtrl.reverse();
    HapticFeedback.lightImpact();
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
    final t = Provider.of<TranslationService>(context);
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final inputBg = isDark ? const Color(0xFF141B24) : const Color(0xFFF4F7F9);
    final species = _selectedSpecies;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle + Header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: borderColor, borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.2),
                            AppColors.secondary.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.get('add_crop_field'),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                        Text(t.isUrdu ? 'نئی فصل شامل کریں' : 'Register a new crop field',
                            style: TextStyle(fontSize: 12, color: captionColor)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          Divider(color: borderColor, height: 1),

          // ── Scrollable Form Body ───────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Crop Name ──────────────────────────────────────
                    _fieldLabel(Icons.agriculture_rounded, t.get('crop_name'), textColor),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: t.isUrdu ? 'مثال: شمالی کھیت' : 'e.g. North Field',
                        prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded, color: AppColors.primary, size: 20),
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? (t.isUrdu ? 'ضروری ہے' : 'Required') : null,
                    ),

                    const SizedBox(height: 20),

                    // ── Plant Type Picker ──────────────────────────────
                    _fieldLabel(Icons.local_florist_rounded, t.get('plant_type'), textColor),
                    const SizedBox(height: 8),

                    // Selected plant display / toggle button
                    GestureDetector(
                      onTap: _togglePlantPicker,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _showPlantPicker ? AppColors.primary.withValues(alpha: 0.08) : inputBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _showPlantPicker ? AppColors.primary : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: species.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  _speciesEmoji(species.nameEn),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.isUrdu ? species.nameUr : species.nameEn,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                                ),
                                Text(
                                  species.scientificName,
                                  style: TextStyle(fontSize: 11, color: captionColor, fontStyle: FontStyle.italic),
                                ),
                              ],
                            )),
                            AnimatedRotation(
                              turns: _showPlantPicker ? 0.5 : 0,
                              duration: const Duration(milliseconds: 250),
                              child: Icon(Icons.keyboard_arrow_down_rounded,
                                  color: _showPlantPicker ? AppColors.primary : captionColor),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Plant grid picker (animated)
                    SizeTransition(
                      sizeFactor: _fadeAnim,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: AppSpecies.allSpecies.length,
                            itemBuilder: (ctx, i) {
                              final s = AppSpecies.allSpecies[i];
                              final isSelected = s.nameEn == _selectedPlant;
                              return GestureDetector(
                                onTap: () => _selectPlant(s.nameEn),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? s.color.withValues(alpha: 0.18)
                                        : (isDark ? AppColors.darkCard : Colors.white),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? s.color : borderColor,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [BoxShadow(color: s.color.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))]
                                        : [],
                                  ),
                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Text(_speciesEmoji(s.nameEn), style: const TextStyle(fontSize: 22)),
                                    const SizedBox(height: 4),
                                    Text(
                                      t.isUrdu ? s.nameUr : s.nameEn,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? s.color : captionColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ]),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Field Size + Notes Row ────────────────────────
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _fieldLabel(Icons.straighten_rounded, '${t.get('field_size')} (${t.get('acres')})', textColor),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _sizeCtrl,
                            style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '0.0',
                              prefixIcon: const Icon(Icons.straighten_rounded, color: AppColors.primary, size: 18),
                              filled: true,
                              fillColor: inputBg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                            ),
                          ),
                        ]),
                      ),
                    ]),

                    const SizedBox(height: 16),

                    _fieldLabel(Icons.notes_rounded, t.get('notes'), textColor),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesCtrl,
                      style: TextStyle(color: textColor, fontSize: 14),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: t.isUrdu ? 'اضافی نوٹس (اختیاری)' : 'Additional notes (optional)',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 14, top: 14),
                          child: Icon(Icons.notes_rounded, color: AppColors.primary, size: 18),
                        ),
                        prefixIconConstraints: const BoxConstraints(),
                        alignLabelWithHint: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF22C55E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.check_circle_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(t.get('save_crop'),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                              ]),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          t.isUrdu ? 'منسوخ کریں' : 'Cancel',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: captionColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(IconData icon, String label, Color textColor) {
    return Row(children: [
      Icon(icon, size: 14, color: AppColors.primary),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor, letterSpacing: 0.2)),
    ]);
  }

  String _speciesEmoji(String nameEn) {
    const emojis = {
      'Apricot': '🍑',
      'Bean': '🫘',
      'Cherry': '🍒',
      'Corn': '🌽',
      'Fig': '🍈',
      'Grape': '🍇',
      'Loquat': '🍊',
      'Pear': '🍐',
      'Persimmon': '🍅',
      'Tomato': '🍅',
      'Walnut': '🌰',
    };
    return emojis[nameEn] ?? '🌿';
  }
}
