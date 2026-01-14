import 'package:flutter/material.dart';

class Statistics extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  final EdgeInsets cardPadding;
  final double itemSpacing;

  const Statistics({
    super.key,
    required this.userProfile,
    required this.cardPadding,
    required this.itemSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final int scans = userProfile['scanCount'] ?? 0;
    final int reports = userProfile['reportCount'] ?? 0;

    return Container(
      height: 110, // Fixed height for the entire row
      child: Row(
        children: [
          // Scans Card
          Expanded(
            child: _StatCard(
              value: scans.toString(),
              label: 'Scans',
              color: const Color(0xFF9B86F5),
              icon: Icons.scanner_rounded,
            ),
          ),
          SizedBox(width: itemSpacing),

          // Reports Card
          Expanded(
            child: _StatCard(
              value: reports.toString(),
              label: 'Reports',
              color: const Color(0xFF4CAF50),
              icon: Icons.description_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.7),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),

          // Value
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),

          // Label
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}