import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_fyp/core/services/translation_service.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';
import 'plant_species.dart';
import 'widgets/species_widgets.dart';

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
                  child: SpeciesChip(species: species, isDark: isDark, t: t),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Feature cards with custom images
          FeatureCard(
            title: t.isUrdu ? 'تشخیص' : 'Diagnose',
            subtitle: t.isUrdu ? 'آف لائن' : 'Offline',
            customIconPath: 'assets/diag.png',
            imagePath: 'assets/diag.png',
            isDark: isDark,
            onTap: () => Navigator.pushNamed(context, '/capture'),
          ),
          const SizedBox(height: 12),
          FeatureCard(
            title: t.isUrdu ? 'ایڈوانسڈ اسکین' : 'Advance Scan',
            subtitle: t.isUrdu ? 'انٹرنیٹ درکار' : 'Internet Required',
            customIconPath: 'assets/adv.png',
            imagePath: 'assets/adv.png',
            isDark: isDark,
            onTap: () => Navigator.pushNamed(context, '/capture',
                arguments: {'startAdvanced': true}),
          ),
          const SizedBox(height: 12),
          FeatureCard(
            title: t.isUrdu ? 'فارم ڈائری' : 'Farm Diary',
            subtitle: t.isUrdu ? 'اپنی فصلیں ٹریک کریں' : 'Track Your Crops',
            customIconPath: 'assets/farm.png',
            imagePath: 'assets/farm.png',
            isDark: isDark,
            onTap: () => Navigator.pushNamed(context, '/farm-diary'),
          ),
          const SizedBox(height: 12),
          FeatureCard(
            title: t.isUrdu ? 'تجزیات' : 'Analytics',
            subtitle: t.isUrdu ? 'آف لائن' : 'Offline',
            customIconPath: 'assets/analytics.png',
            imagePath: 'assets/analytics.png',
            isDark: isDark,
            onTap: () => Navigator.pushNamed(context, '/analytics'),
          ),
          const SizedBox(height: 12),
          FeatureCard(
            title: t.isUrdu ? 'بیماری لائبریری' : 'Disease Library',
            subtitle: t.isUrdu ? '35 بیماریاں اور پودے' : '35 Diseases & Plants',
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





