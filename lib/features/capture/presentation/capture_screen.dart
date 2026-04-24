import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_fyp/core/constants/app_routes.dart';
import 'package:agriguard_fyp/core/services/ai_analysis_service.dart';
import 'package:agriguard_fyp/core/services/translation_service.dart';
import 'package:agriguard_fyp/core/widgets/app_dialog.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';
import 'package:agriguard_fyp/core/services/disease_id_service.dart';
import 'package:agriguard_fyp/core/services/plant_id_service.dart';
import '../../advance_search_screen/advanced_search_screen.dart';
import '../../auth/login/services/guest_service.dart';
import 'components/processing_overlay.dart';
import 'widgets/animated_shutter_button.dart';
import 'widgets/brackets_painter.dart';
import 'widgets/capture_dialogs.dart';

// Scan mode: 0 = On-Device (offline), 1 = Advanced AI (cloud)
enum _ScanMode { onDevice, advancedAI }

class CaptureScreen extends StatefulWidget {
  final bool startOnDevice;
  final bool startAdvanced;
  final XFile? prePickedImage;
  final String? plantHint; // pre-selected plant name from species grid

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
  // Camera
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _cameraReady = false;
  bool _isFrontCamera = false;
  int _currentCameraIndex = 0;

  // Zoom
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _baseZoom = 1.0; // zoom at start of pinch

  // Focus
  Offset? _focusPoint;
  bool _showFocusCircle = false;

  // State
  XFile? _imageFile;
  bool _isProcessing = false;
  String? _selectedMethod;
  _ScanMode _scanMode = _ScanMode.onDevice;
  FlashMode _flashMode = FlashMode.off;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _focusAnimCtrl;
  late Animation<double> _focusAnim;
  late PageController _modePageController;

  // Services
  final PlantIdService _plantService = PlantIdService();
  final DiseaseIdService _diseaseService = DiseaseIdService();
  late final PlantAnalysisService _analysisService;
  final GuestService _guestService = GuestService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this)
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _focusAnimCtrl = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _focusAnim = Tween<double>(begin: 1.3, end: 1.0).animate(
        CurvedAnimation(parent: _focusAnimCtrl, curve: Curves.easeOut));

    _modePageController = PageController(initialPage: 0, viewportFraction: 0.4);

    _analysisService = PlantAnalysisService(
      speciesService: _plantService,
      diseaseService: _diseaseService,
    );

    _initAll();

    if (widget.prePickedImage != null) {
      _imageFile = widget.prePickedImage;
    }
    if (widget.startAdvanced) _scanMode = _ScanMode.advancedAI;
  }

  Future<void> _initAll() async {
    await _guestService.initialize();
    await _initCamera();
    try {
      await Future.wait([_plantService.loadModel(), _diseaseService.loadModel()]);
    } catch (e) {
      debugPrint('Model load error: $e');
    }
    if (mounted) setState(() {});
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      _currentCameraIndex = 0;
      _isFrontCamera = false;
      await _startCamera(_currentCameraIndex);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _startCamera(int index) async {
    if (_cameras.isEmpty || index >= _cameras.length) return;

    // Dispose old controller first
    final oldController = _cameraController;
    if (mounted) setState(() { _cameraReady = false; _cameraController = null; });
    await oldController?.dispose();

    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await controller.initialize();
      // Get zoom range
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      if (mounted) {
        setState(() {
          _cameraController = controller;
          _cameraReady = true;
          _minZoom = minZoom;
          _maxZoom = maxZoom;
          _currentZoom = 1.0;
        });
      }
    } catch (e) {
      debugPrint('Camera start error: $e');
      await controller.dispose();
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _isProcessing) return;
    HapticFeedback.lightImpact();
    _isFrontCamera = !_isFrontCamera;
    _currentCameraIndex = _isFrontCamera ? 1 : 0;
    // Clamp to available cameras
    if (_currentCameraIndex >= _cameras.length) {
      _currentCameraIndex = 0;
      _isFrontCamera = false;
    }
    await _startCamera(_currentCameraIndex);
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraReady) return;
    HapticFeedback.selectionClick();
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await _cameraController!.setFlashMode(next);
      if (mounted) setState(() => _flashMode = next);
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  Future<void> _handleTapToFocus(TapDownDetails details, BoxConstraints constraints) async {
    if (_cameraController == null || !_cameraReady) return;
    final x = details.localPosition.dx / constraints.maxWidth;
    final y = details.localPosition.dy / constraints.maxHeight;
    final offset = Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
    try {
      await _cameraController!.setFocusPoint(offset);
      await _cameraController!.setExposurePoint(offset);
      if (mounted) {
        setState(() {
          _focusPoint = details.localPosition;
          _showFocusCircle = true;
        });
        _focusAnimCtrl.forward(from: 0);
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) setState(() => _showFocusCircle = false);
      }
    } catch (e) {
      debugPrint('Focus error: $e');
    }
  }

  void _handlePinchZoom(ScaleUpdateDetails details) {
    if (_cameraController == null || !_cameraReady) return;
    final newZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
    _cameraController!.setZoomLevel(newZoom).catchError((_) {});
    if (mounted) setState(() => _currentZoom = newZoom);
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraReady || _isProcessing) return;
    if (_guestService.isGuestMode && !_guestService.hasScansRemaining) {
      _showGuestLimitDialog(); return;
    }
    try {
      HapticFeedback.mediumImpact();
      final photo = await _cameraController!.takePicture();
      if (mounted) {
        setState(() => _imageFile = photo);
        await _startScan();
      }
    } catch (e) {
      debugPrint('Take picture error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    if (_guestService.isGuestMode && !_guestService.hasScansRemaining) {
      _showGuestLimitDialog(); return;
    }
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200, maxHeight: 1200, imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _imageFile = picked);
        await _startScan();
      }
    } catch (e) {
      debugPrint('Gallery error: $e');
    }
  }

  Future<void> _startScan() async {
    if (_imageFile == null) return;
    final method = _scanMode == _ScanMode.advancedAI ? 'api' : 'tflite';
    setState(() { _selectedMethod = method; _isProcessing = true; });

    if (method == 'api') {
      setState(() => _isProcessing = false);
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => AdvancedSearchScreen(
          originalScanData: {
            'imagePath': _imageFile!.path,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ),
      ));
      _reset();
      return;
    }

    try {
      final t = Provider.of<TranslationService>(context, listen: false);
      User? user;
      if (!_guestService.isGuestMode) {
        user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception(t.get('error_sign_in'));
      }
      final imageFile = File(_imageFile!.path);
      if (!await imageFile.exists()) throw Exception(t.get('error_file_not_found'));
      final result = await _analysisService.analyzePlant(imageFile, plantHint: widget.plantHint);
      if (!mounted) return;

      // ── 3-tier confidence handling ─────────────────────────────────────────
      final tier = result['confidenceTier'] as String? ?? 'high';
      final confidence = double.tryParse(result['confidence']?.toString() ?? '0') ?? 0.0;

      if (tier == 'low') {
        // < 70% — ask user to retake
        setState(() => _isProcessing = false);
        _showRetakeDialog(confidence);
        _reset();
        return;
      }

      if (tier == 'medium') {
        // 70-85% — show top 3 options
        setState(() => _isProcessing = false);
        final top3 = result['top3Predictions'] as List? ?? [];
        if (top3.isNotEmpty && mounted) {
          await _showTop3Dialog(top3, result, user);
        } else {
          // fallback — show result anyway
          final scanData = _buildScanData(result, user);
          await Navigator.pushNamed(context, AppRoutes.results, arguments: {'scanData': scanData});
        }
        _reset();
        return;
      }

      // HIGH confidence (≥85%) — show result directly
      if (_guestService.isGuestMode) {
        final ok = await _guestService.incrementScanCount();
        if (!ok) { _showGuestLimitDialog(); setState(() => _isProcessing = false); return; }
      }
      final scanData = _buildScanData(result, user);
      await Navigator.pushNamed(context, AppRoutes.results, arguments: {'scanData': scanData});
      _reset();
    } catch (e) {
      debugPrint('Scan error: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Scan failed. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      // Always reset processing state even if something unexpected happens
      if (mounted && _isProcessing) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Map<String, dynamic> _buildScanData(Map<String, dynamic> analysis, User? user) {
    final plantName = analysis['plantName']?.toString() ?? 'Unknown Plant';
    final diseaseName = analysis['diseaseName']?.toString() ?? 'Healthy';
    final isHealthy = analysis['isHealthy'] as bool? ?? diseaseName.toLowerCase() == 'healthy';
    final confidence = (analysis['confidence'] ?? 0.0);
    final remediation = analysis['remediation'];
    final remediationList = remediation is List ? List<String>.from(remediation) : <String>[];
    final shouldSave = _guestService.isGuestMode ? false : (analysis['shouldSaveToHistory'] as bool? ?? true);
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'plantName': plantName, 'diseaseName': diseaseName,
      'diagnosis': isHealthy ? '✅ Healthy $plantName' : '⚠️ $diseaseName on $plantName',
      'confidence': confidence is num ? confidence.toStringAsFixed(1) : confidence.toString(),
      'severity': analysis['severity']?.toString() ?? (isHealthy ? 'None' : 'Unknown'),
      'remediation': remediationList,
      'treatment': remediationList.isNotEmpty ? '• ${remediationList.join('\n• ')}' : '',
      'symptoms': analysis['symptoms'] ?? <String>[],
      'precautions': analysis['precautions'] ?? <String>[],
      'imagePath': _imageFile!.path,
      'timestamp': DateTime.now().toIso8601String(),
      'userId': user?.uid ?? 'guest',
      'fromCapture': true,
      'previousRoute': AppRoutes.scan,
      'isUnknown': analysis['isUnknown'] as bool? ?? false,
      'isHealthy': isHealthy,
      'isLeaf': analysis['isLeaf'] as bool? ?? true,
      'leafConfidence': analysis['leafConfidence'],
      'leafAnalysis': analysis['_leafAnalysis'] ?? analysis['leafAnalysis'],
      'shouldSaveToHistory': shouldSave,
      'skipSave': !shouldSave,
      'rawLabel': analysis['rawLabel'],
      'isGuestScan': _guestService.isGuestMode,
    };
  }

  void _reset() {
    if (mounted) setState(() { _imageFile = null; _isProcessing = false; _selectedMethod = null; });
  }

  void _showRetakeDialog(double confidence) {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
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
          setState(() => _scanMode = _ScanMode.advancedAI);
        },
      ),
    );
  }



  Future<void> _showTop3Dialog(List top3, Map<String, dynamic> result, User? user) async {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    final confidence = double.tryParse(result['confidence']?.toString() ?? '0') ?? 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) => CaptureTop3Dialog(
        top3: top3,
        confidence: confidence,
        isDark: isDark,
        onRetake: () => Navigator.pop(ctx),
        onSelect: (pred) {
          Navigator.pop(ctx);
          final overridden = Map<String, dynamic>.from(result);
          overridden['plantName'] = pred['plantName']?.toString() ?? '';
          overridden['diseaseName'] = pred['diseaseName']?.toString() ?? '';
          overridden['confidence'] = (double.tryParse(pred['confidence']?.toString() ?? '0') ?? 0.0).toStringAsFixed(1);
          overridden['isHealthy'] = pred['isHealthy'] ?? false;
          overridden['rawLabel'] = pred['label'] ?? '';
          final scanData = _buildScanData(overridden, user);
          Navigator.pushNamed(context, AppRoutes.results, arguments: {'scanData': scanData});
        },
      ),
    );
  }

  void _showGuestLimitDialog() {
    final t = Provider.of<TranslationService>(context, listen: false);
    showDialog(context: context, builder: (ctx) => GuestLimitDialog(t: t));
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _plantService.dispose();
    _diseaseService.dispose();
    _pulseController.dispose();
    _focusAnimCtrl.dispose();
    _modePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isProcessing,
      onPopInvoked: (didPop) {},
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _buildCameraView(),
            if (_isProcessing)
              ProcessingOverlay(
                selectedMethod: _selectedMethod ?? 'tflite',
                isProcessing: _isProcessing,
                isGuestMode: _guestService.isGuestMode,
                remainingScans: _guestService.remainingScans,
                pulseAnimation: _pulseAnimation,
                processingMessage: 'Analyzing...',
                imagePath: _imageFile?.path,
                modelStatuses: {
                  'Plant ID': _plantService.isLoaded,
                  'Disease': _diseaseService.isLoaded,
                },
                onCancel: () { if (mounted) setState(() { _isProcessing = false; _imageFile = null; }); },
              ),
          ],
        ),
      ),
    );
  }

  // ── Live camera viewfinder ────────────────────────────────────────────────
  Widget _buildCameraView() {
    final t = Provider.of<TranslationService>(context, listen: false);
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Camera preview with tap-to-focus + pinch-to-zoom ──────────────
        if (_cameraReady && _cameraController != null)
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = 1 / (_cameraController!.value.aspectRatio * MediaQuery.of(context).size.aspectRatio);
              return Transform.scale(
                scale: scale < 1 ? 1 / scale : scale,
                child: Center(
                  child: GestureDetector(
                    onTapDown: (d) => _handleTapToFocus(d, constraints),
                    onScaleStart: (_) => _baseZoom = _currentZoom,
                    onScaleUpdate: _handlePinchZoom,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              );
            },
          )
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
            ),
          ),

        // ── Focus circle ──────────────────────────────────────────────────
        if (_showFocusCircle && _focusPoint != null)
          Positioned(
            left: _focusPoint!.dx - 30,
            top: _focusPoint!.dy - 30,
            child: AnimatedBuilder(
              animation: _focusAnim,
              builder: (_, __) => Transform.scale(
                scale: _focusAnim.value,
                child: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.yellow, width: 1.5),
                  ),
                ),
              ),
            ),
          ),

        // ── Corner brackets overlay ───────────────────────────────────────
        Center(
          child: SizedBox(
            width: 240, height: 240,
            child: CustomPaint(painter: BracketsPainter()),
          ),
        ),

        // ── Hint text ─────────────────────────────────────────────────────
        Positioned(
          bottom: 230,
          left: 0, right: 0,
          child: Text(
            t.isUrdu ? 'پودے کے پتے پر نشانہ لگائیں' : 'Point at a plant leaf',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ),

        // ── Zoom indicator ────────────────────────────────────────────────
        if (_currentZoom > 1.05)
          Positioned(
            bottom: 210,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentZoom.toStringAsFixed(1)}×',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),

        // ── Plant hint banner ─────────────────────────────────────────────
        if (widget.plantHint != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.eco_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    t.isUrdu ? '${widget.plantHint} کے طور پر اسکین' : 'Scanning as ${widget.plantHint}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ]),
              ),
            ),
          ),

        // ── Top bar: close + flash + flip ─────────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 0, right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _overlayBtn(Icons.close_rounded, () => Navigator.of(context).pop()),
                // Flash button
                GestureDetector(
                  onTap: _toggleFlash,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _flashMode == FlashMode.torch
                          ? Colors.yellow.withValues(alpha: 0.9)
                          : Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _flashMode == FlashMode.torch
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      color: _flashMode == FlashMode.torch ? Colors.black : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                // Flip camera — only show if multiple cameras available
                _cameras.length > 1
                    ? GestureDetector(
                        onTap: _flipCamera,
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 20),
                        ),
                      )
                    : const SizedBox(width: 40),
              ],
            ),
          ),
        ),

        // ── Bottom controls ───────────────────────────────────────────────
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scan mode selector
                _buildModeSelector(),
                const SizedBox(height: 24),

                // Camera controls row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Gallery
                    GestureDetector(
                      onTap: _pickFromGallery,
                      child: Container(
                        width: 54, height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 24),
                      ),
                    ),

                    // Shutter button — animated press
                    AnimatedShutterButton(onTap: _takePicture),

                    // Zoom reset button — shows when zoomed in
                    GestureDetector(
                      onTap: _currentZoom > 1.05 ? () {
                        _cameraController?.setZoomLevel(1.0).catchError((_) {});
                        setState(() => _currentZoom = 1.0);
                      } : null,
                      child: AnimatedOpacity(
                        opacity: _currentZoom > 1.05 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          width: 54, height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: const Icon(Icons.zoom_out_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ],
);
  }

  // ── Scan mode selector ────────────────────────────────────────────────────
  Widget _buildModeSelector() {
    final modes = [
      (_ScanMode.onDevice, 'Fast Scan', Icons.bolt_rounded),
      (_ScanMode.advancedAI, 'Deep AI', Icons.auto_awesome_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modes.map((m) {
          final isSelected = _scanMode == m.$1;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _scanMode = m.$1);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(26),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ] : [],
              ),
              child: Row(
                children: [
                  Icon(m.$3, color: isSelected ? Colors.white : Colors.white60, size: 16),
                  const SizedBox(width: 6),
                  Text(m.$2, style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _overlayBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}







