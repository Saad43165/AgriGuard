// mock_users.dart
/// Mock data for users.
/// Each user includes an ID, name, email, and farm details.
/// This data can be used for testing user-related features like scan history or profiles.
const List<Map<String, dynamic>> mockUsers = [
  {
    'id': 'user_001',
    'name': 'John Doe',
    'email': 'john.doe@example.com',
    'phone': '+1-555-123-4567',
    'farm': {
      'name': 'Doe Family Farm',
      'location': 'Iowa, USA',
      'crops': ['Potato', 'Corn', 'Tomato'],
      'size_hectares': 50,
    },
    'created_at': '2025-01-15T10:00:00Z',
  },
  {
    'id': 'user_002',
    'name': 'Ayesha Khan',
    'email': 'ayesha.khan@example.com',
    'phone': '+92-300-987-6543',
    'farm': {
      'name': 'Khan Agri Farms',
      'location': 'Punjab, Pakistan',
      'crops': ['Wheat', 'Cucumber', 'Pepper'],
      'size_hectares': 30,
    },
    'created_at': '2025-02-20T14:30:00Z',
  },
  {
    'id': 'user_003',
    'name': 'Maria Silva',
    'email': 'maria.silva@example.com',
    'phone': '+55-11-91234-5678',
    'farm': {
      'name': 'Silva Agro',
      'location': 'São Paulo, Brazil',
      'crops': ['Grapes', 'Lettuce', 'Squash'],
      'size_hectares': 20,
    },
    'created_at': '2025-03-10T09:15:00Z',
  },
];