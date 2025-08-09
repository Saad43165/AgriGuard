import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';

class StickersPanel extends StatelessWidget {
  final Function(String, Color) onStickerAdded;

  const StickersPanel({super.key, required this.onStickerAdded});

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    return Wrap(
      spacing: padding,
      runSpacing: padding,
      children: [
        _buildStickerIcon(Icons.favorite, 'Heart', Colors.red),
        _buildStickerIcon(Icons.star, 'Star', Colors.yellow),
        _buildStickerIcon(Icons.local_florist, 'Flower', Colors.green),
      ],
    );
  }

  Widget _buildStickerIcon(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () => onStickerAdded(label, color),
      child: Chip(
        avatar: Icon(icon, color: color),
        label: Text(label),
        backgroundColor: Colors.white,
      ),
    );
  }
}