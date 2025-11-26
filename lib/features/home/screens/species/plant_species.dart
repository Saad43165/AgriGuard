import 'package:flutter/material.dart';

class PlantSpecies {
  final String name;
  final String scientificName;
  final String description;
  final String growthInfo;
  final String commonDiseases;
  final String imagePath;
  final Color color;

  const PlantSpecies({
    required this.name,
    required this.scientificName,
    required this.description,
    required this.growthInfo,
    required this.commonDiseases,
    required this.imagePath,
    required this.color,
  });
}

class AppSpecies {
  static const List<PlantSpecies> allSpecies = [
    PlantSpecies(
      name: 'Apple',
      scientificName: 'Malus domestica',
      description: 'Deciduous trees cultivated worldwide for their sweet fruit. Apples are one of the most widely grown tree fruits.',
      growthInfo: 'Grows best in temperate climates with cold winters. Requires full sun and well-drained soil.',
      commonDiseases: 'Apple Scab, Fire Blight, Powdery Mildew, Cedar Apple Rust',
      imagePath: 'assets/images/apple.png',
      color: Color(0xFFE74C3C),
    ),
    PlantSpecies(
      name: 'Bell Pepper',
      scientificName: 'Capsicum annuum',
      description: 'Sweet peppers with mild flavor, available in various colors. Rich in vitamins A and C.',
      growthInfo: 'Warm-season crop requiring 70-90 days to harvest. Needs full sun and consistent watering.',
      commonDiseases: 'Bacterial Spot, Blossom End Rot, Anthracnose, Mosaic Virus',
      imagePath: 'assets/images/bellpepper.png',
      color: Color(0xFF27AE60),
    ),
    PlantSpecies(
      name: 'Cherry',
      scientificName: 'Prunus avium',
      description: 'Stone fruit trees producing sweet or sour cherries. Popular for fresh eating and cooking.',
      growthInfo: 'Requires chilling hours in winter. Prefers well-drained soil and full sunlight.',
      commonDiseases: 'Brown Rot, Cherry Leaf Spot, Powdery Mildew, Black Knot',
      imagePath: 'assets/images/cherry.png',
      color: Color(0xFFE91E63),
    ),
    PlantSpecies(
      name: 'Corn',
      scientificName: 'Zea mays',
      description: 'Major cereal grain and staple food crop. Used for human consumption, livestock feed, and industrial products.',
      growthInfo: 'Warm-season annual requiring full sun. Needs nitrogen-rich soil and adequate moisture.',
      commonDiseases: 'Common Rust, Northern Leaf Blight, Gray Leaf Spot, Ear Rot',
      imagePath: 'assets/images/corn.png',
      color: Color(0xFFF39C12),
    ),
    PlantSpecies(
      name: 'Grape',
      scientificName: 'Vitis vinifera',
      description: 'Woody vines grown for fresh fruit, wine production, and raisins. One of the oldest cultivated plants.',
      growthInfo: 'Perennial vine requiring support structure. Needs full sun and good air circulation.',
      commonDiseases: 'Powdery Mildew, Downy Mildew, Black Rot, Botrytis',
      imagePath: 'assets/images/grape.png',
      color: Color(0xFF9B59B6),
    ),
    PlantSpecies(
      name: 'Peach',
      scientificName: 'Prunus persica',
      description: 'Deciduous tree producing juicy stone fruits. Native to China and widely cultivated in temperate regions.',
      growthInfo: 'Requires winter chilling and protection from late frosts. Prefers well-drained, sandy soil.',
      commonDiseases: 'Peach Leaf Curl, Brown Rot, Bacterial Spot, Powdery Mildew',
      imagePath: 'assets/images/peach.png',
      color: Color(0xFFFF6B6B),
    ),
    PlantSpecies(
      name: 'Potato',
      scientificName: 'Solanum tuberosum',
      description: 'Starchy tuber crop and staple food worldwide. Fourth largest food crop after rice, wheat, and corn.',
      growthInfo: 'Cool-season crop grown from seed potatoes. Requires hilling and consistent moisture.',
      commonDiseases: 'Late Blight, Early Blight, Blackleg, Common Scab',
      imagePath: 'assets/images/potato.png',
      color: Color(0xFF8D6E63),
    ),
    PlantSpecies(
      name: 'Soybean',
      scientificName: 'Glycine max',
      description: 'Legume crop rich in protein and oil. Important for food, animal feed, and industrial products.',
      growthInfo: 'Warm-season annual fixing nitrogen in soil. Requires well-drained soil and full sun.',
      commonDiseases: 'Soybean Rust, Frogeye Leaf Spot, White Mold, Root Rot',
      imagePath: 'assets/images/soybean.png',
      color: Color(0xFF7CB342),
    ),
    PlantSpecies(
      name: 'Strawberry',
      scientificName: 'Fragaria × ananassa',
      description: 'Perennial plant producing sweet, aromatic berries. Widely cultivated for fresh market and processing.',
      growthInfo: 'Low-growing perennial producing runners. Needs full sun and slightly acidic soil.',
      commonDiseases: 'Gray Mold, Powdery Mildew, Leaf Spot, Verticillium Wilt',
      imagePath: 'assets/images/strawberry.png',
      color: Color(0xFFE74C3C),
    ),
    PlantSpecies(
      name: 'Tomato',
      scientificName: 'Solanum lycopersicum',
      description: 'Popular fruit vegetable with high nutritional value. One of the most widely grown crops globally.',
      growthInfo: 'Warm-season crop requiring support. Needs full sun, consistent watering, and pruning.',
      commonDiseases: 'Early Blight, Late Blight, Septoria Leaf Spot, Fusarium Wilt',
      imagePath: 'assets/images/tomato.png',
      color: Color(0xFFFF5252),
    ),
    PlantSpecies(
      name: 'Wheat',
      scientificName: 'Triticum aestivum',
      description: 'Cereal grain and staple food crop. Most widely grown crop for human consumption worldwide.',
      growthInfo: 'Cool-season grain requiring moderate temperatures. Grown in winter or spring varieties.',
      commonDiseases: 'Rust, Powdery Mildew, Fusarium Head Blight, Septoria Leaf Blotch',
      imagePath: 'assets/images/wheat.png',
      color: Color(0xFFD4A574),
    ),
  ];
}