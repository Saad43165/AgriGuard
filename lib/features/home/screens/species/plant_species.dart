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
  static final List<PlantSpecies> modelPlants = [
    PlantSpecies(
      nameEn: 'Bean', nameUr: 'پھلیاں',
      scientificName: 'Phaseolus vulgaris',
      descriptionEn: 'High-protein legume crop. On-Device model supports 4 disease classes — works offline.',
      descriptionUr: 'پروٹین سے بھرپور پھلی کی فصل۔ آن ڈیوائس ماڈل 4 بیماریاں سپورٹ کرتا ہے۔',
      growthInfoEn: 'Warm season, 18-30°C. Well-drained soil, full sun. Harvest: 50-70 days after planting.',
      growthInfoUr: 'گرم موسم، 18-30°C۔ اچھی نکاسی والی مٹی، مکمل دھوپ۔ بوائی کے 50-70 دن بعد کٹائی۔',
      commonDiseasesEn: 'Fungal Leaf Disease, Healthy, Bean Rust, Shot Hole',
      commonDiseasesUr: 'فنگل پتوں کی بیماری، صحت مند، پھلی کا زنگ، سوراخ دار پتا',
      imagePath: 'assets/images/soybean.png', color: Color(0xFF7CB342),
    ),
    PlantSpecies(
      nameEn: 'Corn', nameUr: 'مکئی',
      scientificName: 'Zea mays',
      descriptionEn: 'Major cereal grain and staple food. On-Device model supports 4 disease classes — works offline.',
      descriptionUr: 'بڑا اناج اور بنیادی خوراک۔ آن ڈیوائس ماڈل 4 بیماریاں سپورٹ کرتا ہے۔',
      growthInfoEn: 'Warm season, 20-30°C. Nitrogen-rich soil, full sun. Harvest: 60-100 days.',
      growthInfoUr: 'گرم موسم، 20-30°C۔ نائٹروجن سے بھرپور مٹی، مکمل دھوپ۔ 60-100 دن میں کٹائی۔',
      commonDiseasesEn: 'Fungal Leaf, Healthy, Gray Leaf Spot, Holcus Leaf Spot',
      commonDiseasesUr: 'فنگل پتا، صحت مند، سرمئی پتوں کا داغ، ہولکس پتوں کا داغ',
      imagePath: 'assets/images/corn.png', color: Color(0xFFF39C12),
    ),
    PlantSpecies(
      nameEn: 'Fig', nameUr: 'انجیر',
      scientificName: 'Ficus carica',
      descriptionEn: 'Subtropical fruit tree with sweet figs. On-Device model supports 4 disease classes — works offline.',
      descriptionUr: 'میٹھے انجیر پیدا کرنے والا ذیلی اشنکٹبندیی پھلوں کا درخت۔ آن ڈیوائس ماڈل 4 بیماریاں۔',
      growthInfoEn: 'Warm climate, 15-35°C. Well-drained soil, full sun. Harvest: Aug-Oct.',
      growthInfoUr: 'گرم آب و ہوا، 15-35°C۔ اچھی نکاسی والی مٹی، مکمل دھوپ۔ اگست - اکتوبر میں کٹائی۔',
      commonDiseasesEn: 'Blight Leaf Disease, Brown Spot, Healthy, Rust',
      commonDiseasesUr: 'پتوں کا جھلساؤ، بھورے دھبے، صحت مند، زنگ',
      imagePath: 'assets/images/fig.png', color: Color(0xFF795548),
    ),
    PlantSpecies(
      nameEn: 'Grape', nameUr: 'انگور',
      scientificName: 'Vitis vinifera',
      descriptionEn: 'Woody vine for fresh fruit and wine. On-Device model supports 7 disease classes — works offline.',
      descriptionUr: 'تازہ پھل اور شراب کے لیے لکڑی کی بیل۔ آن ڈیوائس ماڈل 7 بیماریاں سپورٹ کرتا ہے۔',
      growthInfoEn: 'Mediterranean climate ideal. Full sun, good drainage. Harvest: Aug-Oct.',
      growthInfoUr: 'بحیرہ روم کی آب و ہوا مثالی۔ مکمل دھوپ، اچھی نکاسی۔ اگست - اکتوبر میں کٹائی۔',
      commonDiseasesEn: 'Anthracnose, Brown Spot, Downy Mildew, Mites Leaf Disease, Healthy, Powdery Mildew, Shot Hole Leaf Disease',
      commonDiseasesUr: 'اینتھراکنوز، بھورے دھبے، نیچے کی پھپھوندی، مائٹس کی بیماری، صحت مند، سفید پھپھوندی، سوراخ دار پتا',
      imagePath: 'assets/images/grape.png', color: Color(0xFF9B59B6),
    ),
    PlantSpecies(
      nameEn: 'Walnut', nameUr: 'اخروٹ',
      scientificName: 'Juglans regia',
      descriptionEn: 'Deciduous tree with nutritious walnuts. On-Device model supports 5 disease classes — works offline.',
      descriptionUr: 'غذائیت سے بھرپور اخروٹ پیدا کرنے والا درخت۔ آن ڈیوائس ماڈل 5 بیماریاں سپورٹ کرتا ہے۔',
      growthInfoEn: 'Temperate climate, deep well-drained soil. Full sun. Harvest: Sep-Oct.',
      growthInfoUr: 'معتدل آب و ہوا، گہری اچھی نکاسی والی مٹی۔ مکمل دھوپ۔ ستمبر - اکتوبر میں کٹائی۔',
      commonDiseasesEn: 'Anthracnose Leaf Disease, Blotch Leaf Disease, Healthy, Shot Hole, Leaf Gall Mite',
      commonDiseasesUr: 'اینتھراکنوز، دھبے والی بیماری، صحت مند، سوراخ دار پتا، پتوں کے گال ذرات',
      imagePath: 'assets/images/walnut.png', color: Color(0xFF6D4C41),
    ),
    PlantSpecies(
      nameEn: 'Tomato', nameUr: 'ٹماٹر',
      scientificName: 'Solanum lycopersicum',
      descriptionEn: "Most widely grown vegetable globally. On-Device model supports 11 disease classes — works offline.",
      descriptionUr: "عالمی سطح پر سب سے زیادہ اگائی جانے والی سبزی۔ آن ڈیوائس ماڈل 11 بیماریاں سپورٹ کرتا ہے۔",
      growthInfoEn: "Warm season, 20-30°C. Full sun, consistent watering. Harvest: 60-85 days.",
      growthInfoUr: "گرم موسم، 20-30°C۔ مکمل دھوپ، مسلسل پانی۔ 60-85 دن میں کٹائی۔",
      commonDiseasesEn: "Bacterial Spot, Early Blight, Late Blight, Leaf Curl, Leaf Miner, Leaf Mold, Septoria, Spider Mites, Fusarium Wilt, Verticillium Wilt, Healthy",
      commonDiseasesUr: "بیکٹیریل داغ، ابتدائی جھلساؤ، تاخیری جھلساؤ، پتوں کا مڑنا، پتوں کا کیڑا، پتوں کی پھپھوندی، سیپٹوریا، مکڑی کے ذرات، فیوزیریم مرجھاؤ، ورٹیسیلیم مرجھاؤ، صحت مند",
      imagePath: "assets/images/tomato.png", color: Color(0xFFFF5252),
    ),
    PlantSpecies(
      nameEn: "Apricot", nameUr: "خوبانی",
      scientificName: "Prunus armeniaca",
      descriptionEn: "Stone fruit with orange-gold flesh. Rich in vitamins and fiber.",
      descriptionUr: "سنہرے گوشت والا پھل۔ وٹامنز اور فائبر سے بھرپور۔",
      growthInfoEn: "Temperate climate, well-drained soil. Harvest: Jun-Aug.",
      growthInfoUr: "معتدل آب و ہوا، اچھی نکاسی والی مٹی۔ جون - اگست میں کٹائی۔",
      commonDiseasesEn: "Brown Rot, Shot Hole, Leaf Curl, Healthy",
      commonDiseasesUr: "بھورا سڑنا، سوراخ دار پتا، پتوں کا مڑنا، صحت مند",
      imagePath: "assets/images/apricot.png", color: Color(0xFFFF9800),
    ),
    PlantSpecies(
      nameEn: "Cherry", nameUr: "چیری",
      scientificName: "Prunus avium",
      descriptionEn: "Sweet stone fruit. Good source of antioxidants.",
      descriptionUr: "میٹھا پھل۔ اینٹی آکسیڈنٹس کا اچھا ذریعہ۔",
      growthInfoEn: "Cool temperate, requires chill hours. Harvest: May-Jun.",
      growthInfoUr: "ٹھنڈا معتدل، سردی کی ضرورت۔ مئی - جون میں کٹائی۔",
      commonDiseasesEn: "Brown Rot, Powdery Mildew, Leaf Spot, Healthy",
      commonDiseasesUr: "بھورا سڑنا، سفید پھپھوندی، پتا کا داغ، صحت مند",
      imagePath: "assets/images/cherry.png", color: Color(0xFFD32F2F),
    ),
    PlantSpecies(
      nameEn: "Apple", nameUr: "سیب",
      scientificName: "Malus domestica",
      descriptionEn: "Popular temperate fruit. Rich in fiber and vitamin C.",
      descriptionUr: "مقبول معتدل پھل۔ فائبر اور وٹامن سی سے بھرپور۔",
      growthInfoEn: "Temperate, needs cold dormancy. Harvest: Aug-Oct.",
      growthInfoUr: "معتدل، سردی کی ضرورت۔ اگست - اکتوبر میں کٹائی۔",
      commonDiseasesEn: "Apple Scab, Fire Blight, Powdery Mildew, Healthy",
      commonDiseasesUr: "سیب کا داغ، آگ سے جھلساؤ، سفید پھپھوندی، صحت مند",
      imagePath: "assets/images/apple.png", color: Color(0xFF4CAF50),
    ),
    PlantSpecies(
      nameEn: "Loquat", nameUr: "اُ��و",
      scientificName: "Eriobotrya japonica",
      descriptionEn: " subtropical fruit with sweet yellow flesh.",
      descriptionUr: "میٹھے پیلے گوشت والا ذیلی اشنکٹبندیی پھل۔",
      growthInfoEn: "Subtropical, well-drained soil. Harvest: Mar-May.",
      growthInfoUr: "ذیلی اشنکٹبندیی، اچھی نکاسی والی مٹی۔ مارچ - مئی میں کٹائی۔",
      commonDiseasesEn: "Fire Blight, Leaf Spot, Crown Rot, Healthy",
      commonDiseasesUr: "آگ سے جھلساؤ، پتا کا داغ، تاج کا سڑنا، صحت مند",
      imagePath: "assets/images/loquat.png", color: Color(0xFFFFB300),
    ),
    PlantSpecies(
      nameEn: "Pear", nameUr: "ناک",
      scientificName: "Pyrus communis",
      descriptionEn: "Sweet fleshy fruit. Good source of fiber.",
      descriptionUr: "میٹھا گوشت والا پھل۔ فائبر کا اچھا ذریعہ۔",
      growthInfoEn: "Temperate, needs chill hours. Harvest: Aug-Oct.",
      growthInfoUr: "معتدل، سردی کی ضرورت۔ اگست - اکتوبر میں کٹائی۔",
      commonDiseasesEn: "Fire Blight, Leaf Spot, Powdery Mildew, Healthy",
      commonDiseasesUr: "آگ سے جھلساؤ، پتا کا داغ، سفید پھپھوندی، صحت مند",
      imagePath: "assets/images/pear.png", color: Color(0xFFCDDC39),
    ),
    PlantSpecies(
      nameEn: "Persimmon", nameUr: "پرسنیمون",
      scientificName: "Diospyros kaki",
      descriptionEn: "Sweet orange fruit. High in fiber and antioxidants.",
      descriptionUr: "میٹھا پیلا پھل۔ فائبر اور اینٹی آکسیڈنٹس سے بھرپور۔",
      growthInfoEn: "Subtropical to temperate. Harvest: Oct-Dec.",
      growthInfoUr: "ذیلی اشنکٹبندیی سے معتدل۔ اکتوبر - دسمبر میں کٹائی۔",
      commonDiseasesEn: "Leaf Spot, Anthracnose, Healthy",
      commonDiseasesUr: "پتا کا داغ، اینتھراکنوز، صحت مند",
      imagePath: "assets/images/persimmon.png", color: Color(0xFFFF6D00),
    ),
  ];

  static final List<PlantSpecies> allSpecies = [
    ...modelPlants,
    PlantSpecies(
      nameEn: 'Advanced AI', nameUr: 'ایڈوانسڈ AI',
      scientificName: 'Plant.id API',
      descriptionEn: 'Scan ANY plant species with Advanced AI. Works with thousands of plants beyond our 6 on-device species. Uses Plant.id API for identification and disease detection with detailed images and treatment guides.',
      descriptionUr: 'ایڈوانسڈ AI کے ساتھ کسی بھی پودے کی شناخت کریں۔ ہزاروں پودوں کے ساتھ کام کرتا ہے۔ Plant.id API استعمال کرتا ہے۔',
      growthInfoEn: 'Open Advanced AI scan in the app — no plant limit!',
      growthInfoUr: 'ایپ میں ایڈوانسڈ AI اسکین کھولیں — کوئی پودے کی حد نہیں!',
      commonDiseasesEn: 'Advanced AI detects all common plant diseases with detailed treatment guides.',
      commonDiseasesUr: 'ایڈوانسڈ AI تمام عام پودوں کی بیماریاں تفصیلی علاج کے ساتھ پہچانتا ہے۔',
      imagePath: 'assets/images/image.png', color: Color(0xFF607D8B),
    ),
  ];
}