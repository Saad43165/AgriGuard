import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/widgets/app_themes.dart';
import 'plant_species.dart';

/// Feature action cards — like PictureThis home screen
/// Shows "Diagnose Plant" and "Identify Plant" as large tappable cards
/// with plant images on the right side
class SpeciesGridWidget extends StatelessWidget {
  const SpeciesGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            t.isUrdu ? 'معاون پودے' : 'Supported Plants',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal scrollable species chips
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: AppSpecies.allSpecies.length,
              itemBuilder: (context, index) {
                final species = AppSpecies.allSpecies[index];
                return Padding(
                  padding: EdgeInsets.only(right: index < AppSpecies.allSpecies.length - 1 ? 8 : 0),
                  child: _SpeciesChip(species: species, isDark: isDark),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Feature cards with custom images
          _FeatureCard(
            title: t.isUrdu ? 'تشخیص' : 'Diagnose',
            subtitle: t.isUrdu ? 'آف لائن' : 'Offline',
            customIconPath: 'assets/diag.png',
            imagePath: 'assets/diag.png',
            isDark: isDark,
            onTap: () => Navigator.pushNamed(context, '/capture'),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            title: t.isUrdu ? 'ایڈوانسڈ اسکین' : 'Advance Scan',
            subtitle: t.isUrdu ? 'انٹرنیٹ درکار' : 'Internet Required',
            customIconPath: 'assets/adv.png',
            imagePath: 'assets/adv.png',
            isDark: isDark,
            onTap: () => Navigator.pushNamed(context, '/capture',
                arguments: {'startAdvanced': true}),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            title: t.isUrdu ? 'فارم ڈائری' : 'Farm Diary',
            subtitle: t.isUrdu ? 'اپنی فصلیں ٹریک کریں' : 'Track Your Crops',
            customIconPath: 'assets/farm.png',
            imagePath: 'assets/farm.png',
            isDark: isDark,
            onTap: () => Navigator.pushNamed(context, '/farm-diary'),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            title: t.isUrdu ? 'تجزیات' : 'Analytics',
            subtitle: t.isUrdu ? 'آف لائن' : 'Offline',
            customIconPath: 'assets/analytics.png',
            imagePath: 'assets/analytics.png',
            isDark: isDark,
            onTap: () => Navigator.pushNamed(context, '/analytics'),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            title: t.isUrdu ? 'بیماری لائبریری' : 'Disease Library',
            subtitle: t.isUrdu ? '38 بیماریاں' : '38 Diseases & Plants',
            customIconPath: 'assets/library.png',
            imagePath: 'assets/library.png',
            isDark: isDark,
            onTap: () => Navigator.pushNamed(context, '/disease-library'),
          ),
        ],
      ),
    );
  }
}

// ── Species chip — small pill ─────────────────────────────────────────────────
class _SpeciesChip extends StatelessWidget {
  final PlantSpecies species;
  final bool isDark;
  const _SpeciesChip({required this.species, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<TranslationService>(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showSpeciesSheet(context, species, t);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16, height: 16,
              child: Image.asset(
                species.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.eco_rounded, size: 14, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              species.getName(t.isUrdu),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeciesSheet(BuildContext context, PlantSpecies species, TranslationService t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (ctx, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(species.imagePath, fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.eco_rounded, color: AppColors.primary, size: 32)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('PLANT', style: TextStyle(
                                    fontSize: 9, fontWeight: FontWeight.w800,
                                    color: AppColors.primary, letterSpacing: 1,
                                  )),
                                ),
                                const SizedBox(height: 6),
                                Text(species.getName(t.isUrdu), style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E),
                                )),
                                Text(species.scientificName, style: TextStyle(
                                  fontSize: 12, fontStyle: FontStyle.italic,
                                  color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _sheetSection(context, Icons.info_outline_rounded, 'About', species.getDescription(t.isUrdu), isDark),
                      const SizedBox(height: 12),
                      _sheetSection(context, Icons.wb_sunny_rounded, 'Growth', species.getGrowthInfo(t.isUrdu), isDark),
                      const SizedBox(height: 12),
                      _sheetSection(context, Icons.bug_report_rounded, 'Common Diseases', species.getCommonDiseases(t.isUrdu), isDark),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () { Navigator.pop(ctx); Navigator.pushNamed(ctx, '/capture', arguments: {'plantHint': species.nameEn}); },
                          icon: const Icon(Icons.camera_alt_rounded, size: 18),
                          label: const Text('Scan This Plant'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetSection(BuildContext context, IconData icon, String title, String content, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 15),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 6),
        Text(content, style: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.darkSubtext : const Color(0xFF4A5568),
          height: 1.5,
        )),
      ],
    );
  }
}

// ── Feature card — PictureThis style ─────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final IconData? icon;
  final String? customIconPath;
  final String title, subtitle, imagePath;
  final bool isDark;
  final VoidCallback onTap;

  const _FeatureCard({
    this.icon,
    this.customIconPath,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            // Left — icon/image + text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                child: Row(
                  children: [
                    // Icon: custom image or Material icon
                    if (customIconPath != null)
                      SizedBox(
                        width: 40, height: 40,
                        child: Image.asset(
                          customIconPath!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            icon ?? Icons.eco_rounded,
                            color: AppColors.primary, size: 26,
                          ),
                        ),
                      )
                    else
                      Icon(icon ?? Icons.eco_rounded, color: AppColors.primary, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E),
                            letterSpacing: -0.3,
                          )),
                          const SizedBox(height: 2),
                          Text(subtitle, style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Right — image panel
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(15)),
              child: SizedBox(
                width: 100, height: 88,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: AppColors.primary.withValues(alpha: 0.06)),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          icon ?? Icons.eco_rounded,
                          color: AppColors.primary, size: 44,
                        ),
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
}



