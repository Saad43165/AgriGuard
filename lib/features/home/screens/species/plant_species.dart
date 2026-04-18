// lib/features/home/screens/species/plant_species.dart
import 'package:flutter/material.dart';

class PlantSpecies {
  final String nameEn;
  final String nameUr;
  final String scientificName;
  final String descriptionEn;
  final String descriptionUr;
  final String growthInfoEn;
  final String growthInfoUr;
  final String commonDiseasesEn;
  final String commonDiseasesUr;
  final String imagePath;
  final Color color;

  const PlantSpecies({
    required this.nameEn,
    required this.nameUr,
    required this.scientificName,
    required this.descriptionEn,
    required this.descriptionUr,
    required this.growthInfoEn,
    required this.growthInfoUr,
    required this.commonDiseasesEn,
    required this.commonDiseasesUr,
    required this.imagePath,
    required this.color,
  });

  String getName(bool isUrdu) => isUrdu ? nameUr : nameEn;
  String getDescription(bool isUrdu) => isUrdu ? descriptionUr : descriptionEn;
  String getGrowthInfo(bool isUrdu) => isUrdu ? growthInfoUr : growthInfoEn;
  String getCommonDiseases(bool isUrdu) => isUrdu ? commonDiseasesUr : commonDiseasesEn;
}

