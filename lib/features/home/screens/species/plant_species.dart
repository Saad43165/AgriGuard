import 'package:flutter/material.dart';

class PlantSpecies {
  final String name;
  final IconData icon;
  final Color color;

  const PlantSpecies({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class AppSpecies {
  static const List<PlantSpecies> allSpecies = [
    PlantSpecies(
      name: 'Tomato',
      icon: Icons.circle,
      color: Color(0xFFE74C3C),
    ),
    PlantSpecies(
      name: 'Potato',
      icon: Icons.egg_rounded,
      color: Color(0xFFD4A574),
    ),
    PlantSpecies(
      name: 'Pepper',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFE67E22),
    ),
    PlantSpecies(
      name: 'Corn',
      icon: Icons.grain_rounded,
      color: Color(0xFFF39C12),
    ),
    PlantSpecies(
      name: 'Apple',
      icon: Icons.apple_rounded,
      color: Color(0xFFC0392B),
    ),
    PlantSpecies(
      name: 'Grape',
      icon: Icons.bubble_chart_rounded,
      color: Color(0xFF8E44AD),
    ),
    PlantSpecies(
      name: 'Cherry',
      icon: Icons.circle_outlined,
      color: Color(0xFFE91E63),
    ),
    PlantSpecies(
      name: 'Peach',
      icon: Icons.favorite_rounded,
      color: Color(0xFFFFAB91),
    ),
    PlantSpecies(
      name: 'Strawberry',
      icon: Icons.favorite_border_rounded,
      color: Color(0xFFFF5252),
    ),
    PlantSpecies(
      name: 'Orange',
      icon: Icons.circle,
      color: Color(0xFFFF9800),
    ),
    PlantSpecies(
      name: 'Soybean',
      icon: Icons.eco_rounded,
      color: Color(0xFF8BC34A),
    ),
    PlantSpecies(
      name: 'Squash',
      icon: Icons.grass_rounded,
      color: Color(0xFF4CAF50),
    ),
  ];
}