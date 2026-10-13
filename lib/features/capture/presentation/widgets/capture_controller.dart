import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/analysis/ai_analysis_service.dart';
import '../../../../core/services/disease/disease_id_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../auth/login/services/guest_service.dart';

enum CaptureScanMode { onDevice, advancedAI }

typedef OpenAdvancedCallback = Future<void> Function(String imagePath);
typedef ShowGuestLimitDialogCallback = void Function();
typedef ShowRetakeDialogCallback = void Function(
    double confidence, VoidCallback onAdvanced);
typedef ShowTop3DialogCallback = Future<void> Function(
    List top3,
    double confidence,
    void Function(Map<String, dynamic> pred) onSelect,
    VoidCallback onRetake,
    );

class CaptureController extends ChangeNotifier {
  final TickerProvider vsync;
  final bool startAdvanced;
  final XFile? prePickedImage;
  final String? plantHint;
  final BuildContext context;

  final OpenAdvancedCallback onOpenAdvanced;
  final ShowGuestLimitDialogCallback onShowGuestLimitDialog;
  final ShowRetakeDialogCallback onShowRetakeDialog;
  final ShowTop3DialogCallback onShowTop3Dialog;

  CaptureController({
    required this.vsync,
    required this.startAdvanced,
    required this.prePickedImage,
    required this.plantHint,
    required this.context,
    required this.onOpenAdvanced,
    required this.onShowGuestLimitDialog,
    required this.onShowRetakeDialog,
    required this.onShowTop3Dialog,
  });

  CameraController? cameraController;
  List<CameraDescription> _cameras = [];
  bool cameraReady = false;
  bool _isFrontCamera = false;
  int _currentCameraIndex = 0;

  double currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _baseZoom = 1.0;

  Offset? focusPoint;
  bool showFocusCircle = false;

  XFile? _imageFile;
  bool isProcessing = false;
  String? selectedMethod;
  CaptureScanMode _scanMode = CaptureScanMode.onDevice;
  FlashMode flashMode = FlashMode.off;

  late final AnimationController _pulseController;
  late final Animation<double> pulseAnimation;
  late final AnimationController _focusAnimCtrl;
  late final Animation<double> focusAnimation;

  final DiseaseIdService _diseaseService = DiseaseIdService();
  late final PlantAnalysisService _analysisService;
  final GuestService _guestService = GuestService();

  bool get isGuestMode => _guestService.isGuestMode;
  int get remainingScans => _guestService.remainingScans;
  bool get isModelLoaded => _diseaseService.isLoaded;
  bool get hasMultipleCameras => _cameras.length > 1;
  int get scanModeIndex => _scanMode == CaptureScanMode.onDevice ? 0 : 1;
  String? get imagePath => _imageFile?.path;

  Future<void> init() async {
    _pulseController =
    AnimationController(duration: const Duration(milliseconds: 1500), vsync: vsync)
      ..repeat(reverse: true);
    pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _focusAnimCtrl =
        AnimationController(duration: const Duration(milliseconds: 400), vsync: vsync);
    focusAnimation = Tween<double>(begin: 1.3, end: 1.0).animate(
      CurvedAnimation(parent: _focusAnimCtrl, curve: Curves.easeOut),
    );

    _analysisService = PlantAnalysisService(diseaseService: _diseaseService);

    if (prePickedImage != null) _imageFile = prePickedImage;
    if (startAdvanced) _scanMode = CaptureScanMode.advancedAI;

    await _guestService.initialize();
    await _initCamera();
    try {
      await _diseaseService.loadModel();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      _currentCameraIndex = 0;
      _isFrontCamera = false;
      await _startCamera(_currentCameraIndex);
    } catch (_) {}
  }