class AppSpecies {
  static final List<PlantSpecies> allSpecies = [
    // Apple removed — apple specialist model not yet accurate enough for production
    PlantSpecies(
      nameEn: 'Apricot', nameUr: 'خوبانی',
      scientificName: 'Prunus armeniaca',
      descriptionEn: 'Stone fruit tree producing sweet orange fruit. Supports 3 disease classes in the model.',
      descriptionUr: 'میٹھے نارنجی پھل پیدا کرنے والا پتھر والے پھلوں کا درخت۔',
      growthInfoEn: 'Temperate climate, requires winter chilling. Well-drained soil, full sun. Harvest: Jun–Jul.',
      growthInfoUr: 'معتدل آب و ہوا، سردیوں کی ٹھنڈک ضروری۔ اچھی نکاسی والی مٹی، مکمل دھوپ۔',
      commonDiseasesEn: 'Blight Leaf Disease, Shot Hole',
      commonDiseasesUr: 'پتوں کا جھلساؤ، سوراخ دار پتے',
      imagePath: 'assets/images/apricot.png', color: Color(0xFFFF9800),
    ),
    PlantSpecies(
      nameEn: 'Bean', nameUr: 'پھلیاں',
      scientificName: 'Phaseolus vulgaris',
      descriptionEn: 'Legume crop rich in protein. Supports 4 disease classes in the model.',
      descriptionUr: 'پروٹین سے بھرپور پھلی کی فصل۔',
      growthInfoEn: 'Warm season, 18-30°C. Well-drained soil, full sun. Harvest: 50-70 days.',
      growthInfoUr: 'گرم موسم، 18-30°C۔ اچھی نکاسی والی مٹی، مکمل دھوپ۔',
      commonDiseasesEn: 'Fungal Leaf Disease, Rust, Shot Hole',
      commonDiseasesUr: 'فنگل پتوں کی بیماری، زنگ، سوراخ دار پتے',
      imagePath: 'assets/images/soybean.png', color: Color(0xFF7CB342),
    ),
    PlantSpecies(
      nameEn: 'Cherry', nameUr: 'چیری',
      scientificName: 'Prunus avium',
      descriptionEn: 'Stone fruit tree producing sweet or sour cherries. Supports 5 disease classes.',
      descriptionUr: 'میٹھی یا کھٹی چیری پیدا کرنے والا پتھر والے پھلوں کا درخت۔',
      growthInfoEn: 'Temperate climate, chilling hours required. Well-drained soil, full sun. Harvest: Jun–Jul.',
      growthInfoUr: 'معتدل آب و ہوا، ٹھنڈک کے گھنٹے ضروری۔ اچھی نکاسی والی مٹی، مکمل دھوپ۔',
      commonDiseasesEn: 'Leaf Scorch, Brown Spot, Purple Leaf Spot, Shot Hole',
      commonDiseasesUr: 'پتوں کا جھلساؤ، بھورے دھبے، جامنی دھبے، سوراخ دار پتے',
      imagePath: 'assets/images/cherry.png', color: Color(0xFFE91E63),
    ),
    PlantSpecies(
      nameEn: 'Corn', nameUr: 'مکئی',
      scientificName: 'Zea mays',
      descriptionEn: 'Major cereal grain and staple food. Supports 4 disease classes in the model.',
      descriptionUr: 'بڑا اناج اور بنیادی خوراک۔',
      growthInfoEn: 'Warm season, 20–30°C. Nitrogen-rich soil, full sun. Harvest: 60–100 days.',
      growthInfoUr: 'گرم موسم، 20–30°C۔ نائٹروجن سے بھرپور مٹی، مکمل دھوپ۔',
      commonDiseasesEn: 'Fungal Leaf Disease, Gray Leaf Spot, Holcus Leaf Spot',
      commonDiseasesUr: 'فنگل پتوں کی بیماری، بھوری پتوں کے دھبے، ہولکس دھبے',
      imagePath: 'assets/images/corn.png', color: Color(0xFFF39C12),
    ),
    PlantSpecies(
      nameEn: 'Fig', nameUr: 'انجیر',
      scientificName: 'Ficus carica',
      descriptionEn: 'Subtropical fruit tree producing sweet figs. Supports 4 disease classes.',
      descriptionUr: 'میٹھے انجیر پیدا کرنے والا ذیلی اشنکٹبندیی پھلوں کا درخت۔',
      growthInfoEn: 'Warm climate, 15-35°C. Well-drained soil, full sun. Harvest: Aug–Oct.',
      growthInfoUr: 'گرم آب و ہوا، 15-35°C۔ اچھی نکاسی والی مٹی، مکمل دھوپ۔',
      commonDiseasesEn: 'Blight Leaf Disease, Brown Spot, Rust',
      commonDiseasesUr: 'پتوں کا جھلساؤ، بھورے دھبے، زنگ',
      imagePath: 'assets/images/fig.png', color: Color(0xFF795548),
    ),
    PlantSpecies(
      nameEn: 'Grape', nameUr: 'انگور',
      scientificName: 'Vitis vinifera',
      descriptionEn: 'Woody vine grown for fresh fruit and wine. Supports 7 disease classes.',
      descriptionUr: 'تازہ پھل اور شراب کے لیے اگائی جانے والی لکڑی کی بیل۔',
      growthInfoEn: 'Mediterranean climate ideal. Full sun, good drainage. Harvest: Aug–Oct.',
      growthInfoUr: 'بحیرہ روم کی آب و ہوا مثالی۔ مکمل دھوپ، اچھی نکاسی۔',
      commonDiseasesEn: 'Anthracnose, Brown Spot, Downy Mildew, Mite Damage, Powdery Mildew, Shot Hole',
      commonDiseasesUr: 'اینتھراکنوز، بھورے دھبے، نیچے کی پھپھوندی، کیڑوں کا نقصان، پھپھوندی، سوراخ دار پتے',
      imagePath: 'assets/images/grape.png', color: Color(0xFF9B59B6),
    ),
    PlantSpecies(
      nameEn: 'Loquat', nameUr: 'لوکاٹ',
      scientificName: 'Eriobotrya japonica',
      descriptionEn: 'Subtropical fruit tree producing small orange fruit. Supports 2 disease classes.',
      descriptionUr: 'چھوٹے نارنجی پھل پیدا کرنے والا ذیلی اشنکٹبندیی پھلوں کا درخت۔',
      growthInfoEn: 'Subtropical, 15-30°C. Well-drained soil, full sun. Harvest: Feb–Apr.',
      growthInfoUr: 'ذیلی اشنکٹبندیی، 15-30°C۔ اچھی نکاسی والی مٹی، مکمل دھوپ۔',
      commonDiseasesEn: 'Leaf Spot',
      commonDiseasesUr: 'پتوں کے دھبے',
      imagePath: 'assets/images/peach.png', color: Color(0xFFFF7043),
    ),
    PlantSpecies(
      nameEn: 'Pear', nameUr: 'ناشپاتی',
      scientificName: 'Pyrus communis',
      descriptionEn: 'Deciduous tree producing sweet pears. Supports 3 disease classes in the model.',
      descriptionUr: 'میٹھی ناشپاتی پیدا کرنے والا پتوں والا درخت۔',
      growthInfoEn: 'Temperate climate, cold winters required. Well-drained soil. Harvest: Aug–Oct.',
      growthInfoUr: 'معتدل آب و ہوا، سرد سردیاں ضروری۔ اچھی نکاسی والی مٹی۔',
      commonDiseasesEn: 'Black Spot, Fire Blight',
      commonDiseasesUr: 'کالے دھبے، آگ کا جھلساؤ',
      imagePath: 'assets/images/pear.png', color: Color(0xFF8BC34A),
    ),
    PlantSpecies(
      nameEn: 'Persimmon', nameUr: 'املوک',
      scientificName: 'Diospyros kaki',
      descriptionEn: 'Deciduous tree producing sweet orange fruit. Supports 1 disease class.',
      descriptionUr: 'میٹھے نارنجی پھل پیدا کرنے والا پتوں والا درخت۔',
      growthInfoEn: 'Temperate to subtropical, 15-30°C. Well-drained soil. Harvest: Oct–Dec.',
      growthInfoUr: 'معتدل سے ذیلی اشنکٹبندیی، 15-30°C۔ اچھی نکاسی والی مٹی۔',
      commonDiseasesEn: 'Brown Spot',
      commonDiseasesUr: 'بھورے دھبے',
      imagePath: 'assets/images/persimmons.png', color: Color(0xFFFF5722),
    ),
    PlantSpecies(
      nameEn: 'Tomato', nameUr: 'ٹماٹر',
      scientificName: 'Solanum lycopersicum',
      descriptionEn: 'Most widely grown vegetable globally. Supports 10 disease classes in the model.',
      descriptionUr: 'عالمی سطح پر سب سے زیادہ اگائی جانے والی سبزی۔',
      growthInfoEn: 'Warm season, 20–30°C. Full sun, consistent watering. Harvest: 60–85 days.',
      growthInfoUr: 'گرم موسم، 20–30°C۔ مکمل دھوپ، مسلسل پانی۔',
      commonDiseasesEn: 'Bacterial Spot, Early Blight, Late Blight, Leaf Curl, Leaf Miner, Leaf Mold, Septoria Leaf Spot, Spider Mites, Fusarium Wilt, Verticillium Wilt',
      commonDiseasesUr: 'بیکٹیریل دھبے، ابتدائی جھلساؤ، آخری جھلساؤ، پتوں کا کرل، پتوں کا کان کن، پتوں کی پھپھوندی، سیپٹوریا دھبے، مکڑی کے ذرات، فیوزیریم مرجھاؤ، ورٹیسیلیم مرجھاؤ',
      imagePath: 'assets/images/tomato.png', color: Color(0xFFFF5252),
    ),
    PlantSpecies(
      nameEn: 'Walnut', nameUr: 'اخروٹ',
      scientificName: 'Juglans regia',
      descriptionEn: 'Deciduous tree producing nutritious walnuts. Supports 5 disease classes.',
      descriptionUr: 'غذائیت سے بھرپور اخروٹ پیدا کرنے والا پتوں والا درخت۔',
      growthInfoEn: 'Temperate climate, deep well-drained soil. Full sun. Harvest: Sep–Oct.',
      growthInfoUr: 'معتدل آب و ہوا، گہری اچھی نکاسی والی مٹی۔ مکمل دھوپ۔',
      commonDiseasesEn: 'Anthracnose, Blotch, Shot Hole, Leaf Gall Mite',
      commonDiseasesUr: 'اینتھراکنوز، دھبے، سوراخ دار پتے، پتوں کے گال ذرات',
      imagePath: 'assets/images/walnut.png', color: Color(0xFF6D4C41),
    ),
  ];
}
