import 'dart:io';
import 'dart:typed_data';
import 'package:agriguard_fyp/features/edit/presentation/widgets/highlitghts_panel.dart';
import 'package:agriguard_fyp/features/edit/presentation/widgets/sticker_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;
import '../../../../core/constants/animation_mixin.dart';
import '../../../../core/constants/app_constants.dart';
import '../../home/presentation/screens/components/scan_service.dart';
import 'models/editing_history.dart';
import 'models/drawing_point.dart';
import 'models/text_annotation.dart';
import 'utils/constants.dart';
import 'utils/image_processor.dart';
import 'widgets/adjust_panel.dart';
import 'widgets/crop_panel.dart';
import 'widgets/draw_panel.dart';
import 'widgets/effects_panel.dart';
import 'widgets/text_panel.dart';
import 'widgets/tool_selector.dart';

class ImageEditScreen extends StatefulWidget {
  final String imagePath;

  const ImageEditScreen({super.key, required this.imagePath});

  @override
  State<ImageEditScreen> createState() => _ImageEditScreenState();
}

class _ImageEditScreenState extends State<ImageEditScreen> with TickerProviderStateMixin, ScreenAnimationMixin {
  final ImageProcessor _imageProcessor = ImageProcessor();
  late AnimationController _toolSwitchController;
  late Animation<double> _toolSwitchAnimation;

  // State variables
  Uint8List? _encodedImage;
  bool _isLoading = true;
  bool _isProcessing = false;
  EditingTool _currentTool = EditingTool.adjust;
  final List<EditingHistory> _history = [];
  int _currentHistoryIndex = -1;
  final GlobalKey _imageKey = GlobalKey();
  Matrix4 _matrix = Matrix4.identity();
  Rect? _cropRect;
  bool _isCropping = false;
  Offset? _cropStart;
  Offset? _cropEnd;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    initializeAnimations();
    _initializeToolSwitchAnimation();
    _loadImage();
  }

  void _initializeToolSwitchAnimation() {
    _toolSwitchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toolSwitchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _toolSwitchController, curve: Curves.elasticOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _toolSwitchController.forward();
    });
  }

  @override
  void dispose() {
    _toolSwitchController.dispose();
    disposeAnimations();
    super.dispose();
  }

  Future<void> _loadImage() async {
    setState(() => _isLoading = true);
    try {
      await _imageProcessor.loadImage(widget.imagePath);
      setState(() {
        _encodedImage = _imageProcessor.encodedImage;
        _isLoading = false;
      });
      _addToHistory('Original Image');
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error loading image: $e');
        Navigator.pop(context);
      }
    }
  }

  void _addToHistory(String action) {
    if (_imageProcessor.editedImage == null) return;
    _history.add(EditingHistory(
      image: _imageProcessor.editedImage!,
      action: action,
      timestamp: DateTime.now(),
    ));
    if (_history.length > Constants.maxHistorySize) {
      _history.removeAt(0);
      _currentHistoryIndex--;
    }
    _currentHistoryIndex = _history.length - 1;
  }

  void _undo() {
    if (_currentHistoryIndex <= 0) return;
    _currentHistoryIndex--;
    _imageProcessor.setEditedImage(_history[_currentHistoryIndex].image);
    setState(() => _encodedImage = _imageProcessor.encodedImage);
    HapticFeedback.mediumImpact();
  }

  void _redo() {
    if (_currentHistoryIndex >= _history.length - 1) return;
    _currentHistoryIndex++;
    _imageProcessor.setEditedImage(_history[_currentHistoryIndex].image);
    setState(() => _encodedImage = _imageProcessor.encodedImage);
    HapticFeedback.mediumImpact();
  }

  Future<void> _saveAndNavigateToResults() async {
    if (_encodedImage == null) return;
    setState(() => _isProcessing = true);
    try {
      final scanResult = await _imageProcessor.saveImage();
      await ScanService().saveScan(scanResult);
      if (mounted) {
        Navigator.pushNamed(context, AppRoutes.results, arguments: {
          'imagePath': scanResult['imageUrl'],
          'scanData': scanResult,
        }).then((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Error saving image: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onError,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _switchTool(EditingTool tool) {
    setState(() => _currentTool = tool);
    _toolSwitchController.reset();
    _toolSwitchController.forward();
    HapticFeedback.selectionClick();
  }

  void _handleImageTapDown(TapDownDetails details) {
    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;
    final normalized = Offset(
      (localPosition.dx / size.width).clamp(0.0, 1.0),
      (localPosition.dy / size.height).clamp(0.0, 1.0),
    );

    if (_currentTool == EditingTool.crop && _isCropping) {
      setState(() {
        _cropStart = localPosition;
        _cropEnd = localPosition;
        _updateCropRect();
      });
    } else {
      _imageProcessor.handleInteraction(_currentTool, normalized);
      setState(() => _encodedImage = _imageProcessor.encodedImage);
      _addToHistory(_currentTool.toString().split('.').last);
    }
  }

  void _handleImagePanUpdate(DragUpdateDetails details) {
    if (_currentTool != EditingTool.crop || !_isCropping || _cropStart == null) return;
    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    setState(() {
      _cropEnd = renderBox.globalToLocal(details.globalPosition);
      _updateCropRect();
    });
  }

  void _updateCropRect() {
    if (_cropStart == null || _cropEnd == null) return;
    final left = _cropStart!.dx < _cropEnd!.dx ? _cropStart!.dx : _cropEnd!.dx;
    final top = _cropStart!.dy < _cropEnd!.dy ? _cropStart!.dy : _cropEnd!.dy;
    final right = _cropStart!.dx > _cropEnd!.dx ? _cropStart!.dx : _cropEnd!.dx;
    final bottom = _cropStart!.dy > _cropEnd!.dy ? _cropStart!.dy : _cropEnd!.dy;
    final width = right - left;
    final height = bottom - top;
    if (width > 20 && height > 20) {
      _cropRect = Rect.fromLTWH(left, top, width, height);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: _buildBackgroundGradient(),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
          child: applyAnimations(
            LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Expanded(child: _buildImageEditor()),
                    ToolSelector(
                      currentTool: _currentTool,
                      onToolSelected: _switchTool,
                      animation: _toolSwitchAnimation,
                    ),
                    _buildToolPanel(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(AppStrings.editImage, style: Theme.of(context).textTheme.titleLarge),
      actions: [
        IconButton(
          icon: const Icon(Icons.undo_rounded),
          onPressed: _currentHistoryIndex > 0 ? _undo : null,
          tooltip: AppStrings.undo,
        ),
        IconButton(
          icon: const Icon(Icons.redo_rounded),
          onPressed: _currentHistoryIndex < _history.length - 1 ? _redo : null,
          tooltip: AppStrings.redo,
        ),
        IconButton(
          icon: const Icon(Icons.restart_alt_rounded),
          onPressed: () {
            _imageProcessor.resetAdjustments();
            setState(() => _encodedImage = _imageProcessor.encodedImage);
            _addToHistory('Reset All');
          },
          tooltip: AppStrings.reset,
        ),
        IconButton(
          icon: const Icon(Icons.check_rounded),
          onPressed: _isProcessing || _encodedImage == null ? null : _saveAndNavigateToResults,
          tooltip: AppStrings.save,
        ),
      ],
    );
  }

  BoxDecoration _buildBackgroundGradient() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: Theme.of(context).brightness == Brightness.dark
            ? const [Color(0xFF0F0F23), Color(0xFF16213E), Color(0xFF1A1A2E), Color(0xFF0F0F23)]
            : [
          Theme.of(context).colorScheme.background,
          Theme.of(context).colorScheme.background.withOpacity(0.9),
          Theme.of(context).colorScheme.background.withOpacity(0.8),
          Theme.of(context).colorScheme.background,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ),
    );
  }

  Widget _buildImageEditor() {
    if (_encodedImage == null) return const SizedBox.shrink();
    return Stack(
      children: [
        MatrixGestureDetector(
          onMatrixUpdate: (matrix, translationDelta, scaleDelta, rotationDelta) {
            if (_currentTool == EditingTool.crop && !_isCropping) {
              setState(() {
                _matrix = matrix;
                _currentScale *= scaleDelta as double;
              });
            }
          },
          child: GestureDetector(
            onTapDown: _handleImageTapDown,
            onPanUpdate: _handleImagePanUpdate,
            onPanEnd: (_) {
              if (_currentTool == EditingTool.crop && _isCropping && _cropRect != null) {
                setState(() {
                  _isCropping = false;
                  _imageProcessor.applyCrop(_cropRect!, _imageKey, _currentScale);
                  _encodedImage = _imageProcessor.encodedImage;
                  _matrix = Matrix4.identity();
                  _currentScale = 1.0;
                  _cropRect = null;
                  _addToHistory('Crop');
                });
              }
            },
            child: Center(
              child: Transform(
                transform: _matrix,
                child: Image.memory(_encodedImage!, key: _imageKey, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
        if (_currentTool == EditingTool.crop && _cropRect != null)
          Positioned.fromRect(
            rect: _cropRect!,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
        if (_isProcessing) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildToolPanel() {
    switch (_currentTool) {
      case EditingTool.adjust:
        return AdjustPanel(
          onAdjustmentChanged: (key, value) {
            _imageProcessor.updateAdjustment(key, value);
            setState(() => _encodedImage = _imageProcessor.encodedImage);
            _addToHistory(key);
          },
        );
      case EditingTool.highlight:
        return HighlightPanel(
          onHighlightChanged: (color, size) {
            _imageProcessor.updateHighlight(color, size);
            setState(() => _encodedImage = _imageProcessor.encodedImage);
            _addToHistory('Highlight');
          },
        );
      case EditingTool.crop:
        return CropPanel(
          isCropping: _isCropping,
          onStartCrop: () => setState(() => _isCropping = true),
          onApplyCrop: _cropRect != null
              ? () {
            setState(() {
              _imageProcessor.applyCrop(_cropRect!, _imageKey, _currentScale);
              _encodedImage = _imageProcessor.encodedImage;
              _matrix = Matrix4.identity();
              _currentScale = 1.0;
              _cropRect = null;
              _isCropping = false;
              _addToHistory('Crop');
            });
          }
              : null,
          onResetCrop: () => setState(() {
            _cropRect = null;
            _isCropping = false;
            _matrix = Matrix4.identity();
            _currentScale = 1.0;
            _addToHistory('Reset Crop');
          }),
        );
      case EditingTool.draw:
        return DrawPanel(
          onDrawChanged: (color, size, opacity) {
            _imageProcessor.updateDraw(color, size, opacity);
            setState(() => _encodedImage = _imageProcessor.encodedImage);
            _addToHistory('Draw');
          },
        );
      case EditingTool.text:
        return TextPanel(
          onTextAdded: (text, color) {
            _imageProcessor.addTextAnnotation(text, color);
            setState(() => _encodedImage = _imageProcessor.encodedImage);
            _addToHistory('Text Annotation');
          },
        );
      case EditingTool.effects:
        return EffectsPanel(
          onEffectChanged: (key, value) {
            _imageProcessor.updateEffect(key, value);
            setState(() => _encodedImage = _imageProcessor.encodedImage);
            _addToHistory(key);
          },
        );
      case EditingTool.stickers:
        return StickersPanel(
          onStickerAdded: (label, color) {
            _imageProcessor.addSticker(label, color);
            setState(() => _encodedImage = _imageProcessor.encodedImage);
            _addToHistory('Sticker: $label');
          },
        );
      case EditingTool.curves:
        return const SizedBox(); // Curves panel to be implemented
    }
  }
}