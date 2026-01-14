import 'package:flutter/material.dart';

class PhotoTips extends StatelessWidget {
  const PhotoTips({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera_front_rounded, color: Colors.orange),
              const SizedBox(width: 12),
              Text(
                'Photo Guidelines',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildGuidelines(context),
        ],
      ),
    );
  }

  List<Widget> _buildGuidelines(BuildContext context) {
    final guidelines = [
      {'type': 'do', 'text': 'Place leaf on plain, contrasting background'},
      {'type': 'do', 'text': 'Ensure good, natural lighting (avoid shadows)'},
      {'type': 'do', 'text': 'Focus camera on affected areas'},
      {'type': 'do', 'text': 'Take multiple photos if plant shows different symptoms'},
      {'type': 'dont', 'text': 'Avoid blurry or distant photos'},
      {'type': 'dont', 'text': 'Don\'t include multiple leaves unless necessary'},
      {'type': 'dont', 'text': 'Avoid flash photography (causes glare)'},
    ];

    return guidelines.map((guideline) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          guideline['type'] == 'do'
              ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
              : const Icon(Icons.cancel, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              guideline['text']!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }
}