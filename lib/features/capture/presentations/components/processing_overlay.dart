import 'package:flutter/material.dart';

class ProcessingOverlay extends StatelessWidget {
  final String selectedMethod;
  final bool isProcessing;
  final bool isGuestMode;
  final int remainingScans;
  final Animation<double> pulseAnimation;
  final VoidCallback onCancel;

  const ProcessingOverlay({
    super.key,
    required this.selectedMethod,
    required this.isProcessing,
    required this.isGuestMode,
    required this.remainingScans,
    required this.pulseAnimation,
    required this.onCancel, required String processingMessage, required Map<String, bool> modelStatuses,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme from context here

    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Processing Icon
          ScaleTransition(
            scale: pulseAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      selectedMethod == 'tflite'
                          ? Icons.phone_android_rounded
                          : Icons.cloud_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                    const SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Processing Text
          Column(
            children: [
              Text(
                'Analyzing Your Plant',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                selectedMethod == 'tflite'
                    ? 'Using on-device AI for instant results'
                    : 'Connecting to cloud AI for detailed analysis',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Progress Indicators
          Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                _buildProgressStages(context),
                const SizedBox(height: 20),
                _buildLoadingBar(theme),
                if (isGuestMode) _buildGuestStats(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Cancel Button
          TextButton(
            onPressed: isProcessing ? onCancel : null,
            child: const Text(
              'Cancel Analysis',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStages(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStage(context, '📸', 'Image Captured', true),
        _buildStage(context, '🔍', 'Analyzing', true),
        _buildStage(context, '📊', 'Generating Report', false),
      ],
    );
  }

  Widget _buildStage(BuildContext context, String emoji, String text, bool isComplete) {
    final theme = Theme.of(context); // Pass context to this method

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isComplete
                ? theme.colorScheme.primary
                : Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            color: isComplete ? Colors.white : Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingBar(ThemeData theme) {
    return Column(
      children: [
        LinearProgressIndicator(
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          color: theme.colorScheme.primary,
          backgroundColor: Colors.white.withOpacity(0.1),
        ),
        const SizedBox(height: 8),
        Text(
          'Processing...',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildGuestStats() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        '$remainingScans scans remaining in guest mode',
        style: const TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}