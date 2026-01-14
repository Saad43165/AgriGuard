import 'package:flutter/material.dart';

class FeatureHighlights extends StatelessWidget {
  const FeatureHighlights({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Features',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildFeatureTile(
              context,
              icon: Icons.search_rounded,
              title: 'Identify Plants',
              description: 'Recognize 50,000+ plant species',
              color: Colors.green,
            ),
            _buildFeatureTile(
              context,
              icon: Icons.health_and_safety_rounded,
              title: 'Disease Detection',
              description: 'Spot common plant diseases',
              color: Colors.orange,
            ),
            _buildFeatureTile(
              context,
              icon: Icons.medication_rounded,
              title: 'Treatment Plans',
              description: 'Get expert recommendations',
              color: Colors.blue,
            ),
            _buildFeatureTile(
              context,
              icon: Icons.offline_bolt_rounded,
              title: 'Offline Mode',
              description: 'Works without internet',
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
        required Color color,
      }) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: color), // Smaller icon
          const SizedBox(height: 8),
          Flexible( // Added Flexible for title
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14, // Smaller font
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Flexible( // Added Flexible for description
            child: Text(
              description,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 11, // Smaller font
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}