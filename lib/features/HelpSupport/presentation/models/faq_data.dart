import '../models/faq_category.dart';
import 'faq_items.dart';

class FaqData {
  static final List<FaqItem> allFaqItems = [
    // General FAQs
    FaqItem(
      question: 'What is AgriGuard?',
      answer: 'AgriGuard is an AI-powered plant identification and disease detection app that uses TensorFlow machine learning to identify 12 plant species and detect 18 common plant diseases from photos, even without internet connection.',
      category: FaqCategory.general,
      tags: ['identification', 'AI', 'TensorFlow', 'offline'],
    ),
    FaqItem(
      question: 'How accurate is the plant and disease detection?',
      answer: 'Our TensorFlow model achieves 92% accuracy for plant species identification and 88% accuracy for disease detection. Accuracy depends on photo quality, lighting, and clear visibility of plant features.',
      category: FaqCategory.general,
      tags: ['accuracy', 'AI', 'TensorFlow', 'reliability'],
    ),
    FaqItem(
      question: 'Can I use the app without internet?',
      answer: 'Yes! PlantDetect works completely offline thanks to our optimized TensorFlow Lite model. All plant identification and disease detection happens on your device without needing internet connection.',
      category: FaqCategory.general,
      tags: ['offline', 'TensorFlow Lite', 'no internet'],
    ),

    // Scanning FAQs
    FaqItem(
      question: 'How do I take the best photo for scanning?',
      answer: 'For optimal results: 1) Use natural lighting, 2) Focus on leaves or affected areas, 3) Keep camera steady, 4) Fill frame with plant, 5) Take multiple angles if needed. Avoid shadows and blurry images.',
      category: FaqCategory.scanning,
      tags: ['photography', 'tips', 'lighting', 'scanning'],
    ),
    FaqItem(
      question: 'What plant species can the app identify?',
      answer: 'PlantDetect identifies 12 common plant species: Tomato, Potato, Bell Pepper, Corn, Apple, Grape, Strawberry, Peach, Cherry, Rose, Sunflower, and Soybean.',
      category: FaqCategory.scanning,
      tags: ['species', 'plants', 'supported', '12 species'],
    ),
    FaqItem(
      question: 'What diseases can the app detect?',
      answer: 'We detect 18 common plant diseases including Early Blight, Late Blight, Leaf Spot, Powdery Mildew, Bacterial Spot, Leaf Curl, Mold, Rust, Scab, and various fungal infections.',
      category: FaqCategory.scanning,
      tags: ['diseases', 'detection', '18 diseases', 'health'],
    ),
    FaqItem(
      question: 'What information does the scan result show?',
      answer: 'Each scan provides: 1) Plant Name, 2) Disease Name, 3) Severity Level, 4) Cause Analysis, 5) Remediation Steps with treatment recommendations and preventive measures.',
      category: FaqCategory.scanning,
      tags: ['results', 'output', 'information', 'analysis'],
    ),

    // Database FAQs
    FaqItem(
      question: 'How often is the plant database updated?',
      answer: 'The TensorFlow model and plant database receive quarterly updates with improved accuracy and new features. Updates are automatically applied when you update the app.',
      category: FaqCategory.database,
      tags: ['updates', 'database', 'model', 'TensorFlow'],
    ),
    FaqItem(
      question: 'Can I suggest new plant species or diseases?',
      answer: 'Yes! Go to Settings > Suggest New Plants to request additional species or diseases. We review all suggestions for future model updates.',
      category: FaqCategory.database,
      tags: ['suggestions', 'new species', 'feedback'],
    ),
    FaqItem(
      question: 'How large is the TensorFlow model?',
      answer: 'The optimized TensorFlow Lite model is approximately 45MB, designed for mobile devices with minimal storage impact while maintaining high accuracy.',
      category: FaqCategory.database,
      tags: ['model size', 'storage', 'TensorFlow Lite', 'optimized'],
    ),

    // Account FAQs
    FaqItem(
      question: 'Do I need an account to use the app?',
      answer: 'No account is required for basic scanning features. Creating an account allows you to save scan history, sync across devices, and access premium features.',
      category: FaqCategory.account,
      tags: ['account', 'registration', 'optional'],
    ),
    FaqItem(
      question: 'How do I save my scan history?',
      answer: 'Scan history is automatically saved locally. With an account, your history syncs to the cloud and can be accessed from any device.',
      category: FaqCategory.account,
      tags: ['history', 'save', 'cloud', 'sync'],
    ),
    FaqItem(
      question: 'Is my plant data private?',
      answer: 'Yes! All plant scans and photos are processed locally on your device. We never upload your plant images to our servers without your permission.',
      category: FaqCategory.account,
      tags: ['privacy', 'data', 'local processing', 'security'],
    ),

    // Technical FAQs
    FaqItem(
      question: 'What are the system requirements?',
      answer: 'Android: 7.0+ with 2GB RAM. iOS: 13.0+. Requires camera and 50MB free storage for the TensorFlow model. Works best on devices with 3GB+ RAM.',
      category: FaqCategory.technical,
      tags: ['requirements', 'compatibility', 'devices'],
    ),
    FaqItem(
      question: 'Why is scanning taking longer than expected?',
      answer: 'Scan time depends on device processor. Average scan time is 2-5 seconds. Older devices may take up to 10 seconds for TensorFlow processing.',
      category: FaqCategory.technical,
      tags: ['performance', 'speed', 'scan time', 'processing'],
    ),
    FaqItem(
      question: 'How do I improve scanning accuracy?',
      answer: 'Ensure good lighting, focus on clear plant features, avoid multiple plants in one image, and keep camera steady. The TensorFlow model works best with clear, well-lit images.',
      category: FaqCategory.technical,
      tags: ['accuracy', 'improve', 'tips', 'TensorFlow'],
    ),
    FaqItem(
      question: 'Can I use the app in low light conditions?',
      answer: 'While possible, low light significantly reduces accuracy. We recommend using flash or moving to better lighting for reliable TensorFlow analysis.',
      category: FaqCategory.technical,
      tags: ['lighting', 'conditions', 'accuracy', 'flash'],
    ),

    // Sharing FAQs
    FaqItem(
      question: 'How do I share scan results with others?',
      answer: 'Tap the share icon on any result screen to export plant details, disease information, and treatment recommendations via email, messaging, or social media.',
      category: FaqCategory.sharing,
      tags: ['sharing', 'export', 'results', 'social'],
    ),
    FaqItem(
      question: 'Can I export my scan history for my records?',
      answer: 'Yes! Go to History > Export to download your complete scan history as PDF or CSV, including all plants, diseases, dates, and treatment plans.',
      category: FaqCategory.sharing,
      tags: ['export', 'history', 'backup', 'records'],
    ),
    FaqItem(
      question: 'How do I report incorrect identification?',
      answer: 'From the results screen, tap "Report Issue" to help us improve our TensorFlow model. Your feedback helps train better AI models.',
      category: FaqCategory.sharing,
      tags: ['feedback', 'report', 'improve', 'TensorFlow'],
    ),
  ];
}