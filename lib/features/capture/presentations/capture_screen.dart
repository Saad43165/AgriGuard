import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/ai_analysis_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_themes.dart';
import '../../../core/services/disease_id_service.dart';
import '../../../core/services/plant_id_service.dart';
import '../../advance_search_screen/advanced_search_screen.dart';
import '../../auth/Login_Screen/services/guest_service.dart';
import 'components/processing_overlay.dart';

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

  // State
  XFile? _imageFile;
  bool _isProcessing = false;
  String? _selectedMethod;
  _ScanMode _scanMode = _ScanMode.onDevice;
  FlashMode _flashMode = FlashMode.off;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
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
      await _startCamera(_isFrontCamera ? 1 : 0);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _startCamera(int index) async {
    if (_cameras.isEmpty || index >= _cameras.length) return;
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _cameraController?.dispose();
          _cameraController = controller;
          _cameraReady = true;
        });
      }
    } catch (e) {
      debugPrint('Camera start error: $e');
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    HapticFeedback.lightImpact();
    setState(() { _cameraReady = false; _isFrontCamera = !_isFrontCamera; });
    await _startCamera(_isFrontCamera ? 1 : 0);
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraReady) return;
    HapticFeedback.selectionClick();
    final next = _flashMode == FlashMode.off
        ? FlashMode.torch
        : FlashMode.off;
    try {
      await _cameraController!.setFlashMode(next);
      setState(() => _flashMode = next);
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraReady) return;
    if (_guestService.isGuestMode && !_guestService.hasScansRemaining) {
      _showGuestLimitDialog(); return;
    }
    try {
      HapticFeedback.mediumImpact();
      final photo = await _cameraController!.takePicture();
      if (mounted) {
        setState(() => _imageFile = photo);
        // Immediately start scan with selected mode — no second asking
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
        // Immediately start scan with selected mode
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard : Colors.white,
        title: const Row(children: [
          Icon(Icons.photo_camera_rounded, color: AppColors.warning, size: 22),
          SizedBox(width: 10),
          Text('Better Photo Needed', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Confidence is ${confidence.toStringAsFixed(0)}% — too low for a reliable result.',
              style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('📸 Tips for better results:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text('• Fill frame with a single leaf', style: TextStyle(fontSize: 12)),
              Text('• Use good natural lighting', style: TextStyle(fontSize: 12)),
              Text('• Keep image sharp and in focus', style: TextStyle(fontSize: 12)),
              Text('• Avoid shadows on the leaf', style: TextStyle(fontSize: 12)),
            ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Try Again', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        title: Row(children: [
          const Icon(Icons.help_outline_rounded, color: AppColors.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(
            "I'm ${confidence.toStringAsFixed(0)}% sure",
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Which one looks correct?',
              style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkCaption : AppColors.lightCaption)),
          const SizedBox(height: 12),
          ...top3.asMap().entries.map((entry) {
            final pred = entry.value as Map;
            final pConf = double.tryParse(pred['confidence']?.toString() ?? '0') ?? 0.0;
            final pPlant = pred['plantName']?.toString() ?? '';
            final pDisease = pred['diseaseName']?.toString() ?? '';
            return GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                // Build scan data with selected prediction
                final overridden = Map<String, dynamic>.from(result);
                overridden['plantName'] = pPlant;
                overridden['diseaseName'] = pDisease;
                overridden['confidence'] = pConf.toStringAsFixed(1);
                overridden['isHealthy'] = pred['isHealthy'] ?? false;
                overridden['rawLabel'] = pred['label'] ?? '';
                final scanData = _buildScanData(overridden, user);
                Navigator.pushNamed(context, AppRoutes.results, arguments: {'scanData': scanData});
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBg : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(pPlant, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    Text(pDisease, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E))),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20)),
                    child: Text('${pConf.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary))),
                ]),
              ),
            );
          }),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.camera_alt_rounded, size: 16),
            label: const Text('Retake Photo'),
            style: TextButton.styleFrom(foregroundColor: AppColors.lightCaption),
          ),
        ]),
      ),
    );
  }

  void _showGuestLimitDialog() {
    final t = Provider.of<TranslationService>(context, listen: false);
    showDialog(context: context, builder: (ctx) => AppDialog(
      icon: Icon(Icons.block_rounded, color: Theme.of(ctx).colorScheme.error),
      title: t.get('limit_reached'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(t.get('limit_message')),
        const SizedBox(height: 8),
        Text(t.get('limit_benefit')),
      ]),
      actions: [
        AppDialogActions.secondary(ctx, label: t.get('cancel'), onPressed: () => Navigator.pop(ctx)),
        AppDialogActions.primary(ctx, label: t.get('sign_in_now'), icon: Icons.login_rounded,
            onPressed: () => Navigator.pushNamedAndRemoveUntil(ctx, AppRoutes.login, (_) => false)),
      ],
    ));
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _plantService.dispose();
    _diseaseService.dispose();
    _pulseController.dispose();
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
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        _cameraReady && _cameraController != null
            ? CameraPreview(_cameraController!)
            : Container(color: Colors.black,
                child: const Center(child: CircularProgressIndicator(color: AppColors.primary))),

        // Corner brackets overlay
        Center(
          child: SizedBox(
            width: 260, height: 260,
            child: CustomPaint(painter: _BracketsPainter()),
          ),
        ),

        // Hint text
        const Positioned(
          bottom: 220,
          left: 0, right: 0,
          child: Text('Point at a plant leaf',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
        ),

        // Plant hint banner — shown when scanning from species grid
        if (widget.plantHint != null)
          Positioned(
            bottom: 245,
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
                  Text('Scanning as ${widget.plantHint}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),

        // Top bar: close + flash + flip
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
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _flashMode == FlashMode.torch
                          ? Colors.yellow.withValues(alpha: 0.8)
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
                _overlayBtn(Icons.flip_camera_ios_rounded, _cameras.length > 1 ? _flipCamera : null),
              ],
            ),
          ),
        ),

        // Bottom controls
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 20),
            decoration: const BoxDecoration(
              color: Colors.black54,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scan mode selector — swipeable tabs
                _buildModeSelector(),
                const SizedBox(height: 20),

                // Camera controls row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery
                    GestureDetector(
                      onTap: _pickFromGallery,
                      child: Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 24),
                      ),
                    ),

                    // Shutter button
                    GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),

                    // Spacer (balanced layout)
                    const SizedBox(width: 52),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Scan mode selector ────────────────────────────────────────────────────
  Widget _buildModeSelector() {
    final modes = [
      (_ScanMode.onDevice, '⚡ Quick Scan', 'Offline · Fast'),
      (_ScanMode.advancedAI, '🤖 Advanced AI', 'Cloud · Detailed'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: modes.map((m) {
        final isSelected = _scanMode == m.$1;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _scanMode = m.$1);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.white30,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m.$2, style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                )),
                Text(m.$3, style: TextStyle(
                  color: Colors.white.withValues(alpha: isSelected ? 0.9 : 0.6),
                  fontSize: 10,
                )),
              ],
            ),
          ),
        );
      }).toList(),
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

// ── Corner brackets painter ───────────────────────────────────────────────────
class _BracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const len = 30.0;
    // Top-left
    canvas.drawLine(Offset.zero, const Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, len), paint);
    // Top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}







