import 'package:flutter/material.dart';
import '../../../../core/services/translation_service.dart';

class ProcessingOverlay extends StatelessWidget {
  final String selectedMethod;
  final bool isProcessing;
  final bool isGuestMode;
  final int remainingScans;
  final Animation<double> pulseAnimation;
  final String processingMessage;
  final Map<String, bool> modelStatuses;
  final VoidCallback onCancel;

  const ProcessingOverlay({
    super.key,
    required this.selectedMethod,
    required this.isProcessing,
    required this.isGuestMode,
    required this.remainingScans,
    required this.pulseAnimation,
    required this.processingMessage,
    required this.modelStatuses,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final translation = TranslationService();

    return AnimatedBuilder(
      animation: translation,
      builder: (context, child) {
        return Container(
          color: Colors.black.withValues(alpha: 0.9),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                          width: 85,
                          height: 85,
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

              Column(
                children: [
                  Text(
                    translation.get('processing_analyzing'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    translation.get(selectedMethod == 'tflite'
                        ? 'processing_ondevice_subtitle'
                        : 'processing_cloud_subtitle'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                ),
                child: Column(
                  children: [
                    _buildProgressStages(context, translation),
                    const SizedBox(height: 24),
                    _buildLoadingBar(theme, translation),
                    if (isGuestMode) _buildGuestStats(translation),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              TextButton(
                onPressed: isProcessing ? onCancel : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                ),
                child: Text(
                  translation.get('processing_cancel'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressStages(BuildContext context, TranslationService translation) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStage(context, '📸', translation.get('processing_image_captured'), true),
        _buildStage(context, '🔍', translation.get('processing_analyzing_stage'), true),
        _buildStage(context, '📊', translation.get('processing_generating'), false),
      ],
    );
  }

  Widget _buildStage(BuildContext context, String emoji, String text, bool isComplete) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: isComplete
                  ? LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              )
                  : null,
              color: !isComplete ? Colors.white.withValues(alpha: 0.2) : null,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isComplete
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                  : Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              color: isComplete ? Colors.white : Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBar(ThemeData theme, TranslationService translation) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 8,
            color: theme.colorScheme.primary,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          translation.get('processing_text'),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildGuestStats(TranslationService translation) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Text(
          '$remainingScans ${translation.get('processing_guest_scans')}',
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}