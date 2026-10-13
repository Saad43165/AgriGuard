import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agriguard_fyp/core/services/translation_service.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';
import 'package:agriguard_fyp/features/advance_search_screen/service/groq_service.dart';
import '../plant_species.dart';

class SpeciesChip extends StatelessWidget {
  final PlantSpecies species;
  final bool isDark;
  final TranslationService t;
  const SpeciesChip({super.key, required this.species, required this.isDark, required this.t});

  @override
  Widget build(BuildContext context) {
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
    final groqService = GroqService();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.70,
        minChildSize: 0.4,
        maxChildSize: 0.95,
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
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: _fetchAiInfo(groqService, species, t.isUrdu),
                  builder: (context, snapshot) {
                    final aiData = snapshot.data;
                    return SingleChildScrollView(
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
                                      color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
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
                          if (aiData != null) ...[
                            const SizedBox(height: 12),
                            _sheetSection(context, Icons.psychology_rounded, 'AI Insights', aiData['overview']?.toString() ?? '', isDark),
                            if (aiData['uses'] != null) _buildListSection(context, Icons.eco_rounded, 'Uses', aiData['uses'], isDark),
                            if (aiData['growing'] != null) _sheetSection(context, Icons.wb_sunny_rounded, 'Growing Guide', aiData['growing']?.toString() ?? '', isDark),
                            if (aiData['care'] != null) _sheetSection(context, Icons.favorite_rounded, 'Care Tips', aiData['care']?.toString() ?? '', isDark),
                            if (aiData['problems'] != null) _sheetSection(context, Icons.warning_rounded, 'Watch For', aiData['problems']?.toString() ?? '', isDark),
                          ] else ...[
                            const SizedBox(height: 12),
                            _sheetSection(context, Icons.wb_sunny_rounded, 'Growth', species.getGrowthInfo(t.isUrdu), isDark),
                          ],
                          const SizedBox(height: 12),
                          _sheetSection(context, Icons.bug_report_rounded, 'Common Diseases', species.getCommonDiseases(t.isUrdu), isDark),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchAiInfo(GroqService service, PlantSpecies species, bool isUrdu) async {
    try {
      return await service.generatePlantInfo(
        plantName: species.nameEn,
        scientificName: species.scientificName,
        inUrdu: isUrdu,
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildListSection(BuildContext context, IconData icon, String title, List<dynamic> items, bool isDark) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 15),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 6),
        ...items.map((item) => Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 4, start: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(margin: const EdgeInsets.only(top: 6), width: 5, height: 5,
                  decoration: BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(item.toString(), style: TextStyle(
                fontSize: 12, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ))),
            ],
          ),
        )),
      ],
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
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          height: 1.5,
        )),
      ],
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData? icon;
  final String? customIconPath;
  final String title, subtitle, imagePath;
  final bool isDark;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                child: Row(
                  children: [
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
                            color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
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
