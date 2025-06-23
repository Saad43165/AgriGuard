// mock_scans.dart
/// Mock data for plant scans.
/// Each scan includes an ID, user ID, disease ID, timestamp, severity, and recommendations.
/// This data can be used for testing scan history or result displays like ResultsScreen.
const List<Map<String, dynamic>> mockScans = [
  {
    'id': 'scan_001',
    'user_id': 'user_001',
    'disease_id': 'disease_001', // Late Blight
    'timestamp': '2025-06-20T08:45:00Z',
    'severity': 'High',
    'image_url': 'https://example.com/scans/scan_001.jpg',
    'crop_type': 'Potato',
    'recommendations': [
      'Remove affected leaves immediately',
      'Apply copper fungicide every 7-10 days',
      'Avoid overhead watering',
    ],
    'confidence_score': 0.92,
  },
  {
    'id': 'scan_002',
    'user_id': 'user_002',
    'disease_id': 'disease_002', // Powdery Mildew
    'timestamp': '2025-06-21T12:30:00Z',
    'severity': 'Moderate',
    'image_url': 'https://example.com/scans/scan_002.jpg',
    'crop_type': 'Cucumber',
    'recommendations': [
      'Improve air circulation around plants',
      'Apply sulfur-based fungicide',
      'Remove infected plant parts',
    ],
    'confidence_score': 0.85,
  },
  {
    'id': 'scan_003',
    'user_id': 'user_003',
    'disease_id': 'disease_003', // Bacterial Leaf Spot
    'timestamp': '2025-06-22T15:20:00Z',
    'severity': 'Low',
    'image_url': 'https://example.com/scans/scan_003.jpg',
    'crop_type': 'Lettuce',
    'recommendations': [
      'Use drip irrigation to avoid wet foliage',
      'Apply copper-based bactericide',
      'Rotate crops to prevent recurrence',
    ],
    'confidence_score': 0.78,
  },
];