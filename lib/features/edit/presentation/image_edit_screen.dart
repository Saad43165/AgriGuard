import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;
import '../../../../core/constants/animation_mixin.dart';
import '../../../core/constants/app_routes.dart';
import '../../home/presentation/screens/components/scan_service.dart';
import 'utils/image_processor.dart';
import 'widgets/app_bar.dart';
import 'widgets/image_editor.dart';
import 'widgets/tool_panel_container.dart';
import 'widgets/tool_selector_container.dart';
import 'models/editing_history.dart';
import 'utils/constants.dart';

class ImageEditScreen extends StatefulWidget {
  final String imagePath;

  const ImageEditScreen({super.key, required this.imagePath});

  @override
  State<ImageEditScreen> createState() => _ImageEditScreenState();
}

class _ImageEditScreenState extends State<ImageEditScreen>
    with TickerProviderStateMixin, ScreenAnimationMixin {
  final ImageProcessor _imageProcessor = ImageProcessor();
  late AnimationController _toolSwitchController;
  late Animation<double> _toolSwitchAnimation;
  late AnimationController _panelController;
  late Animation<double> _panelAnimation;

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
  bool _isPanelExpanded = false;

  @override
  void initState() {
    super.initState();
    initializeAnimations();
    _initializeAnimations();
    _loadImage();
  }

  void _initializeAnimations() {
    _toolSwitchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toolSwitchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _toolSwitchController, curve: Curves.elasticOut),
    );

    _panelController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _panelAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _panelController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _toolSwitchController.forward();
        _panelController.forward();
      }
    });
  }

  @override
  void dispose() {
    _toolSwitchController.dispose();
    _panelController.dispose();
    disposeAnimations();
    super.dispose();
  }

  Future<void> _loadImage() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await _imageProcessor.loadImage(widget.imagePath);
      if (mounted) {
        setState(() {
          _encodedImage = _imageProcessor.encodedImage;
          _isLoading = false;
        });
        _addToHistory('Original Image');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error loading image: $e');
        Navigator.pop(context);
      }
    }
  }

  void _addToHistory(String action) {
    if (_imageProcessor.editedImage == null) return;
    if (_currentHistoryIndex < _history.length - 1) {
      _history.removeRange(_currentHistoryIndex + 1, _history.length);
    }
    _history.add(EditingHistory(
      image: _imageProcessor.editedImage!,
      action: action,
      timestamp: DateTime.now(),
    ));
    if (_history.length > Constants.maxHistorySize) {
      _history.removeAt(0);
    } else {
      _currentHistoryIndex++;
    }
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

// In your ImageEditScreen, fix the _saveAndNavigateToResults method:
  Future<void> _saveAndNavigateToResults() async {
    if (_encodedImage == null || _isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final scanResult = await _imageProcessor.saveImage();
      await ScanService().saveScan(scanResult);

      if (mounted) {
        // Debug print to see what we're passing
        debugPrint('Navigating to results with scanResult: $scanResult');
        debugPrint('Image path: ${scanResult['imagePath']}');
        debugPrint('Image URL: ${scanResult['imageUrl']}');

        Navigator.pushNamed(
            context,
            AppRoutes.results,
            arguments: {
              'scanData': scanResult, // Pass the entire scan result
            }
        ).then((_) {
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
    if (!mounted) return;
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
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.3,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  void _switchTool(EditingTool tool) {
    if (_currentTool == tool) return;
    setState(() {
      _currentTool = tool;
      _isPanelExpanded = false;
    });
    _toolSwitchController.reset();
    _toolSwitchController.forward();
    _panelController.reset();
    _panelController.forward();
    HapticFeedback.selectionClick();
  }

  void _togglePanelExpansion() {
    setState(() => _isPanelExpanded = !_isPanelExpanded);
    HapticFeedback.lightImpact();
  }

  void _handleImageTapDown(TapDownDetails details) {
    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;
    if (localPosition.dx < 0 || localPosition.dx > size.width ||
        localPosition.dy < 0 || localPosition.dy > size.height) return;
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
      try {
        _imageProcessor.handleInteraction(_currentTool, normalized);
        setState(() => _encodedImage = _imageProcessor.encodedImage);
        _addToHistory(_currentTool.toString().split('.').last);
      } catch (e) {
        _showErrorSnackBar('Error applying edit: $e');
      }
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
    final left = _cropStart!.dx.clamp(0.0, double.infinity);
    final top = _cropStart!.dy.clamp(0.0, double.infinity);
    final right = _cropEnd!.dx.clamp(0.0, double.infinity);
    final bottom = _cropEnd!.dy.clamp(0.0, double.infinity);
    final width = (right - left).abs();
    final height = (bottom - top).abs();
    if (width > 20 && height > 20) {
      _cropRect = Rect.fromLTWH(
        left < right ? left : right,
        top < bottom ? top : bottom,
        width,
        height,
      );
    }
  }

  void _resetCrop() {
    setState(() {
      _cropRect = null;
      _isCropping = false;
      _matrix = Matrix4.identity();
      _currentScale = 1.0;
      _cropStart = null;
      _cropEnd = null;
    });
  }

  void _applyCrop() {
    if (_cropRect == null) return;
    try {
      setState(() {
        _imageProcessor.applyCrop(_cropRect!, _imageKey, _currentScale);
        _encodedImage = _imageProcessor.encodedImage;
        _addToHistory('Crop');
      });
      _resetCrop();
    } catch (e) {
      _showErrorSnackBar('Error applying crop: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = screenWidth > screenHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: EditAppBar(
        currentHistoryIndex: _currentHistoryIndex,
        historyLength: _history.length,
        isProcessing: _isProcessing,
        onUndo: _undo,
        onRedo: _redo,
        onReset: () {
          _imageProcessor.resetAdjustments();
          setState(() => _encodedImage = _imageProcessor.encodedImage);
          _addToHistory('Reset All');
          HapticFeedback.mediumImpact();
        },
        onSave: _saveAndNavigateToResults,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [Color(0xFF121212), Color(0xFF1E1E1E), Color(0xFF121212)]
                : const [Color(0xFFF5F5F5), Color(0xFFE0E0E0), Color(0xFFF5F5F5)],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
            : SafeArea(
          child: applyAnimations(
            isLandscape
                ? Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ImageEditor(
                    encodedImage: _encodedImage,
                    currentTool: _currentTool,
                    isCropping: _isCropping,
                    cropRect: _cropRect,
                    matrix: _matrix,
                    currentScale: _currentScale,
                    imageKey: _imageKey,
                    isProcessing: _isProcessing,
                    onMatrixUpdate: (matrix, translation, scale, rotation) {
                      if (_currentTool == EditingTool.crop && !_isCropping) {
                        setState(() {
                          _matrix = matrix;
                          _currentScale = (_currentScale * (scale as double)).clamp(0.5, 3.0);
                        });
                      }
                    },
                    onTapDown: _handleImageTapDown,
                    onPanUpdate: _handleImagePanUpdate,
                    onPanEnd: (_) {
                      if (_currentTool == EditingTool.crop && _isCropping && _cropRect != null) {
                        _applyCrop();
                      }
                    },
                  ),
                ),
                Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      ToolSelectorContainer(
                        currentTool: _currentTool,
                        onToolSelected: _switchTool,
                        animation: _toolSwitchAnimation,
                        isHorizontal: false,
                      ),
                      Expanded(
                        child: ToolPanelContainer(
                          currentTool: _currentTool,
                          isPanelExpanded: _isPanelExpanded,
                          panelAnimation: _panelAnimation,
                          onToggleExpansion: _togglePanelExpansion,
                          onAdjustmentChanged: (key, value) {
                            _imageProcessor.updateAdjustment(key, value);
                            setState(() => _encodedImage = _imageProcessor.encodedImage);
                            _addToHistory(key);
                          },
                          onHighlightChanged: (color, size) {
                            _imageProcessor.updateHighlight(color, size);
                            setState(() => _encodedImage = _imageProcessor.encodedImage);
                            _addToHistory('Highlight');
                          },
                          onStartCrop: () => setState(() => _isCropping = true),
                          onApplyCrop: _cropRect != null ? _applyCrop : null,
                          onResetCrop: _resetCrop,
                          onDrawChanged: (color, size, opacity) {
                            _imageProcessor.updateDraw(color, size, opacity);
                            setState(() => _encodedImage = _imageProcessor.encodedImage);
                            _addToHistory('Draw');
                          },
                          onTextAdded: (text, color) {
                            _imageProcessor.addTextAnnotation(text, color);
                            setState(() => _encodedImage = _imageProcessor.encodedImage);
                            _addToHistory('Text Annotation');
                          },
                          onEffectChanged: (key, value) {
                            _imageProcessor.updateEffect(key, value);
                            setState(() => _encodedImage = _imageProcessor.encodedImage);
                            _addToHistory(key);
                          },
                          onStickerAdded: (label, color) {
                            _imageProcessor.addSticker(label, color);
                            setState(() => _encodedImage = _imageProcessor.encodedImage);
                            _addToHistory('Sticker: $label');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
                : Column(
              children: [
                Expanded(
                  flex: _isPanelExpanded ? 2 : 3,
                  child: ImageEditor(
                    encodedImage: _encodedImage,
                    currentTool: _currentTool,
                    isCropping: _isCropping,
                    cropRect: _cropRect,
                    matrix: _matrix,
                    currentScale: _currentScale,
                    imageKey: _imageKey,
                    isProcessing: _isProcessing,
                    onMatrixUpdate: (matrix, translation, scale, rotation) {
                      if (_currentTool == EditingTool.crop && !_isCropping) {
                        setState(() {
                          _matrix = matrix;
                          _currentScale = (_currentScale * (scale as double)).clamp(0.5, 3.0);
                        });
                      }
                    },
                    onTapDown: _handleImageTapDown,
                    onPanUpdate: _handleImagePanUpdate,
                    onPanEnd: (_) {
                      if (_currentTool == EditingTool.crop && _isCropping && _cropRect != null) {
                        _applyCrop();
                      }
                    },
                  ),
                ),
                ToolSelectorContainer(
                  currentTool: _currentTool,
                  onToolSelected: _switchTool,
                  animation: _toolSwitchAnimation,
                  isHorizontal: true,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: _isPanelExpanded ? 300 : 120,
                  child: ToolPanelContainer(
                    currentTool: _currentTool,
                    isPanelExpanded: _isPanelExpanded,
                    panelAnimation: _panelAnimation,
                    onToggleExpansion: _togglePanelExpansion,
                    onAdjustmentChanged: (key, value) {
                      _imageProcessor.updateAdjustment(key, value);
                      setState(() => _encodedImage = _imageProcessor.encodedImage);
                      _addToHistory(key);
                    },
                    onHighlightChanged: (color, size) {
                      _imageProcessor.updateHighlight(color, size);
                      setState(() => _encodedImage = _imageProcessor.encodedImage);
                      _addToHistory('Highlight');
                    },
                    onStartCrop: () => setState(() => _isCropping = true),
                    onApplyCrop: _cropRect != null ? _applyCrop : null,
                    onResetCrop: _resetCrop,
                    onDrawChanged: (color, size, opacity) {
                      _imageProcessor.updateDraw(color, size, opacity);
                      setState(() => _encodedImage = _imageProcessor.encodedImage);
                      _addToHistory('Draw');
                    },
                    onTextAdded: (text, color) {
                      _imageProcessor.addTextAnnotation(text, color);
                      setState(() => _encodedImage = _imageProcessor.encodedImage);
                      _addToHistory('Text Annotation');
                    },
                    onEffectChanged: (key, value) {
                      _imageProcessor.updateEffect(key, value);
                      setState(() => _encodedImage = _imageProcessor.encodedImage);
                      _addToHistory(key);
                    },
                    onStickerAdded: (label, color) {
                      _imageProcessor.addSticker(label, color);
                      setState(() => _encodedImage = _imageProcessor.encodedImage);
                      _addToHistory('Sticker: $label');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}