  Future<void> _startCamera(int index) async {
    if (_cameras.isEmpty || index >= _cameras.length) return;

    final oldController = cameraController;
    cameraReady = false;
    cameraController = null;
    notifyListeners();
    await oldController?.dispose();

    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();

      cameraController = controller;
      cameraReady = true;
      currentZoom = 1.0;
      notifyListeners();
    } catch (_) {
      await controller.dispose();
    }
  }

  Future<void> flipCamera() async {
    if (_cameras.length < 2 || isProcessing) return;
    HapticFeedback.lightImpact();

    _isFrontCamera = !_isFrontCamera;
    _currentCameraIndex = _isFrontCamera ? 1 : 0;
    if (_currentCameraIndex >= _cameras.length) {
      _currentCameraIndex = 0;
      _isFrontCamera = false;
    }

    await _startCamera(_currentCameraIndex);
  }

  Future<void> toggleFlash() async {
    if (cameraController == null || !cameraReady) return;
    HapticFeedback.selectionClick();

    final next = flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await cameraController!.setFlashMode(next);
      flashMode = next;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> handleTapToFocus(TapDownDetails details, BoxConstraints constraints) async {
    if (cameraController == null || !cameraReady) return;

    final x = details.localPosition.dx / constraints.maxWidth;
    final y = details.localPosition.dy / constraints.maxHeight;
    final offset = Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));

    try {
      await cameraController!.setFocusPoint(offset);
      await cameraController!.setExposurePoint(offset);

      focusPoint = details.localPosition;
      showFocusCircle = true;
      notifyListeners();

      _focusAnimCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 1500));
      showFocusCircle = false;
      notifyListeners();
    } catch (_) {}
  }

  void handleScaleStart() {
    _baseZoom = currentZoom;
  }

  void handlePinchZoom(ScaleUpdateDetails details) {
    if (cameraController == null || !cameraReady) return;
    final newZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
    cameraController!.setZoomLevel(newZoom).catchError((_) {});
    currentZoom = newZoom;
    notifyListeners();
  }

  void resetZoom() {
    cameraController?.setZoomLevel(1.0).catchError((_) {});
    currentZoom = 1.0;
    notifyListeners();
  }

  void changeScanMode(int index) {
    _scanMode = index == 0 ? CaptureScanMode.onDevice : CaptureScanMode.advancedAI;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  Future<void> takePicture() async {
    if (cameraController == null || !cameraReady || isProcessing) return;
    if (_guestService.isGuestMode && !_guestService.hasScansRemaining) {
      onShowGuestLimitDialog();
      return;
    }

    try {
      HapticFeedback.mediumImpact();
      final photo = await cameraController!.takePicture();
      _imageFile = photo;
      notifyListeners();
      await _startScan();
    } catch (_) {}
  }

  Future<void> pickFromGallery() async {
    if (_guestService.isGuestMode && !_guestService.hasScansRemaining) {
      onShowGuestLimitDialog();
      return;
    }

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        _imageFile = picked;
        notifyListeners();
        await _startScan();
      }
    } catch (_) {}
  }

  Future<void> _startScan() async {
    if (_imageFile == null) return;

    final method = _scanMode == CaptureScanMode.advancedAI ? 'api' : 'tflite';
    selectedMethod = method;
    isProcessing = true;
    notifyListeners();

    if (method == 'api') {
      isProcessing = false;
      notifyListeners();
      await onOpenAdvanced(_imageFile!.path);
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

      final result = await _analysisService.analyzePlant(imageFile, plantHint: plantHint);
      final tier = result['confidenceTier'] as String? ?? 'high';
      final confidence = double.tryParse(result['confidence']?.toString() ?? '0') ?? 0.0;

      if (tier == 'low' || tier == 'medium') {
        isProcessing = false;
        notifyListeners();
        final top3 = result['top3Predictions'] as List? ?? [];
        if (top3.isNotEmpty) {
          await onShowTop3Dialog(
            top3,
            confidence,
                (pred) => _pushResultWithPrediction(result, pred, user),
                () {},
          );
        } else {
          final scanData = _buildScanData(result, user);
          if (!context.mounted) return;
          await Navigator.pushNamed(context, AppRoutes.results, arguments: {'scanData': scanData});
        }
        _reset();
        return;
      }

      if (_guestService.isGuestMode) {
        final ok = await _guestService.incrementScanCount();
        if (!ok) {
          onShowGuestLimitDialog();
          isProcessing = false;
          notifyListeners();
          return;
        }
      }

      final scanData = _buildScanData(result, user);
      if (!context.mounted) return;
      await Navigator.pushNamed(context, AppRoutes.results, arguments: {'scanData': scanData});
      _reset();
    } catch (_) {
      isProcessing = false;
      notifyListeners();
    } finally {
      if (isProcessing) {
        isProcessing = false;
        notifyListeners();
      }
    }
  }

  Future<void> _pushResultWithPrediction(
      Map<String, dynamic> result,
      Map<String, dynamic> pred,
      User? user,
      ) async {
    final overridden = Map<String, dynamic>.from(result);
    overridden['plantName'] = pred['plantName']?.toString() ?? '';
    overridden['diseaseName'] = pred['diseaseName']?.toString() ?? '';
    overridden['confidence'] =
        (double.tryParse(pred['confidence']?.toString() ?? '0') ?? 0.0).toStringAsFixed(1);
    overridden['isHealthy'] = pred['isHealthy'] ?? false;
    overridden['rawLabel'] = pred['label'] ?? '';
    final scanData = _buildScanData(overridden, user);
    await Navigator.pushNamed(context, AppRoutes.results, arguments: {'scanData': scanData});
  }

  Map<String, dynamic> _buildScanData(Map<String, dynamic> analysis, User? user) {
    final plantName = analysis['plantName']?.toString() ?? 'Unknown Plant';
    final diseaseName = analysis['diseaseName']?.toString() ?? 'Healthy';
    final isHealthy = analysis['isHealthy'] as bool? ?? diseaseName.toLowerCase() == 'healthy';
    final confidence = analysis['confidence'] ?? 0.0;
    final remediation = analysis['remediation'];
    final remediationList = remediation is List ? List<String>.from(remediation) : <String>[];
    final shouldSave = _guestService.isGuestMode
        ? false
        : (analysis['shouldSaveToHistory'] as bool? ?? true);

    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'plantName': plantName,
      'diseaseName': diseaseName,
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

  void cancelProcessing() {
    isProcessing = false;
    _imageFile = null;
    notifyListeners();
  }

  void _reset() {
    _imageFile = null;
    isProcessing = false;
    selectedMethod = null;
    notifyListeners();
  }

  void disposeController() {
    cameraController?.dispose();
    _diseaseService.dispose();
    _pulseController.dispose();
    _focusAnimCtrl.dispose();
    dispose();
  }
}