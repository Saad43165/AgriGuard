import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_measurements.dart';
import 'image_Buttons.dart';

class ActionButtons extends StatelessWidget {
  final bool isLoading;
  final bool isProcessing;
  final XFile? imageFile;
  final Function(ImageSource) onPickImage;
  final VoidCallback onProcess;

  const ActionButtons({
    super.key,
    required this.isLoading,
    required this.isProcessing,
    required this.imageFile,
    required this.onPickImage,
    required this.onProcess,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppMeasurements.defaultPadding,
      ),
      child: Column(
        children: [
          // Tips only when no image
          if (imageFile == null) const _TipsSection(),

          // Animated transition: Buttons ↔ Change Chip
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: imageFile == null
                ? _buildPickImageButtons()
                : _ChangeImageChip(
              onCamera: () => onPickImage(ImageSource.camera),
              onGallery: () => onPickImage(ImageSource.gallery),
              isLoading: isLoading,
            ),
          ),

          const SizedBox(height: 90),

          // Analyze Button
          if (imageFile != null)
            _AnalyzeButton(
              isProcessing: isProcessing,
              onProcess: onProcess,
            ),
        ],
      ),
    );
  }

  Widget _buildPickImageButtons() {
    return Row(
      key: const ValueKey('pick_buttons'),
      children: [
        Expanded(
          child: ImageButton(
            icon: Icons.camera_alt_rounded,
            label: 'Camera',
            isPrimary: true,
            isEnabled: !isLoading,
            onPressed: () => onPickImage(ImageSource.camera),
          ),
        ),
        const SizedBox(width: AppMeasurements.defaultPadding),
        Expanded(
          child: ImageButton(
            icon: Icons.photo_library_rounded,
            label: 'Gallery',
            isPrimary: false,
            isEnabled: !isLoading,
            onPressed: () => onPickImage(ImageSource.gallery),
          ),
        ),
      ],
    );
  }
}

/// BEAUTIFUL, MATCHING, LARGER CHANGE IMAGE CHIP
class _ChangeImageChip extends StatefulWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final bool isLoading;

  const _ChangeImageChip({
    required this.onCamera,
    required this.onGallery,
    required this.isLoading,
  });

  @override
  State<_ChangeImageChip> createState() => _ChangeImageChipState();
}

class _ChangeImageChipState extends State<_ChangeImageChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    // Pulse once when first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pulseController.forward().then((_) => _pulseController.reverse());
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context) * 1.2);

    return Center(
      key: const ValueKey('change_chip'),
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: GestureDetector(
          onTap: widget.isLoading ? null : () => _showSourceSheet(context),
          child: Opacity(
            opacity: widget.isLoading ? 0.65 : 1.0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppMeasurements.defaultPadding * 1.1,
                vertical: AppMeasurements.smallPadding * 0.9,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.01),
                    theme.colorScheme.secondary.withOpacity(0.01),
                  ],
                ),
                borderRadius: borderRadius,
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: theme.colorScheme.secondary.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient icon badge
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.sync_rounded,
                      size: 18,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Change Image',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 15),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSourceSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Options
            _buildSheetOption(
              context,
              icon: Icons.camera_alt_rounded,
              label: 'Take Photo',
              onTap: () {
                Navigator.pop(context);
                widget.onCamera();
              },
            ),
            _buildSheetOption(
              context,
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                widget.onGallery();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetOption(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 22),
      ),
      title: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      minLeadingWidth: 40,
    );
  }
}

// ————————————————————————
// KEEP YOUR _TipsSection & _AnalyzeButton UNCHANGED
// ————————————————————————

/// A private widget to display scanning tips.
class _TipsSection extends StatelessWidget {
  const _TipsSection();

  static const List<Map<String, dynamic>> _tips = [
    {'icon': Icons.camera_enhance_rounded, 'title': 'Keep Camera Steady'},
    {'icon': Icons.wb_sunny_rounded, 'title': 'Good Lighting'},
    {'icon': Icons.center_focus_strong_rounded, 'title': 'Focus on Affected Area'},
    {'icon': Icons.crop_original_rounded, 'title': 'Capture Full Leaf'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(AppMeasurements.smallPadding * 0.8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.08),
            Theme.of(context).colorScheme.secondary.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: AppMeasurements.getResponsiveSmallPadding(context) * 0.8),
          ..._tips.map((tip) => Padding(
            padding: EdgeInsets.only(
              bottom: AppMeasurements.getResponsiveExtraSmallPadding(context) * 0.8,
            ),
            child: _buildTipItem(
              context,
              icon: tip['icon'] as IconData,
              title: tip['title'] as String,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.tips_and_updates_rounded,
            size: AppMeasurements.getResponsiveIconSizeSmall(context) * 0.9,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scanning Tips',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                ),
              ),
              Text(
                'For accurate results',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(BuildContext context, {required IconData icon, required String title}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 12),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Analyze Button
class _AnalyzeButton extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onProcess;

  const _AnalyzeButton({required this.isProcessing, required this.onProcess});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = isProcessing
        ? [
      theme.colorScheme.primary.withOpacity(0.6),
      theme.colorScheme.secondary.withOpacity(0.6),
    ]
        : [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
        onTap: isProcessing ? null : onProcess,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: AppMeasurements.smallPadding,
            horizontal: AppMeasurements.getResponsivePadding(context),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            boxShadow: isProcessing
                ? []
                : [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isProcessing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  Icons.auto_fix_high_rounded,
                  size: AppMeasurements.getResponsiveIconSizeSmall(context),
                  color: theme.colorScheme.onPrimary,
                ),
              const SizedBox(width: 12),
              Text(
                isProcessing ? 'Analyzing...' : 'Analyze Leaf',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}