import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/translation_service.dart';

class MethodCard extends StatelessWidget {
  final String method;
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final List<String> features;
  final List<Color> gradient;
  final bool isReady;
  final String? loadingText;
  final VoidCallback? onSelect;

  const MethodCard({
    super.key,
    required this.method,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
    required this.gradient,
    required this.isReady,
    this.loadingText,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final translation = TranslationService();
    final effectiveColor = isReady ? gradient[0] : Colors.grey;

    return AnimatedBuilder(
      animation: translation,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isReady
                ? () {
              HapticFeedback.mediumImpact();
              onSelect?.call();
            }
                : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isReady
                      ? [
                    effectiveColor.withOpacity(isDark ? 0.2 : 0.12),
                    gradient[1].withOpacity(isDark ? 0.15 : 0.06)
                  ]
                      : [
                    Colors.grey.withOpacity(0.15),
                    Colors.grey.withOpacity(0.08)
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isReady
                      ? effectiveColor.withOpacity(isDark ? 0.5 : 0.4)
                      : Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, translation, effectiveColor, isDark),
                  const SizedBox(height: 8),
                  _buildDescription(context, isDark),
                  if (features.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildFeatures(isDark, effectiveColor),
                  ],
                  const SizedBox(height: 10),
                  _buildSelectButton(context, translation, effectiveColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, TranslationService translation,
      Color effectiveColor, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: isReady
                ? LinearGradient(colors: gradient)
                : LinearGradient(
                colors: [Colors.grey.shade500, Colors.grey.shade600]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isReady
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.grey,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  color: isReady ? effectiveColor : Colors.grey,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        _buildStatusBadge(translation, isDark),
      ],
    );
  }

  Widget _buildStatusBadge(TranslationService translation, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: isReady
            ? Colors.green.withOpacity(isDark ? 0.25 : 0.15)
            : Colors.orange.withOpacity(isDark ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady ? Colors.green : Colors.orange,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReady ? Icons.check_circle : Icons.hourglass_empty,
            size: 11,
            color: isReady ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 3),
          Text(
            isReady ? '✓' : '⏳',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: isReady ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context, bool isDark) {
    return Text(
      description,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: isReady
            ? (isDark
            ? Colors.white.withOpacity(0.8)
            : Colors.black.withOpacity(0.75))
            : Colors.grey,
        height: 1.3,
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFeatures(bool isDark, Color effectiveColor) {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: features.take(4).map((feature) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: isReady
                ? effectiveColor.withOpacity(isDark ? 0.2 : 0.12)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isReady
                  ? effectiveColor.withOpacity(isDark ? 0.4 : 0.3)
                  : Colors.grey.withOpacity(0.3),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 10,
                color: isReady ? effectiveColor : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                feature,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isReady
                      ? (isDark ? Colors.white : const Color(0xFF2C3E50))
                      : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectButton(
      BuildContext context, TranslationService translation, Color effectiveColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        gradient: isReady
            ? LinearGradient(
          colors: gradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        )
            : LinearGradient(colors: [Colors.grey, Colors.grey.shade700]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isReady && loadingText != null)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          if (!isReady && loadingText != null) const SizedBox(width: 8),
          Text(
            isReady ? 'SELECT METHOD' : (loadingText ?? 'LOADING...'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
          if (isReady) const SizedBox(width: 6),
          if (isReady)
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 16,
            ),
        ],
      ),
    );
  }
}