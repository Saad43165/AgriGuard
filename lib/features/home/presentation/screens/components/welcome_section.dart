import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/constants/app_measurements.dart';
import 'glass_card.dart';

class WelcomeSection extends StatelessWidget {
  final bool isFirstTimeUser;
  final Animation<double> scaleAnimation;

  const WelcomeSection({
    super.key,
    required this.isFirstTimeUser,
    required this.scaleAnimation,
  });

  Future<String> _getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? 'User';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getUserName(),
      builder: (context, snapshot) {
        final fullName = snapshot.data ?? 'User';
        return ScaleTransition(
          scale: scaleAnimation,
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.9),
                          Theme.of(context).colorScheme.secondary.withOpacity(0.9),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.eco_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'Welcome, $fullName!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 24),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isFirstTimeUser
                        ? 'Get started by scanning your first plant!'
                        : 'Your crop health insights await you.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}