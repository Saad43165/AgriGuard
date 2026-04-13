import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../../core/widgets/app_themes.dart';
import '../../../../../core/services/translation_service.dart';

/// Single-screen scan launcher — replaces the 3-step wizard.
/// Shows method selection + source selection on one page.
class WelcomeScreen extends StatefulWidget {
  final Animation<double> scaleAnimation;
  final bool isGuestMode;
  final int remainingScans;
  final Map<String, bool> modelStatuses;
  final VoidCallback onStartScan; // kept for compatibility — not used directly
  // New callbacks for direct launch
  final void Function(String method, ImageSource source) onLaunch;
  final bool isTFLiteReady;
  final bool isAdvancedAllowed;
  final String? advancedUnavailableReason;

  const WelcomeScreen({
    super.key,
    required this.scaleAnimation,
    required this.isGuestMode,
    required this.remainingScans,
    required this.modelStatuses,
    required this.onStartScan,
    required this.onLaunch,
    this.isTFLiteReady = true,
    this.isAdvancedAllowed = true,
    this.advancedUnavailableReason,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _selectedMethod = 'tflite'; // 'tflite' or 'api'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = Provider.of<TranslationService>(context);
    final textPrimary = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final textSub = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scan a Plant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -0.5)),
                    Text('Detect diseases instantly with AI', style: TextStyle(fontSize: 12, color: textSub, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (widget.isGuestMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Text('${widget.remainingScans} left',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.warning)),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Analysis Method ──────────────────────────────────────────
          Text('Analysis Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSub)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MethodTile(
                icon: Icons.phone_android_rounded,
                label: 'On-Device',
                sublabel: 'Fast • Offline',
                color: AppColors.primary,
                isSelected: _selectedMethod == 'tflite',
                isEnabled: widget.isTFLiteReady,
                loadingLabel: widget.isTFLiteReady ? null : 'Loading...',
                onTap: widget.isTFLiteReady ? () => setState(() => _selectedMethod = 'tflite') : null,
              )),
              const SizedBox(width: 10),
              Expanded(child: _MethodTile(
                icon: Icons.cloud_rounded,
                label: 'Advanced AI',
                sublabel: 'Cloud • Detailed',
                color: AppColors.secondary,
                isSelected: _selectedMethod == 'api',
                isEnabled: widget.isAdvancedAllowed,
                loadingLabel: widget.isAdvancedAllowed ? null : (widget.advancedUnavailableReason ?? 'Locked'),
                onTap: widget.isAdvancedAllowed ? () => setState(() => _selectedMethod = 'api') : null,
              )),
            ],
          ),

          const SizedBox(height: 24),

          // ── Image Source ─────────────────────────────────────────────
          Text('Choose Image Source', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSub)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _SourceButton(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                sublabel: 'Take a photo',
                color: AppColors.primary,
                onTap: () { HapticFeedback.mediumImpact(); widget.onLaunch(_selectedMethod, ImageSource.camera); },
              )),
              const SizedBox(width: 10),
              Expanded(child: _SourceButton(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                sublabel: 'Pick from library',
                color: AppColors.secondary,
                onTap: () { HapticFeedback.mediumImpact(); widget.onLaunch(_selectedMethod, ImageSource.gallery); },
              )),
            ],
          ),

          const SizedBox(height: 24),

          // ── Tips ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.lightbulb_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('Photo Tips', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ]),
                const SizedBox(height: 8),
                ...[
                  'Focus on the affected leaf area',
                  'Ensure good lighting — avoid shadows',
                  'Hold steady for a sharp image',
                  'Fill the frame with the leaf',
                ].map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 4, height: 4, margin: const EdgeInsets.only(top: 5, right: 8),
                        decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                      Expanded(child: Text(tip, style: TextStyle(fontSize: 11, color: textSub, fontWeight: FontWeight.w500, height: 1.4))),
                    ],
                  ),
                )),
              ],
            ),
          ),

          // Model status
          if (!widget.isTFLiteReady) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warning)),
                  const SizedBox(width: 10),
                  Text('Loading AI models...', style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final bool isSelected;
  final bool isEnabled;
  final String? loadingLabel;
  final VoidCallback? onTap;

  const _MethodTile({
    required this.icon, required this.label, required this.sublabel,
    required this.color, required this.isSelected, required this.isEnabled,
    this.loadingLabel, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = isEnabled ? color : AppColors.lightCaption;
    final textColor = isSelected ? Colors.white : (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface);
    final subColor = isSelected ? Colors.white.withValues(alpha: 0.85) : effectiveColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          // Solid color when selected, subtle when not
          color: isSelected
              ? effectiveColor
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? effectiveColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 0 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: effectiveColor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.22) : effectiveColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: isSelected ? Colors.white : effectiveColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
                  const SizedBox(height: 2),
                  Text(loadingLabel ?? sublabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: subColor)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white)
            else if (!isEnabled)
              Icon(Icons.lock_rounded, size: 16, color: AppColors.lightCaption),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon, required this.label, required this.sublabel,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 2),
              Text(sublabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 10, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
