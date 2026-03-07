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
  static const List<PlantSpecies> allSpecies = [
    PlantSpecies(
      nameEn: 'Apple',
      nameUr: 'سیب',
      scientificName: 'Malus domestica',
      descriptionEn: 'Deciduous trees cultivated worldwide for their sweet fruit. Apples are one of the most widely grown tree fruits.',
      descriptionUr: 'پتوں والے درخت جو دنیا بھر میں میٹھے پھلوں کے لیے اگائے جاتے ہیں۔ سیب سب سے زیادہ اگائے جانے والے درختی پھلوں میں سے ایک ہے۔',
      growthInfoEn: 'Grows best in temperate climates with cold winters. Requires full sun and well-drained soil.',
      growthInfoUr: 'معتدل آب و ہوا میں بہترین اگتا ہے جہاں سردیاں سرد ہوں۔ مکمل دھوپ اور اچھی نکاسی والی مٹی کی ضرورت ہوتی ہے۔',
      commonDiseasesEn: 'Apple Scab, Fire Blight, Powdery Mildew, Cedar Apple Rust',
      commonDiseasesUr: 'ایپل اسکیب، فائر بلائٹ، پاؤڈری ملڈیو، سیڈر ایپل رسٹ',
      imagePath: 'assets/images/apple.png',
      color: Color(0xFFE74C3C),
    ),
    PlantSpecies(
      nameEn: 'Bell Pepper',
      nameUr: 'شملہ مرچ',
      scientificName: 'Capsicum annuum',
      descriptionEn: 'Sweet peppers with mild flavor, available in various colors. Rich in vitamins A and C.',
      descriptionUr: 'میٹھی مرچیں جو ہلکی ذائقہ کے ساتھ مختلف رنگوں میں دستیاب ہیں۔ وٹامن A اور C سے بھرپور۔',
      growthInfoEn: 'Warm-season crop requiring 70-90 days to harvest. Needs full sun and consistent watering.',
      growthInfoUr: 'گرم موسم کی فصل جسے کٹائی تک 70-90 دن ل��تے ہیں۔ مکمل دھوپ اور مسلسل پانی کی ضرورت ہوتی ہے۔',
      commonDiseasesEn: 'Bacterial Spot, Blossom End Rot, Anthracnose, Mosaic Virus',
      commonDiseasesUr: 'بیکٹیریل اسپاٹ، بلاسم اینڈ روٹ، انتھراکنوز، موزیک وائرس',
      imagePath: 'assets/images/bellpepper.png',
      color: Color(0xFF27AE60),
    ),
    PlantSpecies(
      nameEn: 'Cherry',
      nameUr: 'چیری',
      scientificName: 'Prunus avium',
      descriptionEn: 'Stone fruit trees producing sweet or sour cherries. Popular for fresh eating and cooking.',
      descriptionUr: 'پتھر والے پھلوں کے درخت جو میٹھی یا کھٹی چیری پیدا کرتے ہیں۔ تازہ کھانے اور پکانے کے لیے مقبول۔',
      growthInfoEn: 'Requires chilling hours in winter. Prefers well-drained soil and full sunlight.',
      growthInfoUr: 'سردیوں میں ٹھنڈک کے گھنٹے درکار ہیں۔ اچھی نکاسی والی مٹی اور مکمل دھوپ کو ترجیح دیتا ہے۔',
      commonDiseasesEn: 'Brown Rot, Cherry Leaf Spot, Powdery Mildew, Black Knot',
      commonDiseasesUr: 'براؤن روٹ، چیری لیف اسپاٹ، پاؤڈری ملڈیو، بلیک ناٹ',
      imagePath: 'assets/images/cherry.png',
      color: Color(0xFFE91E63),
    ),
    PlantSpecies(
      nameEn: 'Corn',
      nameUr: 'مکئی',
      scientificName: 'Zea mays',
      descriptionEn: 'Major cereal grain and staple food crop. Used for human consumption, livestock feed, and industrial products.',
      descriptionUr: 'بڑا اناج اور بنیادی خوراک کی فصل۔ انسانی استعمال، مویشیوں کی خوراک، اور صنعتی مصنوعات کے لیے استعمال ہوتی ہے۔',
      growthInfoEn: 'Warm-season annual requiring full sun. Needs nitrogen-rich soil and adequate moisture.',
      growthInfoUr: 'گرم موسم کی سالانہ فصل جسے مکمل دھوپ کی ضرورت ہوتی ہے۔ نائٹروجن سے بھرپور مٹی اور مناسب نمی کی ضرورت ہوتی ہے۔',
      commonDiseasesEn: 'Common Rust, Northern Leaf Blight, Gray Leaf Spot, Ear Rot',
      commonDiseasesUr: 'عام زنگ، شمالی پتوں کا جھلساؤ، گرے لیف اسپاٹ، کان کی سڑن',
      imagePath: 'assets/images/corn.png',
      color: Color(0xFFF39C12),
    ),
    PlantSpecies(
      nameEn: 'Grape',
      nameUr: 'انگور',
      scientificName: 'Vitis vinifera',
      descriptionEn: 'Woody vines grown for fresh fruit, wine production, and raisins. One of the oldest cultivated plants.',
      descriptionUr: 'لکڑی کی بیلیں جو تازہ پھل، شراب کی پیداوار، اور کشمش کے لیے اگائی جاتی ہیں۔ سب سے قدیم کاشت شدہ پودوں میں سے ایک۔',
      growthInfoEn: 'Perennial vine requiring support structure. Needs full sun and good air circulation.',
      growthInfoUr: 'دائمی بیل جسے سہارے کی ڈھانچہ کی ضرورت ہوتی ہے۔ مکمل دھوپ اور اچھی ہوا کی گردش کی ضرورت ہوتی ہے۔',
      commonDiseasesEn: 'Powdery Mildew, Downy Mildew, Black Rot, Botrytis',
      commonDiseasesUr: 'پاؤڈری ملڈیو، ڈاؤنی ملڈیو، بلیک روٹ، بوٹرائٹس',
      imagePath: 'assets/images/grape.png',
      color: Color(0xFF9B59B6),
    ),
    PlantSpecies(
      nameEn: 'Peach',
      nameUr: 'آڑو',
      scientificName: 'Prunus persica',
      descriptionEn: 'Deciduous tree producing juicy stone fruits. Native to China and widely cultivated in temperate regions.',
      descriptionUr: 'پتوں والا درخت جو رسیلے پتھر والے پھل پیدا کرتا ہے۔ چین کا مقامی اور معتدل علاقوں میں وسیع پیمانے پر کاشت کیا جاتا ہے۔',
      growthInfoEn: 'Requires winter chilling and protection from late frosts. Prefers well-drained, sandy soil.',
      growthInfoUr: 'سردیوں کی ٹھنڈک اور دیر سے پالا سے تحفظ کی ضرورت ہوتی ہے۔ اچھی نکاسی والی، ریتلی مٹی کو ترجیح دیتا ہے۔',
      commonDiseasesEn: 'Peach Leaf Curl, Brown Rot, Bacterial Spot, Powdery Mildew',
      commonDiseasesUr: 'پیچ لیف کرل، براؤن روٹ، بیکٹیریل اسپاٹ، پاؤڈری ملڈیو',
      imagePath: 'assets/images/peach.png',
      color: Color(0xFFFF6B6B),
    ),
    PlantSpecies(
      nameEn: 'Potato',
      nameUr: 'آلو',
      scientificName: 'Solanum tuberosum',
      descriptionEn: 'Starchy tuber crop and staple food worldwide. Fourth largest food crop after rice, wheat, and corn.',
      descriptionUr: 'نشاستہ دار کند کی فصل اور دنیا بھر میں بنیادی خوراک۔ چاول، گندم، اور مکئی کے بعد چوتھی سب سے بڑی خوراکی فصل۔',
      growthInfoEn: 'Cool-season crop grown from seed potatoes. Requires hilling and consistent moisture.',
      growthInfoUr: 'ٹھنڈے موسم کی فصل جو بیج آلو سے اگائی جاتی ہے۔ مٹی چڑھانے اور مسلسل نمی کی ضرورت ہوتی ہے۔',
      commonDiseasesEn: 'Late Blight, Early Blight, Blackleg, Common Scab',
      commonDiseasesUr: 'لیٹ بلائٹ، ارلی بلائٹ، بلیک لیگ، کامن اسکیب',
      imagePath: 'assets/images/potato.png',
      color: Color(0xFF8D6E63),
    ),
    PlantSpecies(
      nameEn: 'Soybean',
      nameUr: 'سویابین',
      scientificName: 'Glycine max',
      descriptionEn: 'Legume crop rich in protein and oil. Important for food, animal feed, and industrial products.',
      descriptionUr: 'پروٹین اور تیل سے بھرپور پھلی کی فصل۔ خوراک، جانوروں کی خوراک، اور صنعتی مصنوعات کے لیے اہم۔',
      growthInfoEn: 'Warm-season annual fixing nitrogen in soil. Requires well-drained soil and full sun.',
      growthInfoUr: 'گرم موسم کی سالانہ فصل جو مٹی میں نائٹروجن ٹھیک کرتی ہے۔ اچھی نکاسی والی مٹی اور مکمل دھوپ کی ضرورت ہوتی ہے۔',
      commonDiseasesEn: 'Soybean Rust, Frogeye Leaf Spot, White Mold, Root Rot',
      commonDiseasesUr: 'سویابین رسٹ، فروگ آئی لیف اسپاٹ، وائٹ مولڈ، روٹ روٹ',
      imagePath: 'assets/images/soybean.png',
      color: Color(0xFF7CB342),
    ),
    PlantSpecies(
      nameEn: 'Strawberry',
      nameUr: 'اسٹرابیری',
      scientificName: 'Fragaria × ananassa',
      descriptionEn: 'Perennial plant producing sweet, aromatic berries. Widely cultivated for fresh market and processing.',
      descriptionUr: 'دائمی پودا جو میٹھی، خوشبودار بیریاں پیدا کرتا ہے۔ تازہ بازار اور پروسیسنگ کے لیے وسیع پیمانے پر کاشت کیا جاتا ہے۔',
      growthInfoEn: 'Low-growing perennial producing runners. Needs full sun and slightly acidic soil.',
      growthInfoUr: 'کم اونچائی والا دائمی پودا جو دوڑنے والے تنے پیدا کرتا ہے۔ مکمل دھوپ اور قدرے تیزابی مٹی کی ضرورت ہوتی ہے۔',
      commonDiseasesEn: 'Gray Mold, Powdery Mildew, Leaf Spot, Verticillium Wilt',
      commonDiseasesUr: 'گرے مولڈ، پاؤڈری ملڈیو، لیف اسپاٹ، ورٹیسیلیم ولٹ',
      imagePath: 'assets/images/strawberry.png',
      color: Color(0xFFE74C3C),
    ),
    PlantSpecies(
      nameEn: 'Tomato',
      nameUr: 'ٹماٹر',
      scientificName: 'Solanum lycopersicum',
      descriptionEn: 'Popular fruit vegetable with high nutritional value. One of the most widely grown crops globally.',
      descriptionUr: 'مقبول پھل سبزی جس میں غذائیت کی اعلیٰ قدر ہوتی ہے۔ عالمی سطح پر سب سے زیادہ اگائی جانے والی فصلوں میں سے ایک۔',
      growthInfoEn: 'Warm-season crop requiring support. Needs full sun, consistent watering, and pruning.',
      growthInfoUr: 'گرم موسم کی فصل جسے سہارے کی ضرورت ہوتی ہے۔ مکمل دھوپ، مسلسل پانی، اور کٹائی چھانٹ کی ضرورت ہوتی ہے۔',
      commonDiseasesEn: 'Early Blight, Late Blight, Septoria Leaf Spot, Fusarium Wilt',
      commonDiseasesUr: 'ارلی بلائٹ، لیٹ بلائٹ، سیپٹوریا لیف اسپاٹ، فیوزیریم ولٹ',
      imagePath: 'assets/images/tomato.png',
      color: Color(0xFFFF5252),
    ),
    PlantSpecies(
      nameEn: 'Wheat',
      nameUr: 'گندم',
      scientificName: 'Triticum aestivum',
      descriptionEn: 'Cereal grain and staple food crop. Most widely grown crop for human consumption worldwide.',
      descriptionUr: 'اناج اور بنیادی خوراک کی فصل۔ دنیا بھر میں انسانی استعمال کے لیے سب سے زیادہ وسیع پیمانے پر اگائی جانے والی فصل۔',
      growthInfoEn: 'Cool-season grain requiring moderate temperatures. Grown in winter or spring varieties.',
      growthInfoUr: 'ٹھنڈے موسم کا اناج جسے اعتدال پسند درجہ حرارت کی ضرورت ہوتی ہے۔ سردیوں یا بہار کی اقسام میں اگایا جاتا ہے۔',
      commonDiseasesEn: 'Rust, Powdery Mildew, Fusarium Head Blight, Septoria Leaf Blotch',
      commonDiseasesUr: 'زنگ، پاؤڈری ملڈیو، فیوزیریم ہیڈ بلائٹ، سیپٹوریا لیف بلاچ',
      imagePath: 'assets/images/wheat.png',
      color: Color(0xFFD4A574),
    ),
  ];
}