import 'package:agriguard_fyp/features/capture/presentation/widgets/capture_controller.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/translation_service.dart';
import '../../advance_search_screen/advanced_search_screen.dart';
import 'widgets/capture_bottom_controls.dart';
import 'widgets/capture_camera_overlay.dart';
import 'widgets/capture_dialogs.dart';
import 'widgets/processing_overlay.dart';

class CaptureScreen extends StatefulWidget {
  final bool startOnDevice;
  final bool startAdvanced;
  final XFile? prePickedImage;
  final String? plantHint;

  const CaptureScreen({
    super.key,
    this.startOnDevice = false,
    this.startAdvanced = false,
    this.prePickedImage,
    this.plantHint,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with TickerProviderStateMixin {
  late final CaptureController c;

  @override
  void initState() {
    super.initState();

    c = CaptureController(
      vsync: this,
      startAdvanced: widget.startAdvanced,
      prePickedImage: widget.prePickedImage,
      plantHint: widget.plantHint,
      context: context,
      onOpenAdvanced: (imagePath) async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdvancedSearchScreen(
              originalScanData: {
                'imagePath': imagePath,
                'timestamp': DateTime.now().toIso8601String(),
              },
            ),
          ),
        );
      },
      onShowGuestLimitDialog: () {
        final t = Provider.of<TranslationService>(context, listen: false);
        showDialog(context: context, builder: (ctx) => GuestLimitDialog(t: t));
      },
      onShowRetakeDialog: (confidence, onAdvanced) {
        final t = Provider.of<TranslationService>(context, listen: false);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        showDialog(
          context: context,
          builder: (ctx) => CaptureRetakeDialog(
            confidence: confidence,
            t: t,
            isDark: isDark,
            onRetry: () => Navigator.pop(ctx),
            onAdvanced: () {
              Navigator.pop(ctx);
              onAdvanced();
            },
          ),
        );
      },
      onShowTop3Dialog: (top3, confidence, onSelect, onRetake) async {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        await showDialog(
          context: context,
          builder: (ctx) => CaptureTop3Dialog(
            top3: top3,
            confidence: confidence,
            isDark: isDark,
            onRetake: () {
              Navigator.pop(ctx);
              onRetake();
            },
            onSelect: (pred) {
              Navigator.pop(ctx);
              onSelect(Map<String, dynamic>.from(pred));
            },
          ),
        );
      },
    );

    c.init();
  }

  @override
  void dispose() {
    c.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<TranslationService>(context, listen: false);

    return AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        return PopScope(
          canPop: !c.isProcessing,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                CaptureCameraOverlay(
                  cameraReady: c.cameraReady,
                  controller: c.cameraController,
                  currentZoom: c.currentZoom,
                  showFocusCircle: c.showFocusCircle,
                  focusPoint: c.focusPoint,
                  focusAnimation: c.focusAnimation,
                  plantHint: widget.plantHint,
                  flashMode: c.flashMode,
                  hasMultipleCameras: c.hasMultipleCameras,
                  onTapToFocus: c.handleTapToFocus,
                  onScaleStart: c.handleScaleStart,
                  onScaleUpdate: c.handlePinchZoom,
                  onClose: () => Navigator.of(context).pop(),
                  onToggleFlash: c.toggleFlash,
                  onFlipCamera: c.flipCamera,
                  hintText:
                  t.get('ui_point_at_a_plant_leaf'),
                ),
                CaptureBottomControls(
                  scanModeIndex: c.scanModeIndex,
                  onChangeMode: c.changeScanMode,
                  onPickGallery: c.pickFromGallery,
                  onTakePicture: c.takePicture,
                  showZoomReset: c.currentZoom > 1.05,
                  onZoomReset: c.resetZoom,
                ),
                if (c.isProcessing)
                  ProcessingOverlay(
                    selectedMethod: c.selectedMethod ?? 'tflite',
                    isProcessing: c.isProcessing,
                    isGuestMode: c.isGuestMode,
                    remainingScans: c.remainingScans,
                    pulseAnimation: c.pulseAnimation,
                    processingMessage: 'Analyzing...',
                    imagePath: c.imagePath,
                    modelStatuses: {'Disease': c.isModelLoaded},
                    onCancel: c.cancelProcessing,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}