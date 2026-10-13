// lib/features/farm_diary/widgets/add_crop_sheet.dart

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

class _AddCropSheetState extends State<AddCropSheet>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _customSpeciesCtrl = TextEditingController();
  final _customSpeciesScientificCtrl = TextEditingController();

  late String _selectedPlant;
  bool _isSaving = false;
  bool _showPlantPicker = false;
  bool _isCustomSpecies = false;

  late AnimationController _pickerAnimCtrl;
  late AnimationController _sheetAnimCtrl;
  late Animation<double> _pickerAnim;
  late Animation<double> _sheetAnim;

  // Step tracking for multi-step feel
  int _currentStep = 0; // 0 = plant selection, 1 = field details

  static const List<String> _suggestedCustomCrops = [
    'Wheat', 'Rice', 'Cotton', 'Sugarcane', 'Potato',
    'Onion', 'Garlic', 'Chili', 'Sunflower', 'Mustard',
    'Lentil', 'Chickpea', 'Soybean', 'Groundnut', 'Maize',
    'Barley', 'Sorghum', 'Millet', 'Sesame', 'Turmeric',
  ];

  static const List<String> _suggestedCustomCropsUr = [
    'گندم', 'چاول', 'کپاس', 'گنا', 'آلو',
    'پیاز', 'لہسن', 'مرچ', 'سورج مکھی', 'سرسوں',
    'مسور', 'چنا', 'سویابین', 'مونگ پھلی', 'مکئی',
    'جو', 'جوار', 'باجرا', 'تل', 'ہلدی',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPlant = AppSpecies.allSpecies.first.nameEn;
    _pickerAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _sheetAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _pickerAnim =
        CurvedAnimation(parent: _pickerAnimCtrl, curve: Curves.easeOutBack);
    _sheetAnim =
        CurvedAnimation(parent: _sheetAnimCtrl, curve: Curves.easeOut);
    _sheetAnimCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sizeCtrl.dispose();
    _notesCtrl.dispose();
    _customSpeciesCtrl.dispose();
    _customSpeciesScientificCtrl.dispose();
    _pickerAnimCtrl.dispose();
    _sheetAnimCtrl.dispose();
    super.dispose();
  }

  PlantSpecies get _selectedSpecies => AppSpecies.allSpecies.firstWhere(
        (s) => s.nameEn == _selectedPlant,
    orElse: () => AppSpecies.allSpecies.first,
  );

  void _togglePlantPicker() {
    setState(() => _showPlantPicker = !_showPlantPicker);
    if (_showPlantPicker) {
      _pickerAnimCtrl.forward();
    } else {
      _pickerAnimCtrl.reverse();
    }
    HapticFeedback.selectionClick();
  }

  void _selectPlant(String name) {
    setState(() {
      _selectedPlant = name;
      _isCustomSpecies = name == 'Other';
      _showPlantPicker = false;
    });
    _pickerAnimCtrl.reverse();
    HapticFeedback.lightImpact();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final plantTypeFinal = _isCustomSpecies
        ? _customSpeciesCtrl.text.trim()
        : _selectedPlant;

    final scientificName = _isCustomSpecies
        ? (_customSpeciesScientificCtrl.text.trim().isNotEmpty
        ? _customSpeciesScientificCtrl.text.trim()
        : '')
        : _selectedSpecies.scientificName;

    setState(() => _isSaving = true);
    await widget.onAdd({
      'name': _nameCtrl.text.trim(),
      'plantType': plantTypeFinal,
      'scientificName': scientificName,
      'fieldSize': _sizeCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      'healthStatus': 'healthy',
      'scanCount': 0,
      'isCustomSpecies': _isCustomSpecies,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);

    // Refined color palette
    final sheetBg = isDark ? const Color(0xFF0F1923) : const Color(0xFFFAFBFC);
    final cardBg = isDark ? const Color(0xFF1A2535) : Colors.white;
    final inputBg = isDark ? const Color(0xFF111C28) : const Color(0xFFF0F4F8);
    final textColor = isDark ? AppColors.slate100 : const Color(0xFF0F172A);
    final captionColor = isDark ? AppColors.slate500 : AppColors.slate400;
    final borderColor = isDark ? const Color(0xFF1E3A5F).withValues(alpha: 0.6) : AppColors.slate200;
    final accentGreen = AppColors.emerald;
    final accentBlue = AppColors.blue;

    return AnimatedBuilder(
      animation: _sheetAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - _sheetAnim.value)),
        child: Opacity(opacity: _sheetAnim.value, child: child),
      ),
      child: Container(
        constraints:
        BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.95),
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
              blurRadius: 40,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag Handle ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentGreen.withValues(alpha: 0.2),
                          accentBlue.withValues(alpha: 0.1),
                        ],
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accentGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(Icons.eco_rounded, color: accentGreen, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.get('ui_add_new_crop_field'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.get('ui_register_any_crop_or_plant_species'),
                          style: TextStyle(fontSize: 12.5, color: captionColor),
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.close_rounded,
                          color: captionColor, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(
                color: borderColor.withValues(alpha: 0.5), height: 1, thickness: 1),

            // ── Scrollable Form ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── SECTION 1: Plant/Species Selection ─────────────
                      _sectionHeader(
                        '01',
                        t.get('ui_crop_plant_species'),
                        accentGreen,
                        textColor,
                        captionColor,
                      ),
                      const SizedBox(height: 14),

                      // Species selector trigger
                      GestureDetector(
                        onTap: _togglePlantPicker,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _showPlantPicker
                                ? accentGreen.withValues(alpha: 0.06)
                                : cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _showPlantPicker
                                  ? accentGreen.withValues(alpha: 0.5)
                                  : borderColor,
                              width: _showPlantPicker ? 1.5 : 1,
                            ),
                            boxShadow: [
                              if (!_showPlantPicker)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Emoji/icon area
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: _isCustomSpecies
                                      ? accentBlue.withValues(alpha: 0.12)
                                      : _selectedSpecies.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    _isCustomSpecies
                                        ? '🌱'
                                        : _speciesEmoji(_selectedPlant),
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isCustomSpecies
                                          ? (t.get('ui_custom_species'))
                                          : (t.isUrdu
                                          ? _selectedSpecies.nameUr
                                          : _selectedSpecies.nameEn),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isCustomSpecies
                                          ? (t.get('ui_enter_name_below'))
                                          : _selectedSpecies.scientificName,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: captionColor,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _showPlantPicker
                                      ? accentGreen.withValues(alpha: 0.12)
                                      : inputBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      t.get('ui_change'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _showPlantPicker
                                            ? accentGreen
                                            : captionColor,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    AnimatedRotation(
                                      turns: _showPlantPicker ? 0.5 : 0,
                                      duration:
                                      const Duration(milliseconds: 300),
                                      child: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: _showPlantPicker
                                            ? accentGreen
                                            : captionColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Animated grid picker
                      SizeTransition(
                        sizeFactor: _pickerAnim,
                        child: FadeTransition(
                          opacity: _pickerAnim,
                          child: Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                  Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Known species grid
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                  const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 0.82,
                                  ),
                                  itemCount: AppSpecies.allSpecies.length,
                                  itemBuilder: (ctx, i) {
                                    final s = AppSpecies.allSpecies[i];
                                    final isSelected =
                                        s.nameEn == _selectedPlant &&
                                            !_isCustomSpecies;
                                    return _speciesGridItem(
                                      emoji: _speciesEmoji(s.nameEn),
                                      name: t.isUrdu ? s.nameUr : s.nameEn,
                                      color: s.color,
                                      isSelected: isSelected,
                                      isDark: isDark,
                                      borderColor: borderColor,
                                      captionColor: captionColor,
                                      cardBg: cardBg,
                                      onTap: () {
                                        _selectPlant(s.nameEn);
                                        setState(
                                                () => _isCustomSpecies = false);
                                      },
                                    );
                                  },
                                ),

                                const SizedBox(height: 12),
                                Divider(
                                    color: borderColor.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),

                                // "Other / Custom Species" option
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isCustomSpecies = true;
                                      _selectedPlant = 'Other';
                                      _showPlantPicker = false;
                                    });
                                    _pickerAnimCtrl.reverse();
                                    HapticFeedback.lightImpact();
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                    const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _isCustomSpecies
                                          ? accentBlue.withValues(alpha: 0.1)
                                          : inputBg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _isCustomSpecies
                                            ? accentBlue.withValues(alpha: 0.4)
                                            : borderColor,
                                        width: _isCustomSpecies ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40, height: 40,
                                          decoration: BoxDecoration(
                                            color: accentBlue
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                          child: const Center(
                                              child: Text('🌿',
                                                  style: TextStyle(
                                                      fontSize: 20))),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                t.get('ui_other_custom_species'),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: _isCustomSpecies
                                                      ? accentBlue
                                                      : textColor,
                                                ),
                                              ),
                                              Text(
                                                t.get('ui_add_any_plant_not_listed_above'),
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: captionColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (_isCustomSpecies)
                                          Icon(Icons.check_circle_rounded,
                                              color: accentBlue, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Custom species input fields (shown when "Other" selected)
                      if (_isCustomSpecies) ...[
                        const SizedBox(height: 16),
                        _buildCustomSpeciesFields(
                            isDark, t, textColor, captionColor, inputBg,
                            borderColor, accentBlue),
                      ],

                      const SizedBox(height: 28),

                      // ── SECTION 2: Field Details ────────────────────────
                      _sectionHeader(
                        '02',
                        t.get('ui_field_details'),
                        accentBlue,
                        textColor,
                        captionColor,
                      ),
                      const SizedBox(height: 14),

                      // Crop field name
                      _buildLabel(Icons.drive_file_rename_outline_rounded,
                          t.get('ui_field_name'), textColor),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nameCtrl,
                        hint: t.get('ui_e_g_north_field'),
                        icon: Icons.landscape_rounded,
                        textColor: textColor,
                        inputBg: inputBg,
                        borderColor: borderColor,
                        accentColor: accentGreen,
                        validator: (v) => (v == null || v.isEmpty)
                            ? (t.get('ui_required'))
                            : null,
                      ),

                      const SizedBox(height: 18),

                      // Field size
                      _buildLabel(Icons.straighten_rounded,
                          '${t.get('ui_field_size')} (${t.get('ui_acres_2')})',
                          textColor),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _sizeCtrl,
                        hint: '0.0',
                        icon: Icons.crop_square_rounded,
                        textColor: textColor,
                        inputBg: inputBg,
                        borderColor: borderColor,
                        accentColor: accentGreen,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),

                      const SizedBox(height: 18),

                      // Notes
                      _buildLabel(Icons.sticky_note_2_rounded,
                          t.get('ui_notes_optional'),
                          textColor),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        style: TextStyle(
                            color: textColor, fontSize: 14, height: 1.5),
                        decoration: InputDecoration(
                          hintText: t.get('ui_any_special_notes_about_this_field'),
                          hintStyle:
                          TextStyle(color: captionColor, fontSize: 13),
                          prefixIcon: Padding(
                            padding:
                            const EdgeInsetsDirectional.only(start: 16, top: 14),
                            child: Icon(Icons.notes_rounded,
                                color: accentGreen.withValues(alpha: 0.8),
                                size: 18),
                          ),
                          prefixIconConstraints: const BoxConstraints(),
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: inputBg,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: accentGreen.withValues(alpha: 0.7),
                                width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Save Button ────────────────────────────────────
                      _buildSaveButton(t, accentGreen),
                      const SizedBox(height: 10),

                      // Cancel
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            t.get('ui_cancel_2'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: captionColor,
                            ),
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
      ),
    );
  }

  Widget _buildCustomSpeciesFields(
      bool isDark,
      TranslationService t,
      Color textColor,
      Color captionColor,
      Color inputBg,
      Color borderColor,
      Color accentBlue,
      ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline_rounded,
                  size: 15, color: accentBlue),
              const SizedBox(width: 6),
              Text(
                t.get('ui_custom_species_details'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: accentBlue,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Species/crop name field
          Text(
            t.get('ui_species_crop_name'),
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: textColor),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _customSpeciesCtrl,
            style:
            TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText:
              t.get('ui_e_g_wheat_rose_turmeric'),
              hintStyle: TextStyle(color: captionColor, fontSize: 13),
              prefixIcon: Icon(Icons.eco_rounded,
                  color: accentBlue, size: 18),
              filled: true,
              fillColor: inputBg,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                BorderSide(color: accentBlue.withValues(alpha: 0.7), width: 1.5),
              ),
            ),
            validator: (v) => (_isCustomSpecies && (v == null || v.isEmpty))
                ? (t.get('ui_required'))
                : null,
          ),

          const SizedBox(height: 12),

          // Scientific name (optional)
          Text(
            t.get('ui_scientific_name_optional'),
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: textColor),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _customSpeciesScientificCtrl,
            style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontStyle: FontStyle.italic),
            decoration: InputDecoration(
              hintText: t.get('ui_e_g_triticum_aestivum'),
              hintStyle: TextStyle(
                  color: captionColor,
                  fontSize: 12,
                  fontStyle: FontStyle.italic),
              prefixIcon: Icon(Icons.science_rounded,
                  color: captionColor, size: 16),
              filled: true,
              fillColor: inputBg,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                BorderSide(color: accentBlue.withValues(alpha: 0.5)),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Quick suggestions
          Text(
            t.get('ui_quick_suggestions'),
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: captionColor),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: (t.isUrdu
                ? _suggestedCustomCropsUr
                : _suggestedCustomCrops)
                .map((crop) => GestureDetector(
              onTap: () {
                _customSpeciesCtrl.text = crop;
                HapticFeedback.selectionClick();
                setState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: _customSpeciesCtrl.text == crop
                      ? accentBlue.withValues(alpha: 0.15)
                      : inputBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _customSpeciesCtrl.text == crop
                        ? accentBlue.withValues(alpha: 0.5)
                        : borderColor,
                  ),
                ),
                child: Text(
                  crop,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _customSpeciesCtrl.text == crop
                        ? accentBlue
                        : captionColor,
                  ),
                ),
              ),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String number, String title, Color color,
      Color textColor, Color captionColor) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _speciesGridItem({
    required String emoji,
    required String name,
    required Color color,
    required bool isSelected,
    required bool isDark,
    required Color borderColor,
    required Color captionColor,
    required Color cardBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.6) : borderColor,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 5),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : captionColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(IconData icon, String label, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.primary.withValues(alpha: 0.8)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color textColor,
    required Color inputBg,
    required Color borderColor,
    required Color accentColor,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(
          color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: borderColor.withValues(alpha: 1.8),
            fontSize: 13,
            fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon,
            color: accentColor.withValues(alpha: 0.7), size: 18),
        filled: true,
        fillColor: inputBg,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
          BorderSide(color: accentColor.withValues(alpha: 0.7), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildSaveButton(TranslationService t, Color accentGreen) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentGreen, AppColors.emeraldDark],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accentGreen.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: _isSaving
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2.5),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 20),
            const SizedBox(width: 10),
            Text(
              t.get('ui_save_crop_field'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _speciesEmoji(String nameEn) {
    const emojis = {
      'Apple': '🍎',
      'Apricot': '🍑',
      'Bean': '🫘',
      'Cherry': '🍒',
      'Corn': '🌽',
      'Fig': '🍈',
      'Grape': '🍇',
      'Loquat': '🍊',
      'Peach': '🍑',
      'Pear': '🍐',
      'Persimmon': '🍅',
      'Potato': '🥔',
      'Strawberry': '🍓',
      'Tomato': '🍅',
      'Walnut': '🌰',
    };
    return emojis[nameEn] ?? '🌿';
  }
}