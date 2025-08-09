import 'package:image/image.dart' as img;

class EditingHistory {
  final img.Image image;
  final String action;
  final DateTime timestamp;

  EditingHistory({
    required this.image,
    required this.action,
    required this.timestamp,
  });
}