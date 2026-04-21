// lib/core/services/translation_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService extends ChangeNotifier {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  bool _isUrdu = false;
  bool get isUrdu => _isUrdu;
  String get currentLanguage => _isUrdu ? 'ur' : 'en';

  static const String _languageKey = 'app_language';

  Map<String, dynamic> _enAsset = const {};
  Map<String, dynamic> _urAsset = const {};
  bool _assetsLoaded = false;

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _isUrdu = prefs.getBool(_languageKey) ?? false;
    await _loadAssetTranslationsOnce();
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _isUrdu = !_isUrdu;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_languageKey, _isUrdu);
    notifyListeners();
  }

  String get(String key) {
    // 1) Try asset-based translations (supports dotted keys like "results.title")
    final assetValue = _getFromAsset(key);
    if (assetValue != null) return assetValue;

    // 2) Fall back to legacy in-code maps (flat keys)
    return _isUrdu ? _urduTranslations[key] ?? key : _englishTranslations[key] ?? key;
  }

  Future<void> _loadAssetTranslationsOnce() async {
    if (_assetsLoaded) return;
    try {
      final enStr = await rootBundle.loadString('assets/translations/en.json');
      final urStr = await rootBundle.loadString('assets/translations/ur.json');
      final en = jsonDecode(enStr);
      final ur = jsonDecode(urStr);
      if (en is Map<String, dynamic>) _enAsset = en;
      if (ur is Map<String, dynamic>) _urAsset = ur;
      _assetsLoaded = true;
    } catch (_) {
      // Safe fallback: app will still work using legacy maps.
      _assetsLoaded = true;
    }
  }

  String? _getFromAsset(String key) {
    if (!_assetsLoaded) return null;
    final root = _isUrdu ? _urAsset : _enAsset;
    if (root.isEmpty) return null;

    dynamic cur = root;
    for (final part in key.split('.')) {
      if (cur is Map<String, dynamic> && cur.containsKey(part)) {
        cur = cur[part];
      } else {
        return null;
      }
    }
    return cur is String ? cur : null;
  }

  // Translate plant names
  String translatePlant(String plantName) {
    if (!_isUrdu) return plantName;
    final normalized = plantName.toLowerCase().trim();
    return _plantTranslations[normalized]?['ur'] ?? plantName;
  }

  // Translate disease names — handles full names and partial matches
  String translateDisease(String diseaseName) {
    if (!_isUrdu) return diseaseName;
    if (diseaseName.isEmpty) return diseaseName;
    
    final normalized = diseaseName.toLowerCase().trim();
    
    // 1. Exact match
    if (_diseaseTranslations.containsKey(normalized)) {
      return _diseaseTranslations[normalized]!['ur']!;
    }
    
    // 2. Try removing "tomato " prefix (model sometimes returns "Tomato Mosaic Virus")
    final withoutPlant = normalized.replaceFirst(RegExp(r'^(tomato|apple|corn|grape|potato|strawberry|peach|pepper|cherry|orange|squash|soybean|raspberry|blueberry)\s+'), '');
    if (_diseaseTranslations.containsKey(withoutPlant)) {
      return _diseaseTranslations[withoutPlant]!['ur']!;
    }
    
    // 3. Partial match — find key that is contained in the disease name
    for (final entry in _diseaseTranslations.entries) {
      if (normalized.contains(entry.key) && entry.key != 'healthy') {
        return entry.value['ur']!;
      }
    }
    
    // 4. Return original (English) — better than showing nothing
    return diseaseName;
  }

  // Translate severity
  String translateSeverity(String severity) {
    if (!_isUrdu) return severity;
    final normalized = severity.toLowerCase().trim();
    return _severityTranslations[normalized] ?? severity;
  }

  // Translate a treatment/symptom/precaution string
  // Uses the treatments map in ur.json for common strings
  String translateTreatmentItem(String item) {
    if (!_isUrdu) return item;
    if (item.isEmpty) return item;
    // Try exact match from asset translations map
    final assetVal = _getFromAsset('treatments.$item');
    if (assetVal != null) return assetVal;
    // Try partial key match — find a key that the item starts with
    final urMap = _urAsset['treatments'];
    if (urMap is Map<String, dynamic>) {
      for (final entry in urMap.entries) {
        if (item.toLowerCase().contains(entry.key.toLowerCase()) ||
            entry.key.toLowerCase().contains(item.toLowerCase())) {
          return entry.value.toString();
        }
      }
    }
    return item; // return original if no translation found
  }

  // Translate a list of treatment/symptom items
  List<String> translateList(List<String> items) {
    if (!_isUrdu) return items;
    return items.map(translateTreatmentItem).toList();
  }

  // ==================== ENGLISH TRANSLATIONS ====================
  static const Map<String, String> _englishTranslations = {
    // App Basic
    'app_title': 'AGRIGUARD',
    'analysis_method': 'Analysis Method',
    'image_source': 'Image Source',
    'analyzing': 'Analyzing...',

    // Plant Species (NEW)
    'detectable_species': 'Detectable Species',
    'tap_to_explore': 'Tap to explore',
    'plant_species_label': 'Plant Species',
    'about_plant': 'About This Plant',
    'growth_requirements': 'Growth Requirements',
    'start_disease_detection': 'Start Disease Detection',
    'common_diseases': 'Common Diseases',

    // Analysis Method Screen (NEW)
    'select_method': 'Select Method',
    'comparison_title': 'Analysis Comparison',
    'comparison_subtitle': 'Choose your preferred method',
    'comparison_ondevice': 'On-Device',
    'comparison_cloudai': 'Cloud AI',
    'comparison_not_required': 'Internet Not Required',
    'comparison_required': 'Internet Required',
    'comparison_instant': 'Instant Results',
    'comparison_species': 'Limited Species',
    'comparison_private': '100% Private',
    'comparison_cloud_based': 'Cloud-Based',
    'comparison_quick': 'Quick Analysis',
    'comparison_deep': 'Deep Analysis',

    // Info Screen (NEW)
    'take_photo': 'Take a Photo',
    'step1_text': 'Capture a clear image of the affected plant',
    'choose_method': 'Choose Method',
    'step2_text': 'Select on-device or advanced AI analysis',
    'ai_analysis': 'AI Analysis',
    'step3_text': 'Our AI analyzes the plant condition',
    'get_results': 'Get Results',
    'step4_text': 'Receive diagnosis and treatment recommendations',

    // Results Screen
    'analysis_results': 'Analysis Results',
    'diagnosis': 'Diagnosis',
    'diagnosis_summary': 'Diagnosis Summary',
    'analysis_details': 'Analysis Details',
    'comprehensive_diagnosis': 'Comprehensive diagnosis breakdown',
    'disease_causes': 'Disease Causes',
    'possible_causes': 'Possible Causes',
    'understanding_causes': 'Understanding the root causes',
    'recommendations': 'Recommendations',
    'treatment_steps': 'Treatment Steps',
    'follow_steps': 'Follow these steps in order',
    'next_steps': 'Next Steps',
    'recommended_actions': 'Recommended actions to take',
    'preventive_measures': 'Preventive Measures',

    // Status
    'healthy': 'Healthy',
    'healthy_plant': 'Healthy Plant',
    'diseased': 'Diseased',
    'disease_detected': 'Disease Detected',
    'unknown': 'Unknown',

    // Severity
    'severity': 'Severity',
    'severity_level': 'Severity Level',
    'low': 'Low',
    'medium': 'Medium',
    'high': 'High',
    'critical': 'Critical',
    'none': 'None',
    'n/a': 'N/A',

    // Details
    'plant_species': 'Plant Species',
    'plant_name': 'Plant name',
    'disease_name': 'Disease Name',
    'confidence_level': 'Confidence Level',
    'ai_confidence': 'AI Confidence',
    'scientific_name': 'Scientific Name',
    'common_name': 'Common Name',
    'description': 'Description',
    'health_status': 'Health Status',
    'detected_disease': 'Detected Disease',
    'likely_cause': 'Likely Cause',

    // Actions
    'generate_pdf': 'Generate PDF',
    'generating': 'Generating...',
    'save_pdf': 'Save PDF',
    'share_pdf': 'Share PDF',
    'advanced_search': 'Advanced Search',
    'want_deeper_analysis': 'Want deeper analysis?',
    'try_advanced_ai': 'Try Advanced AI Search with AI & Plant.id',
    'consult_expert': 'Consult an Expert',
    'monitor_plant': 'Monitor Your Plant',
    'apply_treatment': 'Apply Treatment',
    'copy_all_details': 'Copy All Details',
    'collapse': 'Collapse',
    'expand': 'Expand',
    'copied_to_clipboard': 'copied to clipboard',
    'details_copied': 'Analysis details copied to clipboard',

    // Messages
    'no_image_available': 'No image available',
    'analysis_failed': 'Analysis could not be completed',
    'please_try_again': 'Please try again',
    'loading': 'Loading...',
    'no_diseases_detected': 'No diseases detected. Plant appears to be in excellent health!',
    'plant_analysis_details': 'Plant Analysis Details',

    // Next Steps Actions
    'monitor_progress': 'Monitor Progress',
    'monitor_progress_desc': 'Check back in 3-5 days to track healing progress',
    'get_treatment': 'Get Treatment Products',
    'get_treatment_desc': 'Find recommended products at your local store',
    'consult_expert_desc': 'Contact a specialist if symptoms worsen',

    // Disease Causes
    'no_disease_analysis': 'No Disease Analysis Available',
    'analysis_not_available': 'Analysis data is not available for this scan',

    // Recommendations
    'treatment_plan': 'Treatment Plan',
    'no_recommendations': 'No Recommendations Available',
    'consult_expert_guidance': 'Consult an expert for personalized guidance',
    'completed': 'COMPLETED',
    'step': 'STEP',
    'cause': 'CAUSE',

    // Image Detection
    'image_not_recognized': 'Image Not Recognized',
    'non_plant_image': 'Non-Plant Image',
    'analyzing_image': 'Analyzing image...',
    'checking_leaf': 'Checking if image is a plant leaf',
    'getting_severity': 'Getting severity and recommendations...',
    'analyzing_severity': 'Analyzing disease severity and treatment options',

    // Welcome & Onboarding
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
    'error_selected_method_unavailable': 'Selected method is unavailable',
    'error_option_unavailable': 'This option is not available',
    'error_image_too_large_5mb': 'Image is too large (max 5MB)',
    'error_unexpected': 'Unexpected error',
    'limit_reached': 'Scan Limit Reached',
    'limit_message': 'You have reached your free scan limit',
    'limit_benefit': 'Sign up for unlimited scans and advanced features!',
    'sign_in_now': 'Sign In Now',

    // Info & Help
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
    'how_it_works': 'How It Works',

    // Advanced analysis UI
    'step_choose': 'Choose a method',
    'step_choose_subtitle': 'Pick the one that best matches your need',
    'unavailable': 'Unavailable',
    'advanced_note': 'Better results with clear, well-lit leaf photos',

    // Features
    'features_title': 'Key Features',
    'feature_identify': 'Identify Plants',
    'feature_identify_desc': '50,000+ species',
    'feature_disease': 'Disease Detection',
    'feature_disease_desc': 'Common diseases',
    'feature_treatment': 'Treatment Plans',
    'feature_treatment_desc': 'Expert advice',
    'feature_offline': 'Offline Mode',
    'feature_offline_desc': 'No internet needed',

    // Analysis Methods
    'analysis_methods': 'Analysis Methods',
    'groq_ai': 'Groq AI',
    'groq_desc': 'AI assistant built on on-device detection',
    'groq_best': 'Best for explanations and treatment guidance',
    'plantid_ai': 'Plant.id',
    'plantid_desc': 'Professional plant identification',
    'plantid_best': 'Best for detailed analysis',
    'cloud_ai': 'Cloud Vision (Free)',
    'cloud_ai_desc': 'Free image-based disease detection (Hugging Face)',
    'plantid': 'Plant.id',
    'duration': 'Duration',
    'seconds': 'seconds',
    'start_analysis': 'Start Analysis',
    'selected': 'Selected',
    'advanced_detection': 'Advanced detection',
    'detailed_reports': 'Detailed reports',
    'high_accuracy': 'High accuracy',
    'plant_id': 'Plant identification',
    'disease_diagnosis': 'Disease diagnosis',
    'treatment_plans': 'Treatment plans',

    // Help & Support
    'help_support': 'Help & Support',
    'get_in_touch': 'Get in Touch',
    'help_questions': 'We\'re here to help you with any questions',
    'email': 'Email',
    'phone': 'Phone',
    'instagram': 'Instagram',
    'send_message': 'Send us a Message',
    'get_back_soon': 'We\'ll get back to you soon',
    'your_name': 'Your Name',
    'enter_full_name': 'Enter your full name',
    'email_address': 'Email Address',
    'email_placeholder': 'your.email@example.com',
    'your_message': 'Your Message',
    'type_message': 'Type your message here...',
    'send_message_btn': 'Send Message',
    'name_required': 'Name is required',
    'email_required': 'Email is required',
    'valid_email': 'Enter a valid email address',
    'message_required': 'Message is required',
    'message_too_short': 'Message is too short (min 10 characters)',
    'message_sent': 'Message sent successfully!',
    'quick_answers': 'Quick Answers',
    'find_answers': 'Find answers to common questions',
    'view_all_faqs': 'View All FAQs',
    'all_faqs': 'All FAQs',
    'search_faqs': 'Search FAQs...',
    'no_results': 'No results found',
    'try_different': 'Try searching with different keywords',

    // FAQ
    'faq_scan_q': 'How do I scan a plant?',
    'faq_scan_a': 'Open the app, tap the scan button, and point your camera at the plant. Ensure good lighting for accurate results.',
    'faq_plants_q': 'What plants can the app identify?',
    'faq_plants_a': 'The app supports a wide range of plants, including common houseplants, garden plants, and crops. Check the plant database for specifics.',
    'faq_accuracy_q': 'How accurate are the results?',
    'faq_accuracy_a': 'Our AI model provides high accuracy, but results depend on image quality and plant condition. Always consult a professional for critical cases.',
    'faq_history_q': 'Can I save my scan history?',
    'faq_history_a': 'Yes, all scans are saved in your profile. You can view, delete, or share them from the history section.',
    'faq_what_is_agriguard_q': 'What is AgriGuard?',
    'faq_what_is_agriguard_a': 'AgriGuard is an AI-powered plant identification and disease detection app that uses TensorFlow machine learning to identify 12 plant species and detect 18 common plant diseases from photos, even without internet connection.',
    'faq_offline_q': 'Can I use the app without internet?',
    'faq_offline_a': 'Yes! PlantDetect works completely offline thanks to our optimized TensorFlow Lite model. All plant identification and disease detection happens on your device without needing internet connection.',
    'faq_best_photo_q': 'How do I take the best photo for scanning?',
    'faq_best_photo_a': 'For optimal results: 1) Use natural lighting, 2) Focus on leaves or affected areas, 3) Keep camera steady, 4) Fill frame with plant, 5) Take multiple angles if needed. Avoid shadows and blurry images.',
  };

  // ==================== URDU TRANSLATIONS ====================
  static const Map<String, String> _urduTranslations = {
    // App Basic
    'app_title': 'ایگری گارڈ',
    'analysis_method': 'تجزیہ کا طریقہ',
    'image_source': 'تصویر کا ذریعہ',
    'analyzing': 'تجزیہ جاری ہے...',

    // Plant Species (NEW)
    'detectable_species': 'قابل شناخت اقسام',
    'tap_to_explore': 'دریافت کرنے کے لیے ٹیپ کریں',
    'plant_species_label': 'پودے کی قسم',
    'about_plant': 'اس پودے کے بارے میں',
    'growth_requirements': 'نمو کی ضروریات',
    'start_disease_detection': 'بیماری کی تشخیص شروع کریں',
    'common_diseases': 'عام بیماریاں',

    // Analysis Method Screen (NEW)
    'select_method': 'طریقہ منتخب کریں',
    'comparison_title': 'تجزیہ کا موازنہ',
    'comparison_subtitle': 'اپنا پسندیدہ طریقہ منتخب کریں',
    'comparison_ondevice': 'آن ڈیوائس',
    'comparison_cloudai': 'کلاؤڈ AI',
    'comparison_not_required': 'انٹرنیٹ کی ضرورت نہیں',
    'comparison_required': 'انٹرنیٹ درکار ہے',
    'comparison_instant': 'فوری نتائج',
    'comparison_species': 'محدود پرجاتیاں',
    'comparison_private': '100% نجی',
    'comparison_cloud_based': 'کلاؤڈ پر مبنی',
    'comparison_quick': 'فوری تجزیہ',
    'comparison_deep': 'گہرا تجزیہ',

    // Info Screen (NEW)
    'take_photo': 'تصویر لیں',
    'step1_text': 'متاثرہ پودے کی واضح تصویر لیں',
    'choose_method': 'طریقہ منتخب کریں',
    'step2_text': 'آن ڈیوائس یا ایڈوانسڈ AI تجزیہ منتخب کریں',
    'ai_analysis': 'AI تجزیہ',
    'step3_text': 'ہماری AI پودے کی حالت کا تجزیہ کرتی ہے',
    'get_results': 'نتائج حاصل کریں',
    'step4_text': 'تشخیص اور علاج کی سفارشات حاصل کریں',

    // Results Screen
    'analysis_results': 'تجزیہ کے نتائج',
    'diagnosis': 'تشخیص',
    'diagnosis_summary': 'تشخیص کا خلاصہ',
    'analysis_details': 'تجزیہ کی تفصیلات',
    'comprehensive_diagnosis': 'تشخیص کی مکمل تفصیل',
    'disease_causes': 'بیماری کی وجوہات',
    'possible_causes': 'ممکنہ وجوہات',
    'understanding_causes': 'بیماری کی بنیادی وجوہات',
    'recommendations': 'سفارشات',
    'treatment_steps': 'علاج کے مراحل',
    'follow_steps': 'ترتیب سے ان مراحل پر عمل کریں',
    'next_steps': 'اگلے اقدامات',
    'recommended_actions': 'تجویز کردہ اقدامات',
    'preventive_measures': 'احتیاطی تدابیر',

    // Status
    'healthy': 'صحت مند',
    'healthy_plant': 'صحت مند پودا',
    'diseased': 'بیمار',
    'disease_detected': 'بیماری کی تشخیص',
    'unknown': 'نامعلوم',

    // Severity
    'severity': 'شدت',
    'severity_level': 'شدت کی سطح',
    'low': 'کم',
    'medium': 'درمیانہ',
    'high': 'زیادہ',
    'critical': 'انتہائی خطرناک',
    'none': 'کوئی نہیں',
    'n/a': 'لاگو نہیں',

    // Details
    'plant_species': 'پودے کی قسم',
    'plant_name': 'پودے کا نام',
    'disease_name': 'بیماری کا نام',
    'confidence_level': 'اعتماد کی سطح',
    'ai_confidence': 'AI کا اعتماد',
    'scientific_name': 'سائنسی نام',
    'common_name': 'عام نام',
    'description': 'تفصیل',
    'health_status': 'صحت کی حالت',
    'detected_disease': 'بیماری کی تشخیص',
    'likely_cause': 'ممکنہ وجہ',

    // Actions
    'generate_pdf': 'پی ڈی ایف بنائیں',
    'generating': 'بنایا جا رہا ہے...',
    'save_pdf': 'پی ڈی ایف محفوظ کریں',
    'share_pdf': 'پی ڈی ایف شیئر کریں',
    'advanced_search': 'اعلیٰ تلاش',
    'want_deeper_analysis': 'مزید تفصیلی تجزیہ چاہتے ہیں؟',
    'try_advanced_ai': 'AI اور Plant.id کے ساتھ جدید تلاش آزمائیں',
    'consult_expert': 'ماہر سے مشورہ کریں',
    'monitor_plant': 'اپنے پودے کی نگرانی کریں',
    'apply_treatment': 'علاج کریں',
    'copy_all_details': 'تمام تفصیلات کاپی کریں',
    'collapse': 'بند کریں',
    'expand': 'کھولیں',
    'copied_to_clipboard': 'کاپی ہو گیا',
    'details_copied': 'تجزیہ کی تفصیلات کاپی ہو گئیں',

    // Messages
    'no_image_available': 'کوئی تصویر دستیاب نہیں',
    'analysis_failed': 'تجزیہ مکمل نہیں ہو سکا',
    'please_try_again': 'براہ کرم دوبارہ کوشش کریں',
    'loading': 'لوڈ ہو رہا ہے...',
    'no_diseases_detected': 'کوئی بیماری نہیں ملی۔ پودا بہترین صحت میں ہے!',
    'plant_analysis_details': 'پودے کے تجزیہ کی تفصیلات',

    // Next Steps Actions
    'monitor_progress': 'پیشرفت کی نگرانی کریں',
    'monitor_progress_desc': 'علاج کی پیشرفت دیکھنے کے لیے 3-5 دنوں بعد چیک کریں',
    'get_treatment': 'علاج کی مصنوعات حاصل کریں',
    'get_treatment_desc': 'اپنے مقامی اسٹور سے تجویز کردہ مصنوعات تلاش کریں',
    'consult_expert_desc': 'اگر علامات بڑھیں تو ماہر سے رابطہ کریں',

    // Disease Causes
    'no_disease_analysis': 'بیماری کا تجزیہ دستیاب نہیں',
    'analysis_not_available': 'اس اسکین کے لیے تجزیہ کا ڈیٹا دستیاب نہیں ہے',

    // Recommendations
    'treatment_plan': 'علاج کا منصوبہ',
    'no_recommendations': 'کوئی سفارشات دستیاب نہیں',
    'consult_expert_guidance': 'ذاتی رہنمائی کے لیے ماہر سے مشورہ کریں',
    'completed': 'مکمل',
    'step': 'مرحلہ',
    'cause': 'وجہ',

    // Image Detection
    'image_not_recognized': 'تصویر کی شناخت نہیں ہوئی',
    'non_plant_image': 'غیر پودے کی تصویر',
    'analyzing_image': 'تصویر کا تجزیہ ہو رہا ہے...',
    'checking_leaf': 'چیک ہو رہا ہے کہ تصویر پودے کا پتہ ہے',
    'getting_severity': 'شدت اور سفارشات حاصل کی جا رہی ہیں...',
    'analyzing_severity': 'بیماری کی شدت اور علاج کے اختیارات کا تجزیہ',

    // Welcome & Onboarding
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
    'error_selected_method_unavailable': 'منتخب کردہ طریقہ دستیاب نہیں ہے',
    'error_option_unavailable': 'یہ آپشن دستیاب نہیں ہے',
    'error_image_too_large_5mb': 'تصویر بہت بڑی ہے (زیادہ سے زیادہ 5MB)',
    'error_unexpected': 'غیر متوقع خرابی',
    'limit_reached': 'اسکین کی حد پوری ہو گئی',
    'limit_message': 'آپ اپنی مفت اسکین کی حد تک پہنچ گئے ہیں',
    'limit_benefit': 'لامحدود اسکینز اور جدید خصوصیات کے لیے سائن اپ کریں!',
    'sign_in_now': 'ابھی سائن ان کریں',

    // Info & Help
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
    'how_it_works': 'یہ کیسے کام کرتا ہے',

    // Advanced analysis UI
    'step_choose': 'طریقہ منتخب کریں',
    'step_choose_subtitle': 'اپنی ضرورت کے مطابق بہترین آپشن منتخب کریں',
    'unavailable': 'دستیاب نہیں',
    'advanced_note': 'بہترین نتائج کے لیے صاف اور روشن پتے کی تصویر استعمال کریں',

    // Features
    'features_title': 'اہم خصوصیات',
    'feature_identify': 'پودوں کی شناخت',
    'feature_identify_desc': '50,000+ اقسام',
    'feature_disease': 'بیماری کی تشخیص',
    'feature_disease_desc': 'عام بیماریاں',
    'feature_treatment': 'علاج کے منصوبے',
    'feature_treatment_desc': 'ماہرین کی مشورہ',
    'feature_offline': 'آف لائن موڈ',
    'feature_offline_desc': 'انٹرنیٹ کی ضرورت نہیں',

    // Analysis Methods
    'analysis_methods': 'تجزیہ کے طریقے',
    'groq_ai': 'گروک AI',
    'groq_desc': 'آن ڈیوائس ڈیٹیکشن کے ساتھ AI اسسٹنٹ',
    'groq_best': 'وضاحت اور علاج کی رہنمائی کے لیے بہترین',
    'plantid_ai': 'Plant.id',
    'plantid_desc': 'پیشہ ورانہ پودوں کی شناخت',
    'plantid_best': 'تفصیلی تجزیہ کے لیے بہترین',
    'cloud_ai': 'کلاؤڈ ویژن (فری)',
    'cloud_ai_desc': 'فری امیج بیسڈ بیماری کی تشخیص (Hugging Face)',
    'plantid': 'Plant.id',
    'duration': 'دورانیہ',
    'seconds': 'سیکنڈ',
    'start_analysis': 'تجزیہ شروع کریں',
    'selected': 'منتخب',
    'advanced_detection': 'جدید تشخیص',
    'detailed_reports': 'تفصیلی رپورٹیں',
    'high_accuracy': 'اعلیٰ درستگی',
    'plant_id': 'پودوں کی شناخت',
    'disease_diagnosis': 'بیماری کی تشخیص',
    'treatment_plans': 'علاج کے منصوبے',

    // Help & Support
    'help_support': 'مدد اور سپورٹ',
    'get_in_touch': 'رابطے میں رہیں',
    'help_questions': 'ہم آپ کی کسی بھی سوال میں مدد کے لیے حاضر ہیں',
    'email': 'ای میل',
    'phone': 'فون',
    'instagram': 'انسٹاگرام',
    'send_message': 'ہمیں پیغام بھیجیں',
    'get_back_soon': 'ہم جلد آپ سے رابطہ کریں گے',
    'your_name': 'آپ کا نام',
    'enter_full_name': 'اپنا پورا نام درج کریں',
    'email_address': 'ای میل ایڈریس',
    'email_placeholder': 'آپ کا.ای میل@مثال.com',
    'your_message': 'آپ کا پیغام',
    'type_message': 'اپنا پیغام یہاں لکھیں...',
    'send_message_btn': 'پیغام بھیجیں',
    'name_required': 'نام ضروری ہے',
    'email_required': 'ای میل ضروری ہے',
    'valid_email': 'درست ای میل ایڈریس درج کریں',
    'message_required': 'پیغام ضروری ہے',
    'message_too_short': 'پیغام بہت مختصر ہے (کم از کم 10 حروف)',
    'message_sent': 'پیغام کامیابی سے بھیج دیا گیا!',
    'quick_answers': 'فوری جوابات',
    'find_answers': 'عام سوالات کے جوابات تلاش کریں',
    'view_all_faqs': 'تمام سوالات دیکھیں',
    'all_faqs': 'تمام سوالات',
    'search_faqs': 'سوالات تلاش کریں...',
    'no_results': 'کوئی نتیجہ نہیں ملا',
    'try_different': 'مختلف مطلوبہ الفاظ سے تلاش کریں',

    // FAQ
    'faq_scan_q': 'میں پودے کو کیسے اسکین کروں؟',
    'faq_scan_a': 'ایپ کھولیں، اسکین بٹن دبائیں، اور اپنا کیمرہ پودے کی طرف کریں۔ درست نتائج کے لیے اچھی روشنی کو یقینی بنائیں۔',
    'faq_plants_q': 'ایپ کون سے پودوں کی شناخت کر سکتی ہے؟',
    'faq_plants_a': 'ایپ پودوں کی وسیع رینج کو سپورٹ کرتی ہے، بشمول عام گھریلو پودے، باغ کے پودے اور فصلیں۔ تفصیلات کے لیے پودوں کا ڈیٹا بیس چیک کریں۔',
    'faq_accuracy_q': 'نتائج کتنے درست ہیں؟',
    'faq_accuracy_a': 'ہمارا AI ماڈل اعلیٰ درستگی فراہم کرتا ہے، لیکن نتائج تصویر کے معیار اور پودے کی حالت پر منحصر ہیں۔ نازک معاملات کے لیے ہمیشہ پیشہ ور سے مشورہ کریں۔',
    'faq_history_q': 'کیا میں اپنی اسکین ہسٹری محفوظ کر سکتا ہوں؟',
    'faq_history_a': 'جی ہاں، تمام اسکینز آپ کی پروفائل میں محفوظ ہیں۔ آپ انہیں ہسٹری سیکشن سے دیکھ، حذف یا شیئر کر سکتے ہیں۔',
    'faq_what_is_agriguard_q': 'AgriGuard کیا ہے؟',
    'faq_what_is_agriguard_a': 'AgriGuard ایک AI سے چلنے والی پودوں کی شناخت اور بیماری کا پتہ لگانے والی ایپ ہے جو TensorFlow مشین لرننگ استعمال کرتی ہے تاکہ 12 پودوں کی اقسام کی شناخت اور تصاویر سے 18 عام پودوں کی بیماریوں کا پتہ لگایا جا سکے، انٹرنیٹ کنکشن کے بغیر بھی۔',
    'faq_offline_q': 'کیا میں ایپ کو انٹرنیٹ کے بغیر استعمال کر سکتا ہوں؟',
    'faq_offline_a': 'جی ہاں! PlantDetect ہمارے بہتر شدہ TensorFlow Lite ماڈل کی بدولت مکمل طور پر آف لائن کام کرتا ہے۔ تمام پودوں کی شناخت اور بیماری کی تشخیص آپ کے ڈیوائس پر انٹرنیٹ کنکشن کی ضرورت کے بغیر ہوتی ہے۔',
    'faq_best_photo_q': 'اسکیننگ کے لیے بہترین تصویر کیسے لی جائے؟',
    'faq_best_photo_a': 'بہترین نتائج کے لیے: 1) قدرتی روشنی استعمال کریں، 2) پتوں یا متاثرہ علاقوں پر توجہ دیں، 3) کیمرہ کو مستحکم رکھیں، 4) فریم کو پودے سے بھریں، 5) ضرورت پڑنے پر مختلف زاویوں سے لیں۔ سائے اور دھندلی تصاویر سے بچیں۔',
  };

  // Plant translations
  static const Map<String, Map<String, String>> _plantTranslations = {
    'tomato': {'en': 'Tomato', 'ur': 'ٹماٹر'},
    'potato': {'en': 'Potato', 'ur': 'آلو'},
    'corn': {'en': 'Corn', 'ur': 'مکئی'},
    'maize': {'en': 'Maize', 'ur': 'مکئی'},
    'wheat': {'en': 'Wheat', 'ur': 'گندم'},
    'rice': {'en': 'Rice', 'ur': 'چاول'},
    'cotton': {'en': 'Cotton', 'ur': 'کپاس'},
    'sugarcane': {'en': 'Sugarcane', 'ur': 'گنا'},
    'pepper': {'en': 'Pepper', 'ur': 'مرچ'},
    'bell pepper': {'en': 'Bell Pepper', 'ur': 'شملہ مرچ'},
    'apple': {'en': 'Apple', 'ur': 'سیب'},
    'grape': {'en': 'Grape', 'ur': 'انگور'},
    'strawberry': {'en': 'Strawberry', 'ur': 'اسٹرابیری'},
    'peach': {'en': 'Peach', 'ur': 'آڑو'},
    'cherry': {'en': 'Cherry', 'ur': 'چیری'},
    'orange': {'en': 'Orange', 'ur': 'مالٹا'},
    'lemon': {'en': 'Lemon', 'ur': 'لیموں'},
    'mango': {'en': 'Mango', 'ur': 'آم'},
    'banana': {'en': 'Banana', 'ur': 'کیلا'},
    'guava': {'en': 'Guava', 'ur': 'امرود'},
    'soybean': {'en': 'Soybean', 'ur': 'سویابین'},
    // PlantCity model additions
    'blueberry': {'en': 'Blueberry', 'ur': 'بلیو بیری'},
    'raspberry': {'en': 'Raspberry', 'ur': 'رسبری'},
    'squash': {'en': 'Squash', 'ur': 'کدو'},
    'walnut': {'en': 'Walnut', 'ur': 'اخروٹ'},
    'fig': {'en': 'Fig', 'ur': 'انجیر'},
    'pear': {'en': 'Pear', 'ur': 'ناشپاتی'},
    'persimmon': {'en': 'Persimmon', 'ur': 'جاپانی پھل'},
    'loquat': {'en': 'Loquat', 'ur': 'لوکاٹ'},
    'apricot': {'en': 'Apricot', 'ur': 'خوبانی'},
    'bean': {'en': 'Bean', 'ur': 'پھلی'},
    'unknown plant': {'en': 'Unknown Plant', 'ur': 'نامعلوم پودا'},
  };

  // Disease translations — all PlantVillage + PlantCity classes
  static const Map<String, Map<String, String>> _diseaseTranslations = {
    'healthy': {'en': 'Healthy', 'ur': 'صحت مند'},
    'normal': {'en': 'Healthy', 'ur': 'صحت مند'},
    // Apple
    'apple scab': {'en': 'Apple Scab', 'ur': 'سیب کا خارش'},
    'black rot': {'en': 'Black Rot', 'ur': 'کالی سڑن'},
    'cedar apple rust': {'en': 'Cedar Apple Rust', 'ur': 'دیودار سیب کا زنگ'},
    'brown spot': {'en': 'Brown Spot', 'ur': 'بھورا داغ'},
    'fire blight': {'en': 'Fire Blight', 'ur': 'آگ کا جھلساؤ'},
    // Cherry
    'powdery mildew': {'en': 'Powdery Mildew', 'ur': 'سفید پھپھوندی'},
    'shot hole disease': {'en': 'Shot Hole Disease', 'ur': 'گولی کے سوراخ کی بیماری'},
    'shot hole': {'en': 'Shot Hole', 'ur': 'گولی کا سوراخ'},
    // Corn / Maize
    'cercospora leaf spot': {'en': 'Cercospora Leaf Spot', 'ur': 'سرکوسپورا پتوں کا داغ'},
    'gray leaf spot': {'en': 'Gray Leaf Spot', 'ur': 'سرمئی پتوں کا داغ'},
    'common rust': {'en': 'Common Rust', 'ur': 'عام زنگ'},
    'northern leaf blight': {'en': 'Northern Leaf Blight', 'ur': 'شمالی پتوں کا جھلساؤ'},
    'holcus leaf spot': {'en': 'Holcus Leaf Spot', 'ur': 'ہولکس پتوں کا داغ'},
    // Grape
    'esca': {'en': 'Esca', 'ur': 'ایسکا'},
    'black measles': {'en': 'Black Measles', 'ur': 'کالا خسرہ'},
    'leaf blight': {'en': 'Leaf Blight', 'ur': 'پتوں کا جھلساؤ'},
    'downy mildew': {'en': 'Downy Mildew', 'ur': 'نیچے کی پھپھوندی'},
    'anthracnose': {'en': 'Anthracnose', 'ur': 'انتھراکنوز'},
    // Orange / Citrus
    'haunglongbing': {'en': 'Haunglongbing', 'ur': 'ہوانگلونگبنگ'},
    'citrus greening': {'en': 'Citrus Greening', 'ur': 'سٹرس گریننگ'},
    // Peach & Pepper
    'bacterial spot': {'en': 'Bacterial Spot', 'ur': 'بیکٹیریل داغ'},
    // Potato & Tomato
    'early blight': {'en': 'Early Blight', 'ur': 'ابتدائی جھلساؤ'},
    'late blight': {'en': 'Late Blight', 'ur': 'تاخیری جھلساؤ'},
    // Strawberry / Tomato
    'leaf scorch': {'en': 'Leaf Scorch', 'ur': 'پتوں کا جھلساؤ'},
    // Tomato
    'leaf mold': {'en': 'Leaf Mold', 'ur': 'پتوں کی سڑن'},
    'septoria leaf spot': {'en': 'Septoria Leaf Spot', 'ur': 'سیپٹوریا داغ'},
    'spider mites': {'en': 'Spider Mites', 'ur': 'مکڑی کیڑے'},
    'two spotted spider mite': {'en': 'Two-Spotted Spider Mite', 'ur': 'دو دھبوں والا مکڑی کیڑا'},
    'target spot': {'en': 'Target Spot', 'ur': 'ہدف داغ'},
    'tomato yellow leaf curl virus': {'en': 'Yellow Leaf Curl Virus', 'ur': 'یلو لیف کرل وائرس'},
    'yellow leaf curl virus': {'en': 'Yellow Leaf Curl Virus', 'ur': 'یلو لیف کرل وائرس'},
    'leaf curl': {'en': 'Leaf Curl', 'ur': 'پتوں کا مڑنا'},
    'tomato mosaic virus': {'en': 'Tomato Mosaic Virus', 'ur': 'ٹماٹر موزیک وائرس'},
    'mosaic virus': {'en': 'Mosaic Virus', 'ur': 'موزیک وائرس'},
    // Wilt diseases
    'fusarium wilt': {'en': 'Fusarium Wilt', 'ur': 'فیوزیریم مرجھاؤ'},
    'verticillium wilt': {'en': 'Verticillium Wilt', 'ur': 'ورٹیسیلیم مرجھاؤ'},
    // Fig / Walnut / Pear
    'rust leaf': {'en': 'Rust', 'ur': 'زنگ'},
    'leaf spot': {'en': 'Leaf Spot', 'ur': 'پتوں کا داغ'},
    'blotch': {'en': 'Blotch', 'ur': 'دھبہ'},
    'leaf miner': {'en': 'Leaf Miner', 'ur': 'پتوں کا کیڑا'},
    // Generic
    'rust': {'en': 'Rust', 'ur': 'زنگ'},
    'blight': {'en': 'Blight', 'ur': 'جھلساؤ'},
    'spot': {'en': 'Spot', 'ur': 'داغ'},
    'mildew': {'en': 'Mildew', 'ur': 'پھپھوندی'},
    'scorch': {'en': 'Scorch', 'ur': 'جھلساؤ'},
    'rot': {'en': 'Rot', 'ur': 'سڑن'},
    'virus': {'en': 'Virus', 'ur': 'وائرس'},
    'wilt': {'en': 'Wilt', 'ur': 'مرجھاؤ'},
    'canker': {'en': 'Canker', 'ur': 'کینکر'},
    'scab': {'en': 'Scab', 'ur': 'خارش'},
    'unable to determine': {'en': 'Unable to Determine', 'ur': 'تعین نہیں ہو سکا'},
    'image not recognized': {'en': 'Image Not Recognized', 'ur': 'تصویر کی شناخت نہیں ہوئی'},
  };

  // Severity translations
  static const Map<String, String> _severityTranslations = {
    'low': 'کم',
    'medium': 'درمیانہ',
    'high': 'زیادہ',
    'critical': 'انتہائی خطرناک',
    'none': 'کوئی نہیں',
    'n/a': 'لاگو نہیں',
  };
}