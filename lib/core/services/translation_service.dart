import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService extends ChangeNotifier {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  bool _isUrdu = false;
  bool get isUrdu => _isUrdu;

  static const String _languageKey = 'capture_screen_language';

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _isUrdu = prefs.getBool(_languageKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _isUrdu = !_isUrdu;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_languageKey, _isUrdu);
    notifyListeners();
  }

  String get(String key) {
    return _isUrdu ? _urduTranslations[key] ?? key : _englishTranslations[key] ?? key;
  }

  // English translations
  static const Map<String, String> _englishTranslations = {
    // App Bar
    'app_title': 'AGRIGUARD',
    'analysis_method': 'Analysis Method',
    'image_source': 'Image Source',
    'analyzing': 'Analyzing...',

    // Welcome Screen
    'welcome_title': 'Plant Disease Detection',
    'welcome_subtitle': 'AI-Powered Agricultural Assistant',
    'welcome_description': 'Identify plant diseases instantly using advanced AI technology',
    'start_scanning': 'Start Scanning',
    'models_loading': 'Loading AI Models...',
    'models_ready': 'AI Models Ready',
    'plant_id_model': 'Plant ID Model',
    'disease_model': 'Disease Model',
    'guest_mode': 'Guest Mode',
    'remaining_scans': 'Remaining Scans',

    // Method Selection
    'method_title': 'Choose Analysis Method',
    'method_subtitle': 'Select how you want to analyze your plant',
    'on_device': 'On-Device AI',
    'on_device_desc': 'Fast • Offline • Free',
    'on_device_features': '• Works without internet\n• Instant results\n• 100% private\n• Free unlimited scans',
    'advanced_ai': 'Advanced AI',
    'advanced_ai_desc': 'Accurate • Detailed • Expert',
    'advanced_ai_features': '• Cloud-based analysis\n• Expert recommendations\n• Detailed treatment plans\n• Weather integration',
    'model_loading': 'Loading AI models...',
    'model_plant': 'Plant Identification',
    'model_disease': 'Disease Detection',

    // Source Selection
    'source_title': 'Select Image Source',
    'source_subtitle': 'How would you like to capture the plant?',
    'camera': 'Camera',
    'camera_desc': 'Take a photo now',
    'camera_tip': 'Best for instant analysis',
    'gallery': 'Gallery',
    'gallery_desc': 'Choose existing photo',
    'gallery_tip': 'Select from your photos',
    'capture_tips': 'Capture Tips',
    'tip_1': 'Use good lighting',
    'tip_2': 'Focus on affected areas',
    'tip_3': 'Include whole leaf',
    'tip_4': 'Avoid shadows',

    // Processing
    'processing_title': 'Analyzing Your Plant',
    'processing_ai': 'Running Dual AI Analysis...',
    'processing_plant': '• Plant Identification',
    'processing_disease': '• Disease Detection',
    'processing_wait': 'This may take a few moments...',
    'cancel': 'Cancel',
    'dismiss': 'Dismiss',

    // Errors
    'error_pick_image': 'Failed to pick image. Please try again.',
    'error_load_models': 'Failed to load AI models. Please restart the app.',
    'error_sign_in': 'Please sign in to continue',
    'error_file_not_found': 'Image file not found',

    // Guest Limit
    'limit_reached': 'Scan Limit Reached',
    'limit_message': 'You have reached your free scan limit',
    'limit_benefit': 'Sign up for unlimited scans and advanced features!',
    'sign_in_now': 'Sign In Now',

    // Info Dialog
    'info_title': 'How It Works',
    'info_step1': 'Select Analysis Method',
    'info_step1_desc': 'Choose between fast on-device AI or advanced cloud analysis',
    'info_step2': 'Capture Image',
    'info_step2_desc': 'Take a clear photo of the affected plant or leaf',
    'info_step3': 'Get Results',
    'info_step3_desc': 'Receive instant diagnosis and treatment recommendations',
    'info_tips': 'Tips for Best Results',
    'info_tip1': '📸 Use natural lighting',
    'info_tip2': '🎯 Focus on diseased areas',
    'info_tip3': '📏 Include whole leaf if possible',
    'info_tip4': '🔍 Avoid blurry images',
    'got_it': 'Got It',

    // How It Works
    'how_it_works': 'How It Works',
    'take_photo': 'Take Photo',
    'choose_method': 'Choose Method',
    'ai_analysis': 'AI Analysis',
    'get_results': 'Get Results',
    'step1_text': 'Capture or upload a clear photo of the plant leaf',
    'step2_text': 'Choose between fast on-device or detailed cloud analysis',
    'step3_text': 'Our AI analyzes the image for identification',
    'step4_text': 'Receive instant diagnosis and treatment advice',

    // Guest Stats
    'guest_stats_title': 'Guest Mode',
    'guest_stats_scans': 'scans remaining',
    'guest_stats_signup': 'Sign up for unlimited scans and save your history',

    // Feature Highlights
    'features_title': 'Key Features',
    'feature_identify': 'Identify Plants',
    'feature_identify_desc': '50,000+ species',
    'feature_disease': 'Disease Detection',
    'feature_disease_desc': 'Common diseases',
    'feature_treatment': 'Treatment Plans',
    'feature_treatment_desc': 'Expert advice',
    'feature_offline': 'Offline Mode',
    'feature_offline_desc': 'No internet needed',

    // Comparison Table
    'comparison_title': 'Method Comparison',
    'comparison_subtitle': 'Choose what suits you best',
    'comparison_ondevice': 'On-Device',
    'comparison_cloudai': 'Cloud AI',
    'comparison_internet': 'Internet',
    'comparison_not_required': 'Not Required',
    'comparison_required': 'Required',
    'comparison_speed': 'Speed',
    'comparison_instant': 'Instant',
    'comparison_database': 'Database',
    'comparison_species': 'Species',
    'comparison_privacy': 'Privacy',
    'comparison_private': '100% Private',
    'comparison_cloud_based': 'Cloud Based',
    'comparison_bestfor': 'Best For',
    'comparison_quick': 'Quick Checks',
    'comparison_deep': 'Deep Analysis',

    // Processing Overlay
    'processing_analyzing': 'Analyzing Your Plant',
    'processing_ondevice_subtitle': 'Using on-device AI for instant results',
    'processing_cloud_subtitle': 'Connecting to cloud AI for detailed analysis',
    'processing_image_captured': 'Image Captured',
    'processing_analyzing_stage': 'Analyzing',
    'processing_generating': 'Generating Report',
    'processing_text': 'Processing...',
    'processing_guest_scans': 'scans remaining in guest mode',
    'processing_cancel': 'Cancel Analysis',

    // Source Card
    'source_tips': 'Tips for Best Results',
    'source_select': 'Select This Option',
    'source_loading': 'Loading...',
    'tap_to_begin': 'Tap to Begin',
    'start_ai_analysis': 'Start AI Analysis',
    'quick_easy': 'Quick & Easy',


    // Advance Scan
    'advanced_analysis': 'Advanced Analysis',
    'step_choose': 'Choose Analysis Method',
    'step_choose_subtitle': 'Select how to analyze your plant',
    'your_scan': 'Your Scan',
    'plant_image_ready': 'Plant Image Ready',
    'image_not_available': 'Image Not Available',
    'analysis_methods': 'Analysis Methods',
    'gemini_ai': 'Gemini AI',
    'gemini_desc': 'Fast AI-powered disease detection',
    'gemini_best': 'Best for field conditions',
    'plantid_ai': 'Plant.id',
    'plantid_desc': 'Professional plant identification',
    'plantid_best': 'Best for detailed analysis',
    'duration': 'Duration',
    'seconds': 'seconds',
    'start_analysis': 'Start Analysis',
    'Analyzing': 'Analyzing',
    'selected': 'Selected',
    'advanced_detection': 'Advanced detection',
    'detailed_reports': 'Detailed reports',
    'high_accuracy': 'High accuracy',
    'plant_id': 'Plant identification',
    'disease_diagnosis': 'Disease diagnosis',
    'treatment_plans': 'Treatment plans',
    'cloud_ai': 'Cloud AI',
    'cloud_ai_desc': 'Fast AI-powered disease detection',
    'plantid': 'Plant.id',
    'plantiddesc': 'Professional plant identification',
    'Seconds': 'seconds',
  };

  // Urdu translations
  static const Map<String, String> _urduTranslations = {
    // App Bar
    'app_title': 'ایگری گارڈ',
    'analysis_method': 'تجزیہ کا طریقہ',
    'image_source': 'تصویر کا ذریعہ',
    'analyzing': 'تجزیہ جاری ہے...',

    // Welcome Screen
    'welcome_title': 'پودوں کی بیماریوں کی تشخیص',
    'welcome_subtitle': 'AI سے چلنے والا زرعی معاون',
    'welcome_description': 'جدید AI ٹیکنالوجی کا استعمال کرتے ہوئے فوری طور پر پودوں کی بیماریوں کی شناخت کریں',
    'start_scanning': 'اسکیننگ شروع کریں',
    'models_loading': 'AI ماڈل لوڈ ہو رہے ہیں...',
    'models_ready': 'AI ماڈل تیار ہیں',
    'plant_id_model': 'پودے کی شناخت ماڈل',
    'disease_model': 'بیماری کا ماڈل',
    'guest_mode': 'مہمان موڈ',
    'remaining_scans': 'باقی اسکینز',

    // Method Selection
    'method_title': 'تجزیہ کا طریقہ منتخب کریں',
    'method_subtitle': 'منتخب کریں کہ آپ اپنے پودے کا تجزیہ کیسے کرنا چاہتے ہیں',
    'on_device': 'آن ڈیوائس AI',
    'on_device_desc': 'تیز • آف لائن • مفت',
    'on_device_features': '• انٹرنیٹ کے بغیر کام کرتا ہے\n• فوری نتائج\n• 100% نجی\n• لامحدود مفت اسکینز',
    'advanced_ai': 'ایڈوانسڈ AI',
    'advanced_ai_desc': 'درست • تفصیلی • ماہر',
    'advanced_ai_features': '• کلاؤڈ پر مبنی تجزیہ\n• ماہرین کی سفارشات\n• تفصیلی علاج کے منصوبے\n• موسم کی معلومات',
    'model_loading': 'AI ماڈل لوڈ ہو رہے ہیں...',
    'model_plant': 'پودے کی شناخت',
    'model_disease': 'بیماری کی تشخیص',

    // Source Selection
    'source_title': 'تصویر کا ذریعہ منتخب کریں',
    'source_subtitle': 'آپ پودے کی تصویر کیسے لینا چاہیں گے؟',
    'camera': 'کیمرہ',
    'camera_desc': 'ابھی تصویر لیں',
    'camera_tip': 'فوری تجزیہ کے لیے بہترین',
    'gallery': 'گیلری',
    'gallery_desc': 'موجودہ تصویر منتخب کریں',
    'gallery_tip': 'اپنی تصاویر سے منتخب کریں',
    'capture_tips': 'تصویر لینے کی تجاویز',
    'tip_1': 'اچھی روشنی استعمال کریں',
    'tip_2': 'متاثرہ علاقوں پر توجہ دیں',
    'tip_3': 'پورے پتے کو شامل کریں',
    'tip_4': 'سائے سے بچیں',

    // Processing
    'processing_title': 'آپ کے پودے کا تجزیہ',
    'processing_ai': 'دوہری AI تجزیہ چل رہا ہے...',
    'processing_plant': '• پودے کی شناخت',
    'processing_disease': '• بیماری کی تشخیص',
    'processing_wait': 'اس میں کچھ لمحے لگ سکتے ہیں...',
    'cancel': 'منسوخ کریں',
    'dismiss': 'بند کریں',

    // Errors
    'error_pick_image': 'تصویر منتخب کرنے میں ناکامی۔ براہ کرم دوبارہ کوشش کریں۔',
    'error_load_models': 'AI ماڈل لوڈ کرنے میں ناکامی۔ براہ کرم ایپ دوبارہ شروع کریں۔',
    'error_sign_in': 'جاری رکھنے کے لیے براہ کرم سائن ان کریں',
    'error_file_not_found': 'تصویر کی فائل نہیں ملی',

    // Guest Limit
    'limit_reached': 'اسکین کی حد پوری ہو گئی',
    'limit_message': 'آپ اپنی مفت اسکین کی حد تک پہنچ گئے ہیں',
    'limit_benefit': 'لامحدود اسکینز اور جدید خصوصیات کے لیے سائن اپ کریں!',
    'sign_in_now': 'ابھی سائن ان کریں',

    // Info Dialog
    'info_title': 'یہ کیسے کام کرتا ہے',
    'info_step1': 'تجزیہ کا طریقہ منتخب کریں',
    'info_step1_desc': 'تیز آن ڈیوائس AI یا جدید کلاؤڈ تجزیہ میں سے انتخاب کریں',
    'info_step2': 'تصویر لیں',
    'info_step2_desc': 'متاثرہ پودے یا پتے کی واضح تصویر لیں',
    'info_step3': 'نتائج حاصل کریں',
    'info_step3_desc': 'فوری تشخیص اور علاج کی سفارشات حاصل کریں',
    'info_tips': 'بہترین نتائج کے لیے تجاویز',
    'info_tip1': '📸 قدرتی روشنی استعمال کریں',
    'info_tip2': '🎯 بیمار علاقوں پر توجہ دیں',
    'info_tip3': '📏 ممکن ہو تو پورا پتہ شامل کریں',
    'info_tip4': '🔍 دھندلی تصاویر سے بچیں',
    'got_it': 'سمجھ گیا',

    // How It Works
    'how_it_works': 'یہ کیسے کام کرتا ہے',
    'take_photo': 'تصویر لیں',
    'choose_method': 'طریقہ منتخب کریں',
    'ai_analysis': 'AI تجزیہ',
    'get_results': 'نتائج حاصل کریں',
    'step1_text': 'پودے کے پتے کی واضح تصویر لیں یا اپ لوڈ کریں',
    'step2_text': 'تیز آن ڈیوائس یا تفصیلی کلاؤڈ تجزیہ میں سے انتخاب کریں',
    'step3_text': 'ہماری AI شناخت کے لیے تصویر کا تجزیہ کرتی ہے',
    'step4_text': 'فوری تشخیص اور علاج کی مشورہ حاصل کریں',

    // Guest Stats
    'guest_stats_title': 'مہمان موڈ',
    'guest_stats_scans': 'اسکینز باقی',
    'guest_stats_signup': 'لامحدود اسکینز اور اپنی سرگزشت محفوظ کرنے کے لیے سائن اپ کریں',

    // Feature Highlights
    'features_title': 'اہم خصوصیات',
    'feature_identify': 'پودوں کی شناخت',
    'feature_identify_desc': '50,000+ اقسام',
    'feature_disease': 'بیماری کی تشخیص',
    'feature_disease_desc': 'عام بیماریاں',
    'feature_treatment': 'علاج کے منصوبے',
    'feature_treatment_desc': 'ماہرین کی مشورہ',
    'feature_offline': 'آف لائن موڈ',
    'feature_offline_desc': 'انٹرنیٹ کی ضرورت نہیں',

    // Comparison Table
    'comparison_title': 'طریقوں کا موازنہ',
    'comparison_subtitle': 'منتخب کریں جو آپ کے لیے بہتر ہے',
    'comparison_ondevice': 'آن ڈیوائس',
    'comparison_cloudai': 'کلاؤڈ AI',
    'comparison_internet': 'انٹرنیٹ',
    'comparison_not_required': 'ضروری نہیں',
    'comparison_required': 'ضروری',
    'comparison_speed': 'رفتار',
    'comparison_instant': 'فوری',
    'comparison_database': 'ڈیٹا بیس',
    'comparison_species': 'اقسام',
    'comparison_privacy': 'رازداری',
    'comparison_private': '100% نجی',
    'comparison_cloud_based': 'کلاؤڈ پر مبنی',
    'comparison_bestfor': 'بہترین',
    'comparison_quick': 'فوری جانچ',
    'comparison_deep': 'گہرا تجزیہ',

    // Processing Overlay
    'processing_analyzing': 'آپ کے پودے کا تجزیہ',
    'processing_ondevice_subtitle': 'فوری نتائج کے لیے آن ڈیوائس AI استعمال کر رہے ہیں',
    'processing_cloud_subtitle': 'تفصیلی تجزیہ کے لیے کلاؤڈ AI سے جڑ رہے ہیں',
    'processing_image_captured': 'تصویر محفوظ',
    'processing_analyzing_stage': 'تجزیہ جاری',
    'processing_generating': 'رپورٹ تیار کر رہے ہیں',
    'processing_text': 'پروسیسنگ جاری ہے...',
    'processing_guest_scans': 'مہمان موڈ میں اسکینز باقی',
    'processing_cancel': 'تجزیہ منسوخ کریں',

    // Source Card
    'source_tips': 'بہترین نتائج کے لیے تجاویز',
    'source_select': 'یہ آپشن منتخب کریں',
    'source_loading': 'لوڈ ہو رہا ہے...',
    'tap_to_begin': 'شروع کرنے کے لیے ٹیپ کریں',
    'start_ai_analysis': 'AI تشخیص شروع کریں',
    'quick_easy': 'فوری اور آسان',

//Advance Scan
    'advanced_analysis': 'جدید تجزیہ',
    'step_choose': 'تجزیہ کا طریقہ منتخب کریں',
    'step_choose_subtitle': 'اپنے پودے کا تجزیہ کرنے کا طریقہ منتخب کریں',
    'your_scan': 'آپ کا اسکین',
    'plant_image_ready': 'پودے کی تصویر تجزیہ کے لیے تیار',
    'image_not_available': 'تصویر دستیاب نہیں',
    'analysis_methods': 'تجزیہ کے طریقے',
    'gemini_ai': 'Gemini AI',
    'gemini_desc': 'تیز AI سے بیماری کی تشخیص',
    'gemini_best': 'میدانی حالات کے لیے بہترین',
    'plantid_ai': 'Plant.id',
    'plantid_desc': 'پیشہ ورانہ پودوں کی شناخت',
    'plantid_best': 'تفصیلی تجزیہ کے لیے بہترین',
    'duration': 'دورانیہ',
    'seconds': 'سیکنڈ',
    'start_analysis': 'تجزیہ شروع کریں',
    'Analyzing': 'تجزیہ جاری ہے',
    'selected': 'منتخب',
    'advanced_detection': 'جدید تشخیص',
    'detailed_reports': 'تفصیلی رپورٹیں',
    'high_accuracy': 'اعلیٰ درستگی',
    'plant_id': 'پودوں کی شناخت',
    'disease_diagnosis': 'بیماری کی تشخیص',
    'treatment_plans': 'علاج کے منصوبے',
    'cloud_ai': 'Cloud AI',
    'cloud_ai_desc': 'تیز AI سے بیماری کی تشخیص',
    'plantid': 'Plant.id',
    'plantiddesc': 'پیشہ ورانہ پودوں کی شناخت',
    'Seconds': 'سیکنڈ',
  };
}