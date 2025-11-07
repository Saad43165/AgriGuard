import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';
import 'plant_species.dart';

class SpeciesGridWidget extends StatelessWidget {
  const SpeciesGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detectable Species',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: AppMeasurements.getResponsiveFontSize(
                    context,
                    baseSize: 18,
                  ),
                ),
              ),
              Text(
                '${AppSpecies.allSpecies.length} Plants',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: AppSpecies.allSpecies.length,
            itemBuilder: (context, index) {
              final species = AppSpecies.allSpecies[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < AppSpecies.allSpecies.length - 1 ? 12 : 0,
                ),
                child: _SpeciesCard(species: species),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SpeciesCard extends StatelessWidget {
  final PlantSpecies species;

  const _SpeciesCard({required this.species});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: species.color.withOpacity(0.15),
            ),
            child: Icon(
              species.icon,
              color: species.color,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              species.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: AppMeasurements.getResponsiveFontSize(
                  context,
                  baseSize: 10,
                ),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}