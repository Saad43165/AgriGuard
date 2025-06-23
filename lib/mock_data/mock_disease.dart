// mock_diseases.dart
/// Mock data for plant diseases.
/// Each disease includes a name, description, symptoms, and possible causes.
/// This data can be used for testing the ResultsScreen and other UI components.
const List<Map<String, dynamic>> mockDiseases = [
  {
    'id': 'disease_001',
    'name': 'Late Blight',
    'description':
    'A common fungal disease affecting potatoes and tomatoes caused by Phytophthora infestans.',
    'symptoms': [
      'Dark, water-soaked spots on leaves',
      'White fungal growth on leaf undersides',
      'Brown, shriveled tubers'
    ],
    'causes': [
      'High humidity',
      'Cool, wet weather',
      'Infected plant debris'
    ],
    'crop_types': ['Potato', 'Tomato'],
  },
  {
    'id': 'disease_002',
    'name': 'Powdery Mildew',
    'description':
    'A fungal disease caused by a variety of fungi, affecting a wide range of plants.',
    'symptoms': [
      'White or grayish powdery spots on leaves',
      'Yellowing and curling leaves',
      'Stunted growth'
    ],
    'causes': [
      'Warm, dry conditions',
      'Poor air circulation',
      'Overcrowded plants'
    ],
    'crop_types': ['Cucumber', 'Squash', 'Grapes'],
  },
  {
    'id': 'disease_003',
    'name': 'Bacterial Leaf Spot',
    'description':
    'A bacterial disease caused by Xanthomonas species, affecting leafy crops.',
    'symptoms': [
      'Small, water-soaked spots with yellow halos',
      'Leaf drop',
      'Blackened veins'
    ],
    'causes': [
      'Warm, wet conditions',
      'Overhead watering',
      'Contaminated seeds'
    ],
    'crop_types': ['Pepper', 'Lettuce', 'Tomato'],
  },
];