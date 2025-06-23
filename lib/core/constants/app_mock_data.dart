// lib/core/constants/app_mock_data.dart
class AppMockData {
  // Mock credentials for login/register
  static const String mockEmail = 'test@agriguard.com';
  static const String mockPassword = 'password123';
  static const String mockFullName = 'John Doe';

  // Mock scan results
  static final List<Map<String, dynamic>> recentScans = [
    {
      'id': '1',
      'image': 'assets/images/plant1.jpg',
      'result': 'Healthy',
      'severity': 'None',
      'timestamp': '2025-06-22 10:30 AM',
    },
    {
      'id': '2',
      'image': 'assets/images/plant2.jpg',
      'result': 'Powdery Mildew',
      'severity': 'Moderate',
      'timestamp': '2025-06-21 03:15 PM',
    },
    {
      'id': '3',
      'image': 'assets/images/plant3.jpg',
      'result': 'Leaf Spot',
      'severity': 'Severe',
      'timestamp': '2025-06-20 08:45 AM',
    },
  ];
}