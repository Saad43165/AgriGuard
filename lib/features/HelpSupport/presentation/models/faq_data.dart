// lib/features/support/data/faq_data.dart
import '../models/faq_category.dart';
import '../models/faq_items.dart';

class FaqData {
  static final List<FaqItem> allFaqItems = [
  // ==================== GENERAL FAQs (6 questions) ====================
  FaqItem(
  questionEn: 'What is AgriGuard?',
  questionUr: 'AgriGuard کیا ہے؟',
  answerEn: 'AgriGuard is an AI-powered plant identification and disease detection app that uses TensorFlow machine learning to identify 12 plant species and detect 18 common plant diseases from photos, even without internet connection.',
  answerUr: 'AgriGuard ایک AI سے چلنے والی پودوں کی شناخت اور بیماری کا پتہ لگانے والی ایپ ہے جو TensorFlow مشین لرننگ استعمال کرتی ہے تاکہ 12 پودوں کی اقسام کی شناخت اور تصاویر سے 18 عام پودوں کی بیماریوں کا پتہ لگایا جا سکے، انٹرنیٹ کنکشن کے بغیر بھی۔',
  category: FaqCategory.general,
  tags: ['identification', 'AI', 'TensorFlow', 'offline'],
  ),

  FaqItem(
  questionEn: 'How accurate is the plant and disease detection?',
  questionUr: 'پودوں اور بیماری کی شناخت کتنی درست ہے؟',
  answerEn: 'Our TensorFlow model achieves 92% accuracy for plant species identification and 88% accuracy for disease detection. Accuracy depends on photo quality, lighting, and clear visibility of plant features.',
  answerUr: 'ہمارا TensorFlow ماڈل پودوں کی اقسام کی شناخت کے لیے 92% اور بیماری کی تشخیص کے لیے 88% درستگی حاصل کرتا ہے۔ درستگی تصویر کے معیار، روشنی اور پودوں کی خصوصیات کی واضح مرئیت پر منحصر ہے۔',
  category: FaqCategory.general,
  tags: ['accuracy', 'AI', 'TensorFlow', 'reliability'],
  ),

  FaqItem(
  questionEn: 'Can I use the app without internet?',
  questionUr: 'کیا میں ایپ کو انٹرنیٹ کے بغیر استعمال کر سکتا ہوں؟',
  answerEn: 'Yes! AgriGuard works completely offline thanks to our optimized TensorFlow Lite model. All plant identification and disease detection happens on your device without needing internet connection.',
  answerUr: 'جی ہاں! AgriGuard ہمارے بہتر شدہ TensorFlow Lite ماڈل کی بدولت مکمل طور پر آف لائن کام کرتا ہے۔ تمام پودوں کی شناخت اور بیماری کی تشخیص آپ کے ڈیوائس پر انٹرنیٹ کنکشن کی ضرورت کے بغیر ہوتی ہے۔',
  category: FaqCategory.general,
  tags: ['offline', 'TensorFlow Lite', 'no internet'],
  ),

  FaqItem(
  questionEn: 'Is AgriGuard free to use?',
  questionUr: 'کیا AgriGuard استعمال کرنا مفت ہے؟',
  answerEn: 'Yes! AgriGuard offers unlimited free scans with on-device AI. Guest users get limited scans. Premium features include cloud AI analysis, detailed reports, and scan history sync across devices.',
  answerUr: 'جی ہاں! AgriGuard آن ڈیوائس AI کے ساتھ لامحدود مفت اسکینز پیش کرتا ہے۔ مہمان صارفین کو محدود اسکینز ملتے ہیں۔ پریمیم خصوصیات میں کلاؤڈ AI تجزیہ، تفصیلی رپورٹیں، اور ڈیوائسز میں اسکین ہسٹری سنک شامل ہیں۔',
  category: FaqCategory.general,
  tags: ['free', 'pricing', 'premium', 'features'],
  ),

  FaqItem(
  questionEn: 'Which languages does AgriGuard support?',
  questionUr: 'AgriGuard کون سی زبانوں کو سپورٹ کرتا ہے؟',
  answerEn: 'AgriGuard currently supports English and Urdu. You can switch languages anytime from Settings or using the language toggle button in the app.',
  answerUr: 'AgriGuard فی الوقت انگریزی اور اردو کو سپورٹ کرتا ہے۔ آپ کسی بھی وقت سیٹنگز سے یا ایپ میں لینگویج ٹوگل بٹن استعمال کرکے زبانیں تبدیل کر سکتے ہیں۔',
  category: FaqCategory.general,
  tags: ['language', 'multilingual', 'urdu', 'english'],
  ),

  FaqItem(
  questionEn: 'What makes AgriGuard different from other plant apps?',
  questionUr: 'AgriGuard کو دوسری پودوں کی ایپس سے کیا مختلف بناتا ہے؟',
  answerEn: 'AgriGuard uniquely combines: 1) Offline AI processing, 2) Dual analysis methods (On-Device + Cloud AI), 3) Severity-based treatment plans, 4) 100% privacy with local processing, 5) Agriculture-focused disease detection.',
  answerUr: 'AgriGuard منفرد طور پر یہ ملاتا ہے: 1) آف لائن AI پروسیسنگ، 2) دوہرے تجزیہ کے طریقے (آن ڈیوائس + کلاؤڈ AI)، 3) شدت پر مبنی علاج کے منصوبے، 4) مقامی پروسیسنگ کے ساتھ 100% رازداری، 5) زراعت پر مرکوز بیماری کی تشخیص۔',
  category: FaqCategory.general,
  tags: ['unique', 'features', 'difference', 'benefits'],
  ),

  // ==================== SCANNING FAQs (12 questions) ====================
  FaqItem(
  questionEn: 'How do I scan a plant?',
  questionUr: 'میں پودے کو کیسے اسکین کروں؟',
  answerEn: 'Open the app, tap the scan button, and point your camera at the plant. Ensure good lighting for accurate results. You can capture from camera or choose from gallery.',
  answerUr: 'ایپ کھولیں، اسکین بٹن دبائیں، اور اپنا کیمرہ پودے کی طرف کریں۔ درست نتائج کے لیے اچھی روشنی کو یقینی بنائیں۔ آپ کیمرے سے کیپچر یا گیلری سے منتخب کر سکتے ہیں۔',
  category: FaqCategory.scanning,
  tags: ['scan', 'camera', 'how to', 'basic'],
  ),

  FaqItem(
  questionEn: 'How do I take the best photo for scanning?',
  questionUr: 'اسکیننگ کے لیے بہترین تصویر کیسے لی جائے؟',
  answerEn: 'For optimal results: 1) Use natural lighting, 2) Focus on leaves or affected areas, 3) Keep camera steady, 4) Fill frame with plant, 5) Take multiple angles if needed. Avoid shadows and blurry images.',
  answerUr: 'بہترین نتائج کے لیے: 1) قدرتی روشنی استعمال کریں، 2) پتوں یا متاثرہ علاقوں پر توجہ دیں، 3) کیمرہ کو مستحکم رکھیں، 4) فریم کو پودے سے بھریں، 5) ضرورت پڑنے پر مختلف زاویوں سے لیں۔ سائے اور دھندلی تصاویر سے بچیں۔',
  category: FaqCategory.scanning,
  tags: ['photography', 'tips', 'lighting', 'scanning'],
  ),

  FaqItem(
  questionEn: 'What plant species can the app identify?',
  questionUr: 'ایپ کون سے پودوں کی اقسام کی شناخت کر سکتی ہے؟',
  answerEn: 'AgriGuard identifies 12 common plant species: Tomato, Potato, Bell Pepper, Corn (Maize), Apple, Grape, Strawberry, Peach, Cherry, Wheat, Soybean, and more agricultural crops.',
  answerUr: 'AgriGuard 12 عام پودوں کی اقسام کی شناخت کرتا ہے: ٹماٹر، آلو، شملہ مرچ، مکئی، سیب، انگور، اسٹرابیری، آڑو، چیری، گندم، سویابین، اور مزید زرعی فصلیں۔',
  category: FaqCategory.scanning,
  tags: ['species', 'plants', 'supported', '12 species'],
  ),

  FaqItem(
  questionEn: 'What diseases can the app detect?',
  questionUr: 'ایپ کون سی بیماریوں کا پتہ لگا سکتی ہے؟',
  answerEn: 'We detect 18+ common plant diseases including Early Blight, Late Blight, Bacterial Spot, Powdery Mildew, Leaf Curl Virus, Mosaic Virus, Rust, Apple Scab, Black Rot, Septoria Leaf Spot, and various fungal/bacterial infections.',
  answerUr: 'ہم 18+ عام پودوں کی بیماریوں کا پتہ لگاتے ہیں بشمول ابتدائی جھلساؤ، تاخیری جھلساؤ، بیکٹیریل داغ، سفید پھپھوندی، لیف کرل وائرس، موزیک وائرس، زنگ، ایپل اسکیب، بلیک روٹ، سیپٹوریا لیف اسپاٹ، اور مختلف فنگل/بیکٹیریل انفیکشنز۔',
  category: FaqCategory.scanning,
  tags: ['diseases', 'detection', '18 diseases', 'health'],
  ),

  FaqItem(
  questionEn: 'What information does the scan result show?',
  questionUr: 'اسکین کا نتیجہ کیا معلومات دکھاتا ہے؟',
  answerEn: 'Each scan provides: 1) Plant Name & Species, 2) Disease Name & Type, 3) Severity Level (None/Low/Medium/High/Critical), 4) Cause Analysis, 5) Treatment Recommendations, 6) Preventive Measures, 7) AI Confidence Score.',
  answerUr: 'ہر اسکین فراہم کرتا ہے: 1) پودے کا نام اور قسم، 2) بیماری کا نام اور قسم، 3) شدت کی سطح (کوئی نہیں/کم/درمیانہ/زیادہ/انتہائی)، 4) وجہ کا تجزیہ، 5) علاج کی سفارشات، 6) احتیاطی تدابیر، 7) AI اعتماد کا اسکور۔',
  category: FaqCategory.scanning,
  tags: ['results', 'output', 'information', 'analysis'],
  ),

  FaqItem(
  questionEn: 'Can I scan multiple plants at once?',
  questionUr: 'کیا میں ایک ساتھ متعدد پودوں کو اسکین کر سکتا ہوں؟',
  answerEn: 'For best accuracy, scan one plant at a time. Multiple plants in a single image may reduce detection accuracy. Take separate photos for each plant you want to analyze.',
  answerUr: 'بہترین درستگی کے لیے، ایک وقت میں ایک پودا اسکین کریں۔ ایک تصویر میں متعدد پودے تشخیص کی درستگی کو کم کر سکتے ہیں۔ ہر پودے کے لیے جو آپ تجزیہ کرنا چاہتے ہیں الگ تصاویر لیں۔',
  category: FaqCategory.scanning,
  tags: ['multiple', 'single', 'accuracy', 'limitation'],
  ),

  FaqItem(
  questionEn: 'Why did my scan fail?',
  questionUr: 'میرا اسکین کیوں ناکام ہوا؟',
  answerEn: 'Scans can fail due to: 1) Poor lighting, 2) Blurry image, 3) Non-plant image, 4) Unsupported plant species, 5) Extreme close-up or too far. Try retaking the photo with better lighting and focus.',
  answerUr: 'اسکین ناکام ہو سکتے ہیں: 1) خراب روشنی، 2) دھندلی تصویر، 3) غیر پودے کی تصویر، 4) غیر معاون پودوں کی اقسام، 5) انتہائی قریب یا بہت دور۔ بہتر روشنی اور فوکس کے ساتھ تصویر دوبارہ لینے کی کوشش کریں۔',
  category: FaqCategory.scanning,
  tags: ['fail', 'error', 'troubleshoot', 'retry'],
  ),

  FaqItem(
  questionEn: 'What is the difference between On-Device AI and Cloud AI?',
  questionUr: 'آن ڈیوائس AI اور کلاؤڈ AI میں کیا فرق ہے؟',
  answerEn: 'On-Device AI: Works offline, instant results, 100% private, free unlimited scans. Cloud AI: Requires internet, more detailed analysis, expert recommendations, weather integration, premium feature.',
  answerUr: 'آن ڈیوائس AI: آف لائن کام کرتا ہے، فوری نتائج، 100% نجی، مفت لامحدود اسکینز۔ کلاؤڈ AI: انٹرنیٹ کی ضرورت ہے، زیادہ تفصیلی تجزیہ، ماہرین کی سفارشات، موسم کی یکجائی، پریمیم فیچر۔',
  category: FaqCategory.scanning,
  tags: ['on-device', 'cloud', 'AI', 'difference'],
  ),

  FaqItem(
  questionEn: 'Can I scan houseplants or only crops?',
  questionUr: 'کیا میں گھریلو پودوں کو اسکین کر سکتا ہوں یا صرف فصلوں کو؟',
  answerEn: 'AgriGuard is optimized for agricultural crops (tomato, potato, corn, wheat, etc.) but can also identify common houseplants. For best results with houseplants, use Cloud AI analysis.',
  answerUr: 'AgriGuard زرعی فصلوں (ٹماٹر، آلو، مکئی، گندم، وغیرہ) کے لیے بہتر بنایا گیا ہے لیکن عام گھریلو پودوں کی بھی شناخت کر سکتا ہے۔ گھریلو پودوں کے ساتھ بہترین نتائج کے لیے، کلاؤڈ AI تجزیہ استعمال کریں۔',
  category: FaqCategory.scanning,
  tags: ['houseplants', 'crops', 'agriculture', 'scope'],
  ),

  FaqItem(
  questionEn: 'How long does a scan take?',
  questionUr: 'اسکین میں کتنا وقت لگتا ہے؟',
  answerEn: 'On-Device AI: 2-5 seconds. Cloud AI: 10-15 seconds depending on internet speed. Older devices may take slightly longer for TensorFlow processing.',
  answerUr: 'آن ڈیوائس AI: 2-5 سیکنڈ۔ کلاؤڈ AI: انٹرنیٹ کی رفتار پر منحصر 10-15 سیکنڈ۔ پرانے ڈیوائسز TensorFlow پروسیسنگ کے لیے تھوڑا زیادہ وقت لے سکتے ہیں۔',
  category: FaqCategory.scanning,
  tags: ['speed', 'time', 'duration', 'performance'],
  ),

  FaqItem(
  questionEn: 'What do severity levels mean?',
  questionUr: 'شدت کی سطحوں کا کیا مطلب ہے؟',
  answerEn: 'None: No disease. Low: Early stage, easy treatment. Medium: Moderate infection, immediate action needed. High: Severe infection, intensive treatment required. Critical: Plant may not recover, consider replacement.',
  answerUr: 'کوئی نہیں: کوئی بیماری نہیں۔ کم: ابتدائی مرحلہ، آسان علاج۔ درمیانہ: اعتدال پسند انفیکشن، فوری کارروائی کی ضرورت۔ زیادہ: شدید انفیکشن، گہرے علاج کی ضرورت۔ انتہائی: پودا بحال نہیں ہو سکتا، تبدیلی پر غور کریں۔',
  category: FaqCategory.scanning,
  tags: ['severity', 'levels', 'meaning', 'stages'],
  ),

  FaqItem(
  questionEn: 'How do I track treatment progress?',
  questionUr: 'میں علاج کی پیشرفت کو کیسے ٹریک کروں؟',
  answerEn: 'Rescan your plant after applying treatment (recommended after 3-5 days). Compare severity levels and symptoms. Save all scans to your history to track healing progress over time.',
  answerUr: 'علاج لاگو کرنے کے بعد اپنے پودے کو دوبارہ اسکین کریں (3-5 دن بعد تجویز کیا جاتا ہے)۔ شدت کی سطحوں اور علامات کا موازنہ کریں۔ وقت کے ساتھ شفا یابی کی پیشرفت کو ٹریک کرنے کے لیے اپنی تاریخ میں تمام اسکینز محفوظ کریں۔',
  category: FaqCategory.scanning,
  tags: ['progress', 'tracking', 'treatment', 'monitoring'],
  ),

  // ==================== DATABASE FAQs (5 questions) ====================
  FaqItem(
  questionEn: 'How often is the plant database updated?',
  questionUr: 'پودوں کا ڈیٹا بیس کتنی بار اپ ڈیٹ ہوتا ہے؟',
  answerEn: 'The TensorFlow model and plant database receive quarterly updates with improved accuracy, new plant species, additional diseases, and enhanced features. Updates are automatically applied when you update the app.',
  answerUr: 'TensorFlow ماڈل اور پودوں کا ڈیٹا بیس سہ ماہی اپ ڈیٹس حاصل کرتے ہیں جن میں بہتر درستگی، نئی پودوں کی اقسام، اضافی بیماریاں، اور بہتر خصوصیات شامل ہیں۔ جب آپ ایپ کو اپ ڈیٹ کرتے ہیں تو اپ ڈیٹس خودکار طور پر لاگو ہو جاتی ہیں۔',
  category: FaqCategory.database,
  tags: ['updates', 'database', 'model', 'TensorFlow'],
  ),

  FaqItem(
  questionEn: 'Can I suggest new plant species or diseases?',
  questionUr: 'کیا میں نئی پودوں کی اقسام یا بیماریاں تجویز کر سکتا ہوں؟',
  answerEn: 'Yes! Go to Settings > Suggest New Plants or use the Feedback option to request additional species or diseases. We review all suggestions for future model updates.',
  answerUr: 'جی ہاں! سیٹنگز > نئے پودوں کی تجویز پر جائیں یا اضافی اقسام یا بیماریوں کی درخواست کے لیے فیڈ بیک آپشن استعمال کریں۔ ہم مستقبل کے ماڈل اپ ڈیٹس ک�� لیے تمام تجاویز کا جائزہ لیتے ہیں۔',
  category: FaqCategory.database,
  tags: ['suggestions', 'new species', 'feedback'],
  ),

  FaqItem(
  questionEn: 'How large is the TensorFlow model?',
  questionUr: 'TensorFlow ماڈل کتنا بڑا ہے؟',
  answerEn: 'The optimized TensorFlow Lite model is approximately 45MB for plant identification and 40MB for disease detection, totaling ~85MB. Designed for mobile devices with minimal storage impact while maintaining high accuracy.',
  answerUr: 'بہتر شدہ TensorFlow Lite ماڈل پودوں کی شناخت کے لیے تقریباً 45MB اور بیماری کی تشخیص کے لیے 40MB ہے، کل ~85MB۔ اعلیٰ درستگی برقرار رکھتے ہوئے کم سے کم سٹوریج اثر کے ساتھ موبائل ڈیوائسز کے لیے ڈیزائن کیا گیا ہے۔',
  category: FaqCategory.database,
  tags: ['model size', 'storage', 'TensorFlow Lite', 'optimized'],
  ),

  FaqItem(
  questionEn: 'What happens if my plant is not in the database?',
  questionUr: 'اگر میرا پودا ڈیٹا بیس میں نہیں ہے تو کیا ہوتا ہے؟',
  answerEn: 'If your plant species is not supported, the app will show "Unknown" or suggest the closest match. You can submit a request to add the plant to our database through Settings > Suggest New Plants.',
  answerUr: 'اگر آپ کے پودوں کی قسم معاون نہیں ہے، تو ایپ "نامعلوم" دکھائے گی یا قریب ترین مماثلت تجویز کرے گی۔ آپ سیٹنگز > نئے پودوں کی تجویز کے ذریعے پودے کو ہمارے ڈیٹا بیس میں شامل کرنے کی درخواست جمع کرا سکتے ہیں۔',
  category: FaqCategory.database,
  tags: ['unknown', 'not found', 'unsupported', 'request'],
  ),

  FaqItem(
  questionEn: 'How does the AI model learn and improve?',
  questionUr: 'AI ماڈل کیسے سیکھتا اور بہتر ہوتا ہے؟',
  answerEn: 'Our TensorFlow model is trained on thousands of plant images. User feedback, reported issues, and new plant submissions help us retrain and improve the model with each quarterly update.',
  answerUr: 'ہمارا TensorFlow ماڈل ہزاروں پودوں کی تصاویر پر تربیت یافتہ ہے۔ صارف کی رائے، رپورٹ شدہ مسائل، اور نئے پودوں کی جمع کرانے سے ہمیں ہر سہ ماہی اپ ڈیٹ کے ساتھ ماڈل کو دوبارہ تربیت دینے اور بہتر بنانے میں مدد ملتی ہے۔',
  category: FaqCategory.database,
  tags: ['learning', 'AI', 'training', 'improvement'],
  ),

  // ==================== ACCOUNT FAQs (7 questions) ====================
  FaqItem(
  questionEn: 'Do I need an account to use the app?',
  questionUr: 'کیا مجھے ایپ استعمال کرنے کے لیے اکاؤنٹ کی ضرورت ہے؟',
  answerEn: 'No account is required for basic scanning features. Creating an account allows you to save scan history, sync across devices, access cloud AI, and get premium features.',
  answerUr: 'بنیادی اسکیننگ خصوصیات کے لیے کسی اکاؤنٹ کی ضرورت نہیں ہے۔ اکاؤنٹ بنانے سے آپ اسکین ہسٹری محفوظ کر سکتے ہیں، ڈیوائسز میں سنک کر سکتے ہیں، کلاؤڈ AI تک رسائی حاصل کر سکتے ہیں، اور پریمیم خصوصیات حاصل کر سکتے ہیں۔',
  category: FaqCategory.account,
  tags: ['account', 'registration', 'optional'],
  ),

  FaqItem(
  questionEn: 'How do I create an account?',
  questionUr: 'میں اکاؤنٹ کیسے بناؤں؟',
  answerEn: 'Tap Profile > Sign Up. You can create an account using email, Google, or Apple Sign-In. Creating an account unlocks scan history, cloud sync, and premium features.',
  answerUr: 'پروفائل > سائن اپ پر ٹیپ کریں۔ آپ ای میل، گوگل، یا ایپل سائن ان استعمال کرکے اکاؤنٹ بنا سکتے ہیں۔ اکاؤنٹ بنانے سے اسکین ہسٹری، کلاؤڈ سنک، اور پریمیم خصوصیات غیر مقفل ہو جاتی ہیں۔',
  category: FaqCategory.account,
  tags: ['sign up', 'register', 'create', 'account'],
  ),

  FaqItem(
  questionEn: 'How do I save my scan history?',
  questionUr: 'میں اپنی اسکین ہسٹری کیسے محفوظ کروں؟',
  answerEn: 'Scan history is automatically saved locally. With an account, your history syncs to the cloud and can be accessed from any device. View history from Profile > Scan History.',
  answerUr: 'اسکین ہسٹری خودکار طور پر مقامی طور پر محفوظ ہوتی ہے۔ اکاؤنٹ کے ساتھ، آپ کی تاریخ کلاؤڈ سے ہم آہنگ ہوتی ہے اور کسی بھی ڈیوائس سے رسائی حاصل کی جا سکتی ہے۔ پروفائل > اسکین ہسٹری سے تاریخ دیکھیں۔',
  category: FaqCategory.account,
  tags: ['history', 'save', 'cloud', 'sync'],
  ),

  FaqItem(
  questionEn: 'Is my plant data private?',
  questionUr: 'کیا میرے پودے کا ڈیٹا نجی ہے؟',
  answerEn: 'Yes! All plant scans and photos are processed locally on your device with On-Device AI. We never upload your plant images to our servers without your permission. Cloud AI requires image upload but data is encrypted and auto-deleted after 30 days.',
  answerUr: 'جی ہاں! تمام پودوں کے اسکینز اور تصاویر آن ڈیوائس AI کے ساتھ آپ کے ڈیوائس پر مقامی طور پر پروسیس ہوتی ہیں۔ ہم آپ کی اجازت کے بغیر کبھی بھی آپ کے پودوں کی تصاویر اپنے سرورز پر اپ لوڈ نہیں کرتے۔ کلاؤڈ AI کو تصویر اپ لوڈ کی ضرورت ہوتی ہے لیکن ڈیٹا خفیہ کیا جاتا ہے اور 30 دنوں بعد خودکار طور پر حذف ہو جاتا ہے۔',
  category: FaqCategory.account,
  tags: ['privacy', 'data', 'local processing', 'security'],
  ),

  FaqItem(
  questionEn: 'Can I use AgriGuard on multiple devices?',
  questionUr: 'کیا میں متعدد ڈیوائسز پر AgriGuard استعمال کر سکتا ہوں؟',
  answerEn: 'Yes! Sign in with your account on multiple devices to sync scan history, settings, and preferences. On-Device AI works independently on each device without internet.',
  answerUr: 'جی ہاں! اسکین ہسٹری، سیٹنگز، اور ترجیحات کو ہم آہنگ کرنے کے لیے متعدد ڈیوائسز پر اپنے اکاؤنٹ کے ساتھ سائن ان کریں۔ آن ڈیوائس AI ہر ڈیوائس پر انٹرنیٹ کے بغیر آزادانہ طور پر کام کرتا ہے۔',
  category: FaqCategory.account,
  tags: ['multiple devices', 'sync', 'cloud', 'cross-device'],
  ),

  FaqItem(
  questionEn: 'How do I delete my account and data?',
  questionUr: 'میں اپنا اکاؤنٹ اور ڈیٹا کیسے حذف کروں؟',
  answerEn: 'Go to Profile > Settings > Account > Delete Account. This will permanently delete your account, scan history, and all associated data from our servers. Local data on your device will also be cleared.',
  answerUr: 'پروفائل > سیٹنگز > اکاؤنٹ > اکاؤنٹ حذف کریں پر جائیں۔ یہ مستقل طور پر آپ کا اکاؤنٹ، اسکین ہسٹری، اور ہمارے سرورز سے تمام منسلک ڈیٹا حذف کر دے گا۔ آپ کے ڈیوائس پر مقامی ڈیٹا بھی صاف کر دیا جائے گا۔',
  category: FaqCategory.account,
  tags: ['delete', 'remove', 'data', 'privacy'],
  ),

  FaqItem(
  questionEn: 'What are Guest Mode limitations?',
  questionUr: 'مہمان موڈ کی حدود کیا ہیں��',
  answerEn: 'Guest Mode allows 10 free scans without creating an account. After reaching the limit, you need to sign in for unlimited scans. Guest scans are not saved and cannot be synced across devices.',
  answerUr: 'مہمان موڈ اکاؤنٹ بنائے بغیر 10 مفت اسکینز کی اجازت دیتا ہے۔ حد تک پہنچنے کے بعد، آپ کو لامحدود اسکینز کے لیے سائن ان کرنا ہوگا۔ مہمان اسکینز محفوظ نہیں ہوتے اور ڈیوائسز میں ہم آہنگ نہیں ہو سکتے۔',
  category: FaqCategory.account,
  tags: ['guest', 'limitations', 'free', 'scans'],
  ),

  // ==================== TECHNICAL FAQs (10 questions) ====================
  FaqItem(
  questionEn: 'What are the system requirements?',
  questionUr: 'سسٹم کی ضروریات کیا ہیں؟',
  answerEn: 'Android: 7.0+ with 2GB RAM. iOS: 13.0+. Requires camera permission and 100MB free storage for the TensorFlow models. Works best on devices with 3GB+ RAM.',
  answerUr: 'اینڈرائیڈ: 7.0+ 2GB RAM کے ساتھ۔ iOS: 13.0+۔ TensorFlow ماڈلز کے لیے کیمرہ کی اجازت اور 100MB خالی اسٹوریج کی ضرورت ہے۔ 3GB+ RAM والے ڈیوائسز پر بہترین کام کرتا ہے۔',
  category: FaqCategory.technical,
  tags: ['requirements', 'compatibility', 'devices'],
  ),

  FaqItem(
  questionEn: 'Why is scanning taking longer than expected?',
  questionUr: 'اسکیننگ میں توقع سے زیادہ وقت کیوں لگ رہا ہے؟',
  answerEn: 'Scan time depends on device processor. Average scan time is 2-5 seconds for On-Device AI. Older devices may take up to 10 seconds for TensorFlow processing. Close background apps to improve speed.',
  answerUr: 'اسکین کا وقت ڈیوائس پروسیسر پر منحصر ہے۔ آن ڈیوائس AI کے لیے اوسط اسکین وقت 2-5 سیکنڈ ہے۔ پرانے ڈیوائسز TensorFlow پروسیسنگ کے لیے 10 سیکنڈ تک لے سکتے ہیں۔ رفتار بہتر بنانے کے لیے پس منظر کی ایپس بند کریں۔',
  category: FaqCategory.technical,
  tags: ['performance', 'speed', 'scan time', 'processing'],
  ),

  FaqItem(
  questionEn: 'How do I improve scanning accuracy?',
  questionUr: 'میں اسکیننگ کی درستگی کیسے بہتر بنا سکتا ہوں؟',
  answerEn: 'Ensure good lighting, focus on clear plant features, avoid multiple plants in one image, and keep camera steady. The TensorFlow model works best with clear, well-lit images showing affected areas.',
  answerUr: 'اچھی روشنی کو یقینی بنائیں، واضح پودوں کی خصوصیات پر توجہ دیں، ایک تصویر میں متعدد پودوں سے بچیں، اور کیمرہ کو مستحکم رکھیں۔ TensorFlow ماڈل متاثرہ علاقوں کو دکھانے والی صاف، اچھی طرح روشن تصاویر کے ساتھ بہترین کام کرتا ہے۔',
  category: FaqCategory.technical,
  tags: ['accuracy', 'improve', 'tips', 'TensorFlow'],
  ),

  FaqItem(
  questionEn: 'Can I use the app in low light conditions?',
  questionUr: 'کیا میں کم روشنی میں ایپ استعمال کر سکتا ہوں؟',
  answerEn: 'While possible, low light significantly reduces accuracy. We recommend using flash or moving to better lighting for reliable TensorFlow analysis. Minimum 300 lux lighting is recommended.',
  answerUr: 'اگرچہ ممکن ہے، کم روشنی درستگی کو نمایاں طور پر کم کرتی ہے۔ ہم قابل اعتماد TensorFlow تجزیہ کے لیے فلیش استعمال کرنے یا بہتر روشنی میں جانے کی سفارش کرتے ہیں۔ کم از کم 300 لکس روشنی کی سفارش کی جاتی ہے۔',
  category: FaqCategory.technical,
  tags: ['lighting', 'conditions', 'accuracy', 'flash'],
  ),

  FaqItem(
  questionEn: 'Why does the app need camera permission?',
  questionUr: 'ایپ کو کیمرہ کی اجازت کی ضرورت کیوں ہے؟',
  answerEn: 'Camera permission is required to capture plant images for analysis. Without camera access, you can only upload photos from your gallery. The app never accesses your camera without your action.',
  answerUr: 'تجزیہ کے لیے پودوں کی تصاویر کیپچر کرنے کے لیے کیمرہ کی اجازت کی ضرورت ہے۔ کیمرہ تک رسائی کے بغیر، آپ صرف اپنی گیلری سے تصاویر اپ لوڈ کر سکتے ہیں۔ ایپ کبھی بھی آپ کی کارروائی کے بغیر آپ کے کیمرہ تک رسائی حاصل نہیں کرتی۔',
  category: FaqCategory.technical,
  tags: ['permission', 'camera', 'privacy', 'access'],
  ),

  FaqItem(
  questionEn: 'Does AgriGuard work on tablets?',
  questionUr: 'کیا AgriGuard ٹیبلٹس پر کام کرتا ہے؟',
  answerEn: 'Yes! AgriGuard is optimized for both phones and tablets. The larger screen on tablets provides better image preview and more detailed result displays.',
  answerUr: 'جی ہاں! AgriGuard فونز اور ٹیبلٹس دون��ں کے لیے بہتر بنایا گیا ہے۔ ٹیبلٹس پر بڑی اسکرین بہتر تصویر کا پیش نظارہ اور زیادہ تفصیلی نتیجہ ڈسپلے فراہم کرتی ہے۔',
  category: FaqCategory.technical,
  tags: ['tablet', 'iPad', 'compatibility', 'screen'],
  ),

  FaqItem(
  questionEn: 'How much data does Cloud AI use?',
  questionUr: 'کلاؤڈ AI کتنا ڈیٹا استعمال کرتا ہے؟',
  answerEn: 'Cloud AI analysis uses approximately 2-5MB per scan depending on image size. Recommended to use WiFi for multiple scans to avoid mobile data charges.',
  answerUr: 'کلاؤڈ AI تجزیہ تصویر کے سائز پر منحصر ہر اسکین کے لیے تقریباً 2-5MB استعمال کرتا ہے۔ موبائل ڈیٹا چارجز سے بچنے کے لیے متعدد اسکینز کے لیے WiFi استعمال کرنے کی سفارش کی جاتی ہے۔',
  category: FaqCategory.technical,
  tags: ['data usage', 'cloud', 'internet', 'mobile'],
  ),

  FaqItem(
  questionEn: 'Why is the app size large?',
  questionUr: 'ایپ کا سائز بڑا کیوں ہے؟',
  answerEn: 'The app includes two TensorFlow Lite models (~85MB total) for offline plant identification and disease detection. This allows the app to work without internet connection.',
  answerUr: 'ایپ میں آف لائن پودوں کی شناخت اور بیماری کی تشخیص کے لیے دو TensorFlow Lite ماڈلز (~85MB کل) شامل ہیں۔ یہ ایپ کو انٹرنیٹ کنکشن کے بغیر کام کرنے کی اجازت دیتا ہے۔',
  category: FaqCategory.technical,
  tags: ['size', 'storage', 'download', 'models'],
  ),

  FaqItem(
  questionEn: 'Can I use AgriGuard offline after downloading?',
  questionUr: 'کیا میں ڈاؤن لوڈ کرنے کے بعد AgriGuard کو آف لائن استعمال کر سکتا ہوں؟',
  answerEn: 'Yes! After first launch, all AI models are downloaded and cached. You can use On-Device AI analysis completely offline. Cloud AI and history sync require internet connection.',
  answerUr: 'جی ہاں! پہلی لانچ کے بعد، تمام AI ماڈلز ڈاؤن لوڈ اور کیش ہو جاتے ہیں۔ آپ آن ڈیوائس AI تجزیہ کو مکمل طور پر آف لائن استعمال کر سکتے ہیں۔ کلاؤڈ AI اور ہسٹری سنک کو انٹرنیٹ کنکشن کی ضرورت ہوتی ہے۔',
  category: FaqCategory.technical,
  tags: ['offline', 'download', 'cache', 'models'],
  ),

  FaqItem(
  questionEn: 'What should I do if the app crashes?',
  questionUr: 'اگر ایپ کریش ہو جائے تو مجھے کیا کرنا چاہیے؟',
  answerEn: 'Try: 1) Force close and restart the app, 2) Clear app cache in Settings, 3) Update to the latest version, 4) Restart your device, 5) Reinstall the app if problem persists. Contact support if issue continues.',
  answerUr: 'آزمائیں: 1) ایپ کو زبردستی بند کریں اور دوبارہ شروع کریں، 2) سیٹنگز میں ایپ کیش صاف کریں، 3) تازہ ترین ورژن میں اپ ڈیٹ کریں، 4) اپنے ڈیوائس کو دوبارہ شروع کریں، 5) اگر مسئلہ برقرار رہے تو ایپ کو دوبارہ انسٹال کریں۔ اگر مسئلہ جاری رہے تو سپورٹ سے رابطہ کریں۔',
  category: FaqCategory.technical,
  tags: ['crash', 'bug', 'error', 'troubleshoot'],
  ),

  // ==================== SHARING FAQs (4 questions) ====================
  FaqItem(
    questionEn: 'How do I share scan results with others?',
    questionUr: 'میں دوسروں کے ساتھ اسکین کے نتائج کیسے شیئر کروں؟',
    answerEn: 'Tap the share icon on any result screen to export plant details, disease information, and treatment recommendations via email, messaging, WhatsApp, or social media.',
    answerUr: 'ای میل، میسیجنگ، واٹس ایپ، یا سوشل میڈیا کے ذریعے پودے کی تفصیلات، بیماری کی معلومات، اور علاج کی سفارشات برآمد کرنے کے لیے کسی بھی نتیجہ اسکرین پر شیئر آئیکن پر ٹیپ کریں۔',
    category: FaqCategory.sharing,
    tags: ['sharing', 'export', 'results', 'social'],
  ),

    FaqItem(
      questionEn: 'Can I export my scan history for my records?',
      questionUr: 'کیا میں اپنے ریکارڈ کے لیے اپنی اسکین ہسٹری برآمد کر سکتا ہوں؟',
      answerEn: 'Yes! Go to History > Export to download your complete scan history as PDF or CSV, including all plants, diseases, dates, severity levels, and treatment plans.',
      answerUr: 'جی ہاں! تاریخ > برآمد پر جائیں تاکہ اپنی مکمل اسکین ہسٹری کو PDF یا CSV کے طور پر ڈاؤن لوڈ کریں، بشمول تمام پودے، بیماریاں، تاریخیں، شدت کی سطحیں، اور علاج کے منصوبے۔',
      category: FaqCategory.sharing,
      tags: ['export', 'history', 'backup', 'records'],
    ),

    FaqItem(
      questionEn: 'How do I report incorrect identification?',
      questionUr: 'میں غلط شناخت کی اطلاع کیسے دوں؟',
      answerEn: 'From the results screen, tap "Report Issue" to help us improve our TensorFlow model. Provide feedback on what you think is incorrect. Your feedback helps train better AI models.',
      answerUr: 'نتائج کی اسکرین سے، ہمارے TensorFlow ماڈل کو بہتر بنانے میں مدد کے لیے "مسئلہ کی اطلاع دیں" پر ٹیپ کریں۔ جو آپ کو غلط لگتا ہے اس پر رائے دیں۔ آپ کی رائے بہتر AI ماڈلز کی تربیت میں مدد کرتی ہے۔',
      category: FaqCategory.sharing,
      tags: ['feedback', 'report', 'improve', 'TensorFlow'],
    ),

    FaqItem(
      questionEn: 'Can I share results with agricultural experts?',
      questionUr: 'کیا میں زرعی ماہرین کے ساتھ نتائج شیئر کر سکتا ہوں؟',
      answerEn: 'Yes! Use "Generate PDF" to create a professional report with all scan details. Share via email to consult with agricultural experts, extension officers, or plant pathologists.',
      answerUr: 'جی ہاں! تمام اسکین کی تفصیلات کے ساتھ ایک پیشہ ورانہ رپورٹ بنانے کے لیے "PDF بنائیں" استعمال کریں۔ زرعی ماہرین، ایکسٹینشن افسران، یا پودوں کے پیتھالوجسٹ سے مشورہ کرنے کے لیے ای میل کے ذریعے شیئر کریں۔',
      category: FaqCategory.sharing,
      tags: ['expert', 'consultation', 'professional', 'share'],
    ),

    // ==================== ADDITIONAL SCANNING FAQs ====================
    FaqItem(
      questionEn: 'Can I get PDF reports of scan results?',
      questionUr: 'کیا میں اسکین کے نتائج کی PDF رپورٹس حاصل کر سکتا ہوں؟',
      answerEn: 'Yes! Tap "Generate PDF" on any result screen to create a detailed report including plant details, disease analysis, treatment plan, and recommendations. You can save or share the PDF.',
      answerUr: 'جی ہاں! پودے کی تفصیلات، بیماری کا تجزیہ، علاج کا منصوبہ، اور سفارشات بشمول تفصیلی رپورٹ بنانے کے لیے کسی بھی نتیجہ اسکرین پر "PDF بنائیں" پر ٹیپ کریں۔ آپ PDF کو محفوظ یا شیئر کر سکتے ہیں۔',
      category: FaqCategory.scanning,
      tags: ['PDF', 'report', 'export', 'document'],
    ),

    FaqItem(
      questionEn: 'How reliable are the treatment recommendations?',
      questionUr: 'علاج کی سفارشات کتنی قابل اعتماد ہیں؟',
      answerEn: 'Treatment recommendations are based on agricultural research and expert guidelines. Always consult local agricultural experts for severe cases. Recommendations are general guidance, not professional medical advice for plants.',
      answerUr: 'علاج کی سفارشات زرعی تحقیق اور ماہرین کی رہنمائی پر مبنی ہیں۔ شدید معاملات کے لیے ہمیشہ مقامی زرعی ماہرین سے مشورہ کریں۔ سفارشات عام رہنمائی ہیں، پودوں کے لیے پیشہ ورانہ طبی مشورہ نہیں۔',
      category: FaqCategory.scanning,
      tags: ['treatment', 'recommendations', 'reliability', 'expert'],
    ),

    // ==================== ADDITIONAL TECHNICAL FAQs ====================
    FaqItem(
      questionEn: 'Why can\'t I see my scan history?',
      questionUr: 'میں اپنی اسکین ہسٹری کیوں نہیں دیکھ سکتا؟',
      answerEn: 'Scan history requires signing in to your account. Guest scans are not saved. If signed in and history is missing, check internet connection for cloud sync or go to Settings > Sync Now.',
      answerUr: 'اسکین ہسٹری کو اپنے اکاؤنٹ میں سائن ان کرنے کی ضرورت ہوتی ہے۔ مہمان اسکینز محفوظ نہیں ہوتے۔ اگر سائن ان ہیں اور ہسٹری غائب ہے، تو کلاؤڈ سنک کے لیے انٹرنیٹ کنکشن چیک کریں یا سیٹنگز > ابھی سنک کریں پر جائیں۔',
      category: FaqCategory.account,
      tags: ['history', 'missing', 'sync', 'troubleshoot'],
    ),

    FaqItem(
      questionEn: 'How do I update the AI models?',
      questionUr: 'میں AI ماڈلز کو کیسے اپ ڈیٹ کروں؟',
      answerEn: 'AI models update automatically when you update the app from App Store or Play Store. Go to Settings > Check for Updates to see if new models are available.',
      answerUr: 'جب آپ ایپ اسٹور یا پلے اسٹور سے ایپ کو اپ ڈیٹ کرتے ہیں تو AI ماڈلز خودکار طور پر اپ ڈیٹ ہو جاتے ہیں۔ نئے ماڈلز دستیاب ہیں یا نہیں دیکھنے کے لیے سیٹنگز > اپ ڈیٹس کے لیے چیک کریں پر جائیں۔',
      category: FaqCategory.database,
      tags: ['update', 'models', 'upgrade', 'version'],
    ),

    FaqItem(
      questionEn: 'Why does detection show wrong results?',
      questionUr: 'تشخیص غلط نتائج کیوں دکھاتی ہے؟',
      answerEn: 'Wrong results can occur due to: 1) Poor image quality, 2) Similar-looking diseases, 3) Mixed infections, 4) Unsupported species. Try rescanning with better lighting or use Cloud AI for more accurate analysis.',
      answerUr: 'غلط نتائج ہو سکتے ہیں: 1) خراب تصویر کا معیار، 2) ملتی جلتی بیماریاں، 3) مخلوط انفیکشن، 4) غیر معاون اقسام۔ بہتر روشنی کے ساتھ دوبارہ اسکین کرنے کی کوشش کریں یا زیادہ درست تجزیہ کے لیے کلاؤڈ AI استعمال کریں۔',
      category: FaqCategory.scanning,
      tags: ['wrong', 'incorrect', 'error', 'accuracy'],
    ),

    // ==================== FEATURES & UPDATES FAQs ====================
    FaqItem(
      questionEn: 'What new features are coming soon?',
      questionUr: 'جلد کون سی نئی خصوصیات آ رہی ہیں؟',
      answerEn: 'Upcoming features: Weather-based disease prediction, Fertilizer recommendations, Pest detection, Growth tracking, Community forum, Multi-language support expansion, and AR-based scanning.',
      answerUr: 'آنے والی خصوصیات: موسم پر مبنی بیماری کی پیشن گوئی، کھاد کی سفارشات، کیڑوں کی تشخیص، نشوونما کی ٹریکنگ، کمیونٹی فورم، کثیر لسانی سپورٹ کی توسیع، اور AR پر مبنی اسکیننگ۔',
      category: FaqCategory.general,
      tags: ['future', 'upcoming', 'roadmap', 'features'],
    ),

    FaqItem(
      questionEn: 'How do I enable dark mode?',
      questionUr: 'میں ڈارک موڈ کیسے فعال کروں؟',
      answerEn: 'Go to Profile > Settings > Appearance > Theme and select Dark Mode. You can also choose Auto to follow your system theme settings.',
      answerUr: 'پروفائل > سیٹنگز > ظاہری شکل > تھیم پر جائیں اور ڈارک موڈ منتخب کریں۔ آپ اپنے سسٹم تھیم کی سیٹنگز کی پیروی کرنے کے لیے آٹو بھی منتخب کر سکتے ہیں۔',
      category: FaqCategory.general,
      tags: ['dark mode', 'theme', 'appearance', 'settings'],
    ),

    FaqItem(
      questionEn: 'Can I change the language?',
      questionUr: 'کیا میں زبان تبدیل کر سکتا ہوں؟',
      answerEn: 'Yes! Tap the language toggle button (EN/اردو) in the app bar or go to Settings > Language. Currently supports English and Urdu with more languages coming soon.',
      answerUr: 'جی ہاں! ایپ بار میں لینگویج ٹوگل بٹن (EN/اردو) پر ٹیپ کریں یا سیٹنگز > زبان پر جائیں۔ فی الوقت انگریزی اور اردو کو سپورٹ کرتا ہے جلد مزید زبانیں آ رہی ہیں۔',
      category: FaqCategory.general,
      tags: ['language', 'translation', 'multilingual', 'settings'],
    ),

    FaqItem(
      questionEn: 'How do I contact support?',
      questionUr: 'میں سپورٹ سے کیسے رابطہ کروں؟',
      answerEn: 'Go to Profile > Help & Support. You can send a message via the contact form, email us at agriguardsupport@gmail.com, call +92 341 4279749, or reach out on Instagram @agriguard.',
      answerUr: 'پروفائل > مدد اور سپورٹ پر جائیں۔ آپ رابطہ فارم کے ذریعے پیغام بھیج سکتے ہیں، ہمیں agriguardsupport@gmail.com پر ای میل کریں، +92 341 4279749 پر کال کریں، یا انسٹاگرام @agriguard پر رابطہ کریں۔',
      category: FaqCategory.general,
      tags: ['support', 'contact', 'help', 'customer service'],
    ),

    // ==================== MORE TECHNICAL TROUBLESHOOTING ====================
    FaqItem(
      questionEn: 'The app is running slow. What should I do?',
      questionUr: 'ایپ سست چل رہی ہے۔ مجھے کیا کرنا چاہیے؟',
      answerEn: 'Try: 1) Close background apps, 2) Clear app cache (Settings > Storage > Clear Cache), 3) Restart your device, 4) Free up device storage (need 100MB+ free), 5) Update to latest version.',
      answerUr: 'آزمائیں: 1) پس منظر کی ایپس بند کریں، 2) ایپ کیش صاف کریں (سیٹنگز > اسٹوریج > کیش صاف کریں)، 3) اپنے ڈیوائس کو دوبارہ شروع کریں، 4) ڈیوائس اسٹوریج خالی کریں (100MB+ خالی کی ضرورت ہے)، 5) تازہ ترین ورژن میں اپ ڈیٹ کریں۔',
      category: FaqCategory.technical,
      tags: ['slow', 'performance', 'lag', 'optimization'],
    ),

    FaqItem(
      questionEn: 'Camera is not working in the app. How to fix?',
      questionUr: 'ایپ میں کیمرہ کام نہیں کر رہا۔ کیسے ٹھیک کریں؟',
      answerEn: 'Check: 1) Camera permission enabled in device Settings, 2) Another app is not using the camera, 3) Restart the app, 4) Restart your device, 5) Reinstall the app if issue persists.',
      answerUr: 'چیک کریں: 1) ڈیوائس سیٹنگز میں کیمرہ کی اجازت فعال ہے، 2) کوئی دوسری ایپ کیمرہ استعمال نہیں کر رہی، 3) ایپ کو دوبارہ شروع کریں، 4) اپنے ڈیوائس کو دوبارہ شروع کریں، 5) اگر مسئلہ برقرار رہے تو ایپ کو دوبارہ انسٹال کریں۔',
      category: FaqCategory.technical,
      tags: ['camera', 'not working', 'permission', 'fix'],
    ),

    FaqItem(
      questionEn: 'How do I report a bug or issue?',
      questionUr: 'میں ایک بگ یا مسئلہ کی اطلاع کیسے دوں؟',
      answerEn: 'Go to Profile > Help & Support > Report Issue. Describe the problem in detail, include screenshots if possible. Our team will investigate and respond within 24-48 hours.',
      answerUr: 'پروفائل > مدد اور سپورٹ > مسئلہ کی اطلاع دیں پر جائیں۔ مسئلہ کو تفصیل سے بیان کریں، اگر ممکن ہو تو اسکرین شاٹس شامل کریں۔ ہماری ٹیم تحقیقات کرے گی اور 24-48 گھنٹوں میں جواب دے گی۔',
      category: FaqCategory.general,
      tags: ['bug', 'report', 'issue', 'feedback'],
    ),

    // ==================== ACCOUNT SECURITY ====================
    FaqItem(
      questionEn: 'How do I change my password?',
      questionUr: 'میں اپنا پاس ورڈ کیسے تبدیل کروں؟',
      answerEn: 'Go to Profile > Settings > Account > Change Password. Enter your current password, then your new password twice to confirm. Passwords must be at least 8 characters long.',
      answerUr: 'پروفائل > سیٹنگز > اکاؤنٹ > پاس ورڈ تبدیل کریں پر جائیں۔ اپنا موجودہ پاس ورڈ درج کریں، پھر تصدیق کے لیے اپنا نیا پاس ورڈ دو بار درج کریں۔ پاس ورڈز کم از کم 8 حروف طویل ہونے چاہئیں۔',
      category: FaqCategory.account,
      tags: ['password', 'security', 'change', 'account'],
    ),

    FaqItem(
      questionEn: 'I forgot my password. How do I reset it?',
      questionUr: 'میں اپنا پاس ورڈ بھول گیا۔ میں اسے کیسے ری سیٹ کروں؟',
      answerEn: 'On the login screen, tap "Forgot Password". Enter your email address and we\'ll send you a password reset link. Click the link in the email to create a new password.',
      answerUr: 'لاگ ان اسکرین پر، "پاس ورڈ بھول گئے" پر ٹیپ کریں۔ اپنا ای میل ایڈریس درج کریں اور ہم آپ کو پاس ورڈ ری سیٹ لنک بھیجیں گے۔ نیا پاس ورڈ بنانے کے لیے ای میل میں لنک پر کلک کریں۔',
      category: FaqCategory.account,
      tags: ['forgot password', 'reset', 'recovery', 'login'],
    ),

    // ==================== PREMIUM & PRICING ====================
    FaqItem(
      questionEn: 'What are the premium features?',
      questionUr: 'پریمیم خصوصیات کیا ہیں؟',
      answerEn: 'Premium includes: Unlimited Cloud AI scans, Advanced disease analysis, Expert treatment recommendations, PDF report generation, Scan history sync, Priority support, and Ad-free experience.',
      answerUr: 'پریمیم میں شامل ہیں: لامحدود کلاؤڈ AI اسکینز، جدید بیماری کا تجزیہ، ماہرین کے علاج کی سفارشات، PDF رپورٹ کی تخلیق، اسکین ہسٹری سنک، ترجیحی سپورٹ، اور اشتہار سے پاک تجربہ۔',
      category: FaqCategory.general,
      tags: ['premium', 'features', 'subscription', 'paid'],
    ),

    FaqItem(
      questionEn: 'How much does premium cost?',
      questionUr: 'پریمیم کی قیمت کتنی ہے؟',
      answerEn: 'Premium subscription costs vary by region. Typical pricing: Monthly - 4.99, Yearly - 39.99 (save 33%). Check the app for exact pricing in your region.',
      answerUr: 'پریمیم سبسکرپشن کی قیمتیں علاقے کے لحاظ سے مختلف ہوتی ہیں۔ عام قیمتیں: ماہانہ - .99، سالانہ - 39.99 (33% بچت)۔ اپنے علاقے میں درست قیمت کے لیے ایپ چیک کریں۔',
      category: FaqCategory.general,
      tags: ['pricing', 'cost', 'subscription', 'premium'],
    ),

    // ==================== OFFLINE FUNCTIONALITY ====================
    FaqItem(
      questionEn: 'What features work offline?',
      questionUr: 'کون سی خصوصیات آف لائن کام کرتی ہیں؟',
      answerEn: 'Offline features: On-Device AI scanning, Plant identification, Disease detection, Treatment recommendations (basic), View saved scan history. Requires internet: Cloud AI, History sync, PDF export, Updates.',
      answerUr: 'آف لائن خصوصیات: آن ڈیوائس AI اسکیننگ، پودوں کی شناخت، بیماری کی تشخیص، علاج کی سفارشات (بنیادی)، محفوظ اسکین ہسٹری دیکھیں۔ انٹرنیٹ کی ضرورت: کلاؤڈ AI، ہسٹری سنک، PDF برآمد، اپ ڈیٹس۔',
      category: FaqCategory.technical,
      tags: ['offline', 'features', 'internet', 'connectivity'],
    ),

    // ==================== FINAL COUNT: 50+ BILINGUAL FAQs ====================
  ];
}