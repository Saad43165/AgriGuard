import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import '../../../../core/constants/animation_mixin.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../home/presentation/screens/home_screen.dart';

enum EditingTool {
  adjust,
  highlight,
  crop,
  draw,
  text,
  effects,
  stickers,
  curves,
}

enum BlendMode {
  normal,
  multiply,
  screen,
  overlay,
  softLight,
  hardLight,
}

class EditingHistory {
  final img.Image image;
  final String action;
  final DateTime timestamp;

  EditingHistory({
    required this.image,
    required this.action,
    required this.timestamp,
  });
}

class DrawingPoint {
  final Offset offset;
  final Color color;
  final double strokeWidth;
  final double opacity;

  DrawingPoint({
    required this.offset,
    required this.color,
    required this.strokeWidth,
    required this.opacity,
  });
}

class TextAnnotation {
  final Offset position;
  final String text;
  final TextStyle style;
  final double rotation;

  TextAnnotation({
    required this.position,
    required this.text,
    required this.style,
    required this.rotation,
  });
}

class ImageEditScreen extends StatefulWidget {
  final String imagePath;

  const ImageEditScreen({super.key, required this.imagePath});

  @override
  State<ImageEditScreen> createState() => _ImageEditScreenState();
}

class _ImageEditScreenState extends State<ImageEditScreen> with TickerProviderStateMixin, ScreenAnimationMixin {
  // Core image data
  img.Image? _originalImage;
  img.Image? _editedImage;
  Uint8List? _encodedImage;
  bool _isLoading = true;

  // History management
  final List<EditingHistory> _history = [];
  int _currentHistoryIndex = -1;
  static const int _maxHistorySize = 20;

  // Current editing tool
  EditingTool _currentTool = EditingTool.adjust;

  // Adjustment parameters
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  double _hue = 0.0;
  double _temperature = 0.0;
  double _tint = 0.0;
  double _exposure = 0.0;
  double _highlights = 0.0;
  double _shadows = 0.0;
  double _vibrance = 0.0;
  double _clarity = 0.0;
  double _vignette = 0.0;
  double _grain = 0.0;

  // Advanced curve adjustments
  List<Offset> _rgbCurve = [Offset(0, 0), Offset(1, 1)];
  List<Offset> _redCurve = [Offset(0, 0), Offset(1, 1)];
  List<Offset> _greenCurve = [Offset(0, 0), Offset(1, 1)];
  List<Offset> _blueCurve = [Offset(0, 0), Offset(1, 1)];

  // Drawing and annotation
  final List<DrawingPoint> _drawingPoints = [];
  final List<TextAnnotation> _textAnnotations = [];
  Color _selectedColor = Colors.red;
  double _brushSize = 5.0;
  double _brushOpacity = 1.0;

  // Highlighting
  final List<Offset> _highlightPoints = [];
  Color _highlightColor = Colors.yellow;
  double _highlightSize = 20.0;

  // Cropping
  final GlobalKey _imageKey = GlobalKey();
  Matrix4 _matrix = Matrix4.identity();
  Rect? _cropRect;
  bool _isCropping = false;
  Offset? _cropStart;
  Offset? _cropEnd;
  double _currentScale = 1.0;

  // Effects
  double _blurRadius = 0.0;
  double _sharpenAmount = 0.0;
  bool _isGrayscale = false;
  bool _isSepia = false;
  double _posterizeLevel = 0.0;

  // Animation controllers
  late AnimationController _toolSwitchController;
  late Animation<double> _toolSwitchAnimation;

  // UI state
  bool _isProcessing = false;
  final double _processingProgress = 0.0;

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
      if (mounted) {
        _toolSwitchController.forward();
      }
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
      final file = File(widget.imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found at ${widget.imagePath}');
      }

      final bytes = await file.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        throw Exception('Failed to decode image at ${widget.imagePath}');
      }

      setState(() {
        _originalImage = decodedImage;
        _editedImage = img.copyResize(decodedImage, width: 1200);
        _addToHistory('Original Image');
        _applyAllFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error loading image: $e');
        Navigator.pop(context);
      }
    }
  }

  void _addToHistory(String action) {
    if (_editedImage == null) return;

    if (_currentHistoryIndex < _history.length - 1) {
      _history.removeRange(_currentHistoryIndex + 1, _history.length);
    }

    _history.add(EditingHistory(
      image: img.copyResize(_editedImage!, width: _editedImage!.width),
      action: action,
      timestamp: DateTime.now(),
    ));

    _currentHistoryIndex = _history.length - 1;

    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
      _currentHistoryIndex--;
    }
  }

  void _undo() {
    if (_currentHistoryIndex > 0) {
      _currentHistoryIndex--;
      _editedImage = img.copyResize(
        _history[_currentHistoryIndex].image,
        width: _history[_currentHistoryIndex].image.width,
      );
      _applyAllFilters();
      setState(() {});
      HapticFeedback.mediumImpact();
    }
  }

  void _redo() {
    if (_currentHistoryIndex < _history.length - 1) {
      _currentHistoryIndex++;
      _editedImage = img.copyResize(
        _history[_currentHistoryIndex].image,
        width: _history[_currentHistoryIndex].image.width,
      );
      _applyAllFilters();
      setState(() {});
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _applyAllFilters() async {
    if (_editedImage == null || _originalImage == null) return;

    setState(() => _isProcessing = true);

    try {
      _editedImage = img.copyResize(_originalImage!, width: 1200);

      await _applyBasicAdjustments();
      await _applyAdvancedEffects();
      _applyDrawingAndAnnotations();
      _applyHighlights();
      await _applyTextAnnotations();
      if (_cropRect != null) _applyCrop();

      _encodedImage = img.encodeJpg(_editedImage!, quality: 95);
    } catch (e) {
      _showErrorSnackBar('Error applying filters: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _applyBasicAdjustments() async {
    if (_editedImage == null) return;

    _editedImage = img.adjustColor(
      _editedImage!,
      brightness: _brightness.clamp(-1.0, 1.0),
      contrast: _contrast.clamp(0.0, 2.0),
      saturation: _saturation.clamp(0.0, 2.0),
      hue: _hue.clamp(-180.0, 180.0),
      gamma: 1.0 + _exposure.clamp(-1.0, 1.0) * 0.5,
    );

    if (_temperature != 0.0 || _tint != 0.0) {
      _applyTemperatureAndTint();
    }

    if (_shadows != 0.0 || _highlights != 0.0) {
      _applyShadowsHighlights();
    }

    if (_vibrance != 0.0) {
      _applyVibrance();
    }
  }

  void _applyTemperatureAndTint() {
    if (_editedImage == null) return;

    for (int y = 0; y < _editedImage!.height; y++) {
      for (int x = 0; x < _editedImage!.width; x++) {
        final pixel = _editedImage!.getPixel(x, y);

        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();

        if (_temperature > 0) {
          r = (r + _temperature * 50).clamp(0, 255).toInt();
          b = (b - _temperature * 25).clamp(0, 255).toInt();
        } else if (_temperature < 0) {
          r = (r + _temperature * 25).clamp(0, 255).toInt();
          b = (b - _temperature * 50).clamp(0, 255).toInt();
        }

        if (_tint != 0) {
          g = (g + _tint * 30).clamp(0, 255).toInt();
        }

        _editedImage!.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }
  }

  void _applyShadowsHighlights() {
    if (_editedImage == null) return;

    for (int y = 0; y < _editedImage!.height; y++) {
      for (int x = 0; x < _editedImage!.width; x++) {
        final pixel = _editedImage!.getPixel(x, y);

        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();

        final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;

        if (luminance < 0.5 && _shadows != 0) {
          final factor = 1.0 + _shadows.clamp(-1.0, 1.0) * (1.0 - luminance);
          r = (r * factor).clamp(0, 255).toInt();
          g = (g * factor).clamp(0, 255).toInt();
          b = (b * factor).clamp(0, 255).toInt();
        }

        if (luminance > 0.5 && _highlights != 0) {
          final factor = 1.0 - _highlights.clamp(-1.0, 1.0) * luminance;
          r = (r * factor).clamp(0, 255).toInt();
          g = (g * factor).clamp(0, 255).toInt();
          b = (b * factor).clamp(0, 255).toInt();
        }

        _editedImage!.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }
  }

  void _applyVibrance() {
    if (_editedImage == null) return;

    for (int y = 0; y < _editedImage!.height; y++) {
      for (int x = 0; x < _editedImage!.width; x++) {
        final pixel = _editedImage!.getPixel(x, y);

        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();

        final max = math.max(r, math.max(g, b));
        final min = math.min(r, math.min(g, b));
        final saturation = max == 0 ? 0 : (max - min) / max;

        if (saturation < 0.5) {
          final factor = 1.0 + _vibrance.clamp(-1.0, 1.0) * (1.0 - saturation);
          final gray = (r + g + b) / 3;

          r = (gray + (r - gray) * factor).clamp(0, 255).toInt();
          g = (gray + (g - gray) * factor).clamp(0, 255).toInt();
          b = (gray + (b - gray) * factor).clamp(0, 255).toInt();

          _editedImage!.setPixel(x, y, img.ColorRgb8(r, g, b));
        }
      }
    }
  }

  Future<void> _applyAdvancedEffects() async {
    if (_editedImage == null) return;

    if (_isGrayscale) {
      _editedImage = img.grayscale(_editedImage!);
    }

    if (_isSepia) {
      _editedImage = img.sepia(_editedImage!);
    }

    if (_blurRadius > 0) {
      _editedImage = img.gaussianBlur(_editedImage!, radius: _blurRadius.toInt().clamp(0, 10));
    }

    if (_posterizeLevel > 0) {
      _applyPosterize(_posterizeLevel.clamp(0.0, 1.0));
    }

    if (_vignette > 0) {
      _applyVignette();
    }

    if (_grain > 0) {
      _applyFilmGrain();
    }
  }

  void _applyPosterize(double level) {
    if (_editedImage == null) return;
    final levels = (2 + level * 14).toInt().clamp(2, 16); // 2 to 16 levels
    final step = 255 ~/ (levels - 1);

    for (int y = 0; y < _editedImage!.height; y++) {
      for (int x = 0; x < _editedImage!.width; x++) {
        final pixel = _editedImage!.getPixel(x, y);
        final r = (pixel.r ~/ step) * step;
        final g = (pixel.g ~/ step) * step;
        final b = (pixel.b ~/ step) * step;
        _editedImage!.setPixel(x, y, img.ColorRgb8(r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255)));
      }
    }
  }

  void _applyVignette() {
    if (_editedImage == null) return;

    final centerX = _editedImage!.width / 2;
    final centerY = _editedImage!.height / 2;
    final maxDistance = math.sqrt(centerX * centerX + centerY * centerY);

    for (int y = 0; y < _editedImage!.height; y++) {
      for (int x = 0; x < _editedImage!.width; x++) {
        final distance = math.sqrt((x - centerX) * (x - centerX) + (y - centerY) * (y - centerY));
        final factor = 1.0 - _vignette.clamp(0.0, 1.0) * (distance / maxDistance);

        final pixel = _editedImage!.getPixel(x, y);
        final r = (pixel.r * factor).clamp(0, 255).toInt();
        final g = (pixel.g * factor).clamp(0, 255).toInt();
        final b = (pixel.b * factor).clamp(0, 255).toInt();

        _editedImage!.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }
  }

  void _applyFilmGrain() {
    if (_editedImage == null) return;

    final random = math.Random();
    final grainIntensity = _grain.clamp(0.0, 1.0) * 30;

    for (int y = 0; y < _editedImage!.height; y++) {
      for (int x = 0; x < _editedImage!.width; x++) {
        final pixel = _editedImage!.getPixel(x, y);
        final noise = (random.nextDouble() - 0.5) * grainIntensity;

        final r = (pixel.r + noise).clamp(0, 255).toInt();
        final g = (pixel.g + noise).clamp(0, 255).toInt();
        final b = (pixel.b + noise).clamp(0, 255).toInt();

        _editedImage!.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }
  }

  void _applyDrawingAndAnnotations() {
    if (_editedImage == null) return;

    for (final point in _drawingPoints) {
      final x = (point.offset.dx * _editedImage!.width).toInt().clamp(0, _editedImage!.width - 1);
      final y = (point.offset.dy * _editedImage!.height).toInt().clamp(0, _editedImage!.height - 1);

      img.drawCircle(
        _editedImage!,
        x: x,
        y: y,
        radius: point.strokeWidth.toInt(),
        color: img.ColorRgba8(
          (point.color.red * point.opacity).toInt(),
          (point.color.green * point.opacity).toInt(),
          (point.color.blue * point.opacity).toInt(),
          (point.opacity * 255).toInt(),
        ),
      );
    }
  }

  void _applyHighlights() {
    if (_editedImage == null) return;

    for (final point in _highlightPoints) {
      final x = (point.dx * _editedImage!.width).toInt().clamp(0, _editedImage!.width - 1);
      final y = (point.dy * _editedImage!.height).toInt().clamp(0, _editedImage!.height - 1);

      img.drawCircle(
        _editedImage!,
        x: x,
        y: y,
        radius: (_highlightSize * 1.2).toInt(),
        color: img.ColorRgba8(_highlightColor.red, _highlightColor.green, _highlightColor.blue, 100),
      );
      img.drawCircle(
        _editedImage!,
        x: x,
        y: y,
        radius: _highlightSize.toInt(),
        color: img.ColorRgba8(_highlightColor.red, _highlightColor.green, _highlightColor.blue, 150),
      );
      img.drawCircle(
        _editedImage!,
        x: x,
        y: y,
        radius: (_highlightSize * 0.6).toInt(),
        color: img.ColorRgba8(255, 255, 255, 200),
      );
    }
  }

  Future<void> _applyTextAnnotations() async {
    if (_editedImage == null || _textAnnotations.isEmpty) return;

    for (final annotation in _textAnnotations) {
      final x = (annotation.position.dx * _editedImage!.width).toInt().clamp(0, _editedImage!.width - 1);
      final y = (annotation.position.dy * _editedImage!.height).toInt().clamp(0, _editedImage!.height - 1);

      final ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: annotation.style.fontSize ?? 24.0,
      ));
      builder.pushStyle(ui.TextStyle(
        color: annotation.style.color ?? _selectedColor,
        fontWeight: annotation.style.fontWeight,
      ));
      builder.addText(annotation.text);

      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(ui.ParagraphConstraints(width: 200));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.save();
      canvas.translate(x.toDouble(), y.toDouble());
      canvas.rotate(annotation.rotation);
      canvas.drawParagraph(paragraph, Offset.zero);
      canvas.restore();

      final picture = recorder.endRecording();
      final img = await picture.toImage(paragraph.maxIntrinsicWidth.toInt(), paragraph.height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) continue;

    }
  }

  void _applyCrop() {
    if (_editedImage == null || _cropRect == null) return;

    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final imageWidth = _editedImage!.width;
    final imageHeight = _editedImage!.height;
    final boxSize = renderBox.size;

    final scaleX = imageWidth / (boxSize.width * _currentScale);
    final scaleY = imageHeight / (boxSize.height * _currentScale);

    final x = (_cropRect!.left * scaleX).round().clamp(0, imageWidth - 1);
    final y = (_cropRect!.top * scaleY).round().clamp(0, imageHeight - 1);
    final width = (_cropRect!.width * scaleX).round().clamp(1, imageWidth - x);
    final height = (_cropRect!.height * scaleY).round().clamp(1, imageHeight - y);

    _editedImage = img.copyCrop(
      _editedImage!,
      x: x,
      y: y,
      width: width,
      height: height,
    );

    _matrix = Matrix4.identity();
    _currentScale = 1.0;
    _cropRect = null;
    _isCropping = false;
    _applyAllFilters();
    _addToHistory('Crop');
  }

  Future<void> _saveAndNavigateToResults() async {
    if (_encodedImage == null || _editedImage == null) return;

    setState(() => _isProcessing = true);

    try {
      // 1. Save the edited image to permanent storage
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final editedPath = '${appDir.path}/$fileName';
      await File(editedPath).writeAsBytes(_encodedImage!);

      // 2. Generate scan result data
      final scanResult = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'imageUrl': editedPath,
        'result': 'Analyzed Plant',
        'confidence': 95,
        'recommendation': 'Apply recommended treatment',
        'timestamp': DateTime.now().toIso8601String(),
        'severity': 'Medium',
        'treatment': 'Detailed treatment instructions',
      };

      // 3. Save the scan to persistent storage
      await ScanService().saveScan(scanResult);

      if (mounted) {
        // 4. Navigate to results screen while ensuring home screen will update
        Navigator.pushNamed(
          context,
          AppRoutes.results,
          arguments: {
            'imagePath': editedPath,
            'scanData': scanResult,
          },
        ).then((_) {
          // This ensures home screen refreshes when we return from results
          if (mounted) {
            Navigator.pop(context); // Go back to home
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error saving scan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: EdgeInsets.all(AppMeasurements.getResponsivePadding(context)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.error.withOpacity(0.8),
                  Theme.of(context).colorScheme.error.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
            ),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _switchTool(EditingTool tool) {
    setState(() {
      _currentTool = tool;
    });
    _toolSwitchController.reset();
    _toolSwitchController.forward();
    HapticFeedback.selectionClick();
  }

  void _handleImageTapDown(TapDownDetails details) {
    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;
    final normalizedX = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final normalizedY = (localPosition.dy / size.height).clamp(0.0, 1.0);

    switch (_currentTool) {
      case EditingTool.highlight:
        setState(() {
          _highlightPoints.add(Offset(normalizedX, normalizedY));
        });
        _applyAllFilters();
        _addToHistory('Add Highlight');
        break;

      case EditingTool.draw:
        setState(() {
          _drawingPoints.add(DrawingPoint(
            offset: Offset(normalizedX, normalizedY),
            color: _selectedColor,
            strokeWidth: _brushSize,
            opacity: _brushOpacity,
          ));
        });
        _applyAllFilters();
        _addToHistory('Draw');
        break;

      case EditingTool.crop:
        if (_isCropping) {
          setState(() {
            _cropStart = localPosition;
            _cropEnd = localPosition;
            _updateCropRect();
          });
        }
        break;

      case EditingTool.text:
        setState(() {
          _textAnnotations.add(TextAnnotation(
            position: Offset(normalizedX, normalizedY),
            text: 'Sample Text',
            style: TextStyle(
              color: _selectedColor,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
            rotation: 0.0,
          ));
        });
        _applyAllFilters();
        _addToHistory('Add Text');
        break;

      default:
        break;
    }
  }

  void _handleImagePanUpdate(DragUpdateDetails details) {
    if (_currentTool == EditingTool.crop && _isCropping && _cropStart != null) {
      final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final localPosition = renderBox.globalToLocal(details.globalPosition);
      setState(() {
        _cropEnd = localPosition;
        _updateCropRect();
      });
    }
  }

  void _updateCropRect() {
    if (_cropStart == null || _cropEnd == null) return;

    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

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

  void _resetAllAdjustments() {
    setState(() {
      _brightness = 0.0;
      _contrast = 1.0;
      _saturation = 1.0;
      _hue = 0.0;
      _temperature = 0.0;
      _tint = 0.0;
      _exposure = 0.0;
      _highlights = 0.0;
      _shadows = 0.0;
      _vibrance = 0.0;
      _clarity = 0.0;
      _vignette = 0.0;
      _grain = 0.0;
      _blurRadius = 0.0;
      _sharpenAmount = 0.0;
      _posterizeLevel = 0.0;
      _isGrayscale = false;
      _isSepia = false;
      _highlightPoints.clear();
      _drawingPoints.clear();
      _textAnnotations.clear();
      _cropRect = null;
      _isCropping = false;
      _matrix = Matrix4.identity();
      _currentScale = 1.0;
      _rgbCurve = [Offset(0, 0), Offset(1, 1)];
      _redCurve = [Offset(0, 0), Offset(1, 1)];
      _greenCurve = [Offset(0, 0), Offset(1, 1)];
      _blueCurve = [Offset(0, 0), Offset(1, 1)];
    });
    _applyAllFilters();
    _addToHistory('Reset All');
  }

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context) * MediaQuery.of(context).size.width / 400;
    final borderRadius = AppMeasurements.getResponsiveBorderRadius(context);
    final isLargeScreen = AppMeasurements.isLargeScreen(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: _buildBackgroundGradient(),
        child: _isLoading
            ? _buildLoadingIndicator()
            : SafeArea(
          child: applyAnimations(
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = isLargeScreen ? 600.0 : constraints.maxWidth;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(padding),
                            child: _buildImageEditor(),
                          ),
                        ),
                        SizedBox(height: smallPadding),
                        SizedBox(
                          height: 60.0 * MediaQuery.of(context).size.width / 400,
                          child: _buildToolSelector(),
                        ),
                        SizedBox(height: smallPadding),
                        SizedBox(
                          height: 200.0 * MediaQuery.of(context).size.height / 800,
                          child: _buildToolPanel(),
                        ),
                        SizedBox(height: padding),
                      ],
                    ),
                  ),
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
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ).createShader(bounds),
        child: Text(
          AppStrings.editImage,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 22),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.undo_rounded,
            size: AppMeasurements.getResponsiveIconSizeMedium(context),
          ),
          onPressed: _currentHistoryIndex > 0 ? _undo : null,
          tooltip: AppStrings.undo,
        ),
        IconButton(
          icon: Icon(
            Icons.redo_rounded,
            size: AppMeasurements.getResponsiveIconSizeMedium(context),
          ),
          onPressed: _currentHistoryIndex < _history.length - 1 ? _redo : null,
          tooltip: AppStrings.redo,
        ),
        IconButton(
          icon: Icon(
            Icons.restart_alt_rounded,
            size: AppMeasurements.getResponsiveIconSizeMedium(context),
          ),
          onPressed: _resetAllAdjustments,
          tooltip: AppStrings.reset,
        ),
        IconButton(
          icon: Icon(
            Icons.check_rounded,
            size: AppMeasurements.getResponsiveIconSizeMedium(context),
          ),
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
            ? [
          const Color(0xFF0F0F23),
          const Color(0xFF16213E),
          const Color(0xFF1A1A2E),
          const Color(0xFF0F0F23),
        ]
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

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildImageEditor() {
    if (_encodedImage == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        GestureDetector(
          onTapDown: _handleImageTapDown,
          onPanUpdate: _handleImagePanUpdate,
          onPanEnd: (_) {
            if (_currentTool == EditingTool.crop && _isCropping) {
              setState(() {
                _isCropping = false;
                if (_cropRect != null) {
                  _applyCrop();
                }
              });
            }
          },
          child: MatrixGestureDetector(
            onMatrixUpdate: (matrix, translationDelta, scaleDelta, rotationDelta) {
              if (_currentTool == EditingTool.crop && !_isCropping) {
                setState(() {
                  _matrix = matrix;
                  _currentScale *= scaleDelta as double;
                });
              }
            },
            child: Center(
              child: Transform(
                transform: _matrix,
                child: Image.memory(
                  _encodedImage!,
                  key: _imageKey,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        if (_currentTool == EditingTool.crop && _cropRect != null)
          Positioned.fromRect(
            rect: _cropRect!,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: AppMeasurements.getResponsiveFontSize(context, baseSize: 2),
                ),
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
        if (_isProcessing)
          Center(
            child: CircularProgressIndicator(
              value: _processingProgress,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildToolSelector() {
    final toolSelectorHeight = AppMeasurements.getResponsivePadding(context) * 3;
    final padding = AppMeasurements.getResponsivePadding(context);
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context) * MediaQuery.of(context).size.width / 400;
    final borderRadius = AppMeasurements.getResponsiveBorderRadius(context);

    return Container(
      height: toolSelectorHeight * MediaQuery.of(context).size.width / 400,
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: EditingTool.values.map((tool) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: smallPadding),
            child: AnimatedBuilder(
              animation: _toolSwitchAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _currentTool == tool
                      ? 1.0 + 0.2 * _toolSwitchAnimation.value
                      : 1.0,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: () => _switchTool(tool),
                child: Chip(
                  label: Text(
                    tool.toString().split('.').last.capitalize(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _currentTool == tool
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  backgroundColor: _currentTool == tool
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToolPanel() {
    switch (_currentTool) {
      case EditingTool.adjust:
        return _buildAdjustPanel();
      case EditingTool.highlight:
        return _buildHighlightPanel();
      case EditingTool.crop:
        return _buildCropPanel();
      case EditingTool.draw:
        return _buildDrawPanel();
      case EditingTool.text:
        return _buildTextPanel();
      case EditingTool.effects:
        return _buildEffectsPanel();
      case EditingTool.stickers:
        return _buildStickersPanel();
      case EditingTool.curves:
        return _buildCurvesPanel();
    }
  }

  Widget _buildAdjustPanel() {
    final padding = AppMeasurements.getResponsivePadding(context) * MediaQuery.of(context).size.width / 400;
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context) * MediaQuery.of(context).size.width / 400;

    return Container(
      padding: EdgeInsets.all(padding),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildSlider(
              label: AppStrings.brightness,
              value: _brightness,
              onChanged: (value) {
                setState(() => _brightness = value);
                _applyAllFilters();
                _addToHistory('Brightness');
              },
              min: -1.0,
              max: 1.0,
            ),
            SizedBox(height: smallPadding),
            _buildSlider(
              label: AppStrings.contrast,
              value: _contrast,
              onChanged: (value) {
                setState(() => _contrast = value);
                _applyAllFilters();
                _addToHistory('Contrast');
              },
              min: 0.0,
              max: 2.0,
            ),
            SizedBox(height: smallPadding),
            _buildSlider(
              label: AppStrings.saturation,
              value: _saturation,
              onChanged: (value) {
                setState(() => _saturation = value);
                _applyAllFilters();
                _addToHistory('Saturation');
              },
              min: 0.0,
              max: 2.0,
            ),
            SizedBox(height: smallPadding),
            _buildSlider(
              label: AppStrings.hue,
              value: _hue,
              onChanged: (value) {
                setState(() => _hue = value);
                _applyAllFilters();
                _addToHistory('Hue');
              },
              min: -180.0,
              max: 180.0,
            ),
            SizedBox(height: smallPadding),
            _buildSlider(
              label: AppStrings.temperature,
              value: _temperature,
              onChanged: (value) {
                setState(() => _temperature = value);
                _applyAllFilters();
                _addToHistory('Temperature');
              },
              min: -1.0,
              max: 1.0,
            ),
            SizedBox(height: smallPadding),
            _buildSlider(
              label: AppStrings.tint,
              value: _tint,
              onChanged: (value) {
                setState(() => _tint = value);
                _applyAllFilters();
                _addToHistory('Tint');
              },
              min: -1.0,
              max: 1.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightPanel() {
    final padding = AppMeasurements.getResponsivePadding(context) * MediaQuery.of(context).size.width / 400;
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context) * MediaQuery.of(context).size.width / 400;
    final borderRadius = AppMeasurements.getResponsiveBorderRadius(context);

    return Container(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          _buildSlider(
            label: AppStrings.highlightSize,
            value: _highlightSize,
            onChanged: (value) {
              setState(() => _highlightSize = value);
              _applyAllFilters();
              _addToHistory('Highlight Size');
            },
            min: 5.0,
            max: 50.0,
          ),
          SizedBox(height: smallPadding),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    AppStrings.selectColor,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: _highlightColor,
                      onColorChanged: (color) {
                        setState(() => _highlightColor = color);
                        _applyAllFilters();
                        _addToHistory('Highlight Color');
                      },
                      enableAlpha: false,
                      pickerAreaHeightPercent: 0.8,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        AppStrings.done,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Text(
              AppStrings.chooseColor,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropPanel() {
    final padding = AppMeasurements.getResponsivePadding(context) * MediaQuery.of(context).size.width / 400;
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context) * MediaQuery.of(context).size.width / 400;
    final borderRadius = AppMeasurements.getResponsiveBorderRadius(context);

    return Container(
      padding: EdgeInsets.all(padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: smallPadding,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            onPressed: () {
              setState(() => _isCropping = true);
              HapticFeedback.lightImpact();
            },
            child: Text(
              AppStrings.startCrop,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: smallPadding,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            onPressed: _cropRect != null
                ? () {
              setState(() {
                _applyCrop();
              });
              HapticFeedback.lightImpact();
            }
                : null,
            child: Text(
              AppStrings.applyCrop,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: smallPadding,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            onPressed: () {
              setState(() {
                _cropRect = null;
                _isCropping = false;
                _matrix = Matrix4.identity();
                _currentScale = 1.0;
              });
              _applyAllFilters();
              _addToHistory('Reset Crop');
              HapticFeedback.lightImpact();
            },
            child: Text(
              AppStrings.resetCrop,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawPanel() {
    final padding = AppMeasurements.getResponsivePadding(context) * MediaQuery.of(context).size.width / 400;
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context) * MediaQuery.of(context).size.width / 400;
    final borderRadius = AppMeasurements.getResponsiveBorderRadius(context);

    return Container(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          _buildSlider(
            label: AppStrings.brushSize,
            value: _brushSize,
            onChanged: (value) {
              setState(() => _brushSize = value);
              _applyAllFilters();
              _addToHistory('Brush Size');
            },
            min: 1.0,
            max: 20.0,
          ),
          SizedBox(height: smallPadding),
          _buildSlider(
            label: AppStrings.brushOpacity,
            value: _brushOpacity,
            onChanged: (value) {
              setState(() => _brushOpacity = value);
              _applyAllFilters();
              _addToHistory('Brush Opacity');
            },
            min: 0.1,
            max: 1.0,
          ),
          SizedBox(height: smallPadding),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    AppStrings.selectColor,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: _selectedColor,
                      onColorChanged: (color) {
                        setState(() => _selectedColor = color);
                        _applyAllFilters();
                        _addToHistory('Draw Color');
                      },
                      enableAlpha: true,
                      pickerAreaHeightPercent: 0.8,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        AppStrings.done,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Text(
              AppStrings.chooseColor,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextPanel() {
    final padding = AppMeasurements.getResponsivePadding(context) * MediaQuery.of(context).size.width / 400;
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context) * MediaQuery.of(context).size.width / 400;
    final borderRadius = AppMeasurements.getResponsiveBorderRadius(context);

    return Container(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: AppStrings.enterText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: smallPadding,
              ),
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  _textAnnotations.add(TextAnnotation(
                    position: Offset(0.5, 0.5), // Center by default
                    text: value,
                    style: TextStyle(
                      color: _selectedColor,
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 24),
                      fontWeight: FontWeight.bold,
                    ),
                    rotation: 0.0,
                  ));
                });
                _applyAllFilters();
                _addToHistory('Text Annotation');
              }
            },
          ),
          SizedBox(height: smallPadding),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    AppStrings.selectColor,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: _selectedColor,
                      onColorChanged: (color) {
                        setState(() => _selectedColor = color);
                        _applyAllFilters();
                        _addToHistory('Text Color');
                      },
                      enableAlpha: true,
                      pickerAreaHeightPercent: 0.8,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        AppStrings.done,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Text(
              AppStrings.chooseColor,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEffectsPanel() {
    final padding = AppMeasurements.getResponsivePadding(context) * MediaQuery.of(context).size.width / 400;
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context) * MediaQuery.of(context).size.width / 400;

    return Container(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          _buildSlider(
            label: AppStrings.blur,
            value: _blurRadius,
            onChanged: (value) {
              setState(() => _blurRadius = value);
              _applyAllFilters();
              _addToHistory('Blur');
            },
            min: 0.0,
            max: 10.0,
          ),
          SizedBox(height: smallPadding),
          _buildSlider(
            label: AppStrings.posterize,
            value: _posterizeLevel,
            onChanged: (value) {
              setState(() => _posterizeLevel = value);
              _applyAllFilters();
              _addToHistory('Posterize');
            },
            min: 0.0,
            max: 1.0,
          ),
          SizedBox(height: smallPadding),
          SwitchListTile(
            title: Text(
              AppStrings.grayscale,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
            ),
            value: _isGrayscale,
            onChanged: (value) {
              setState(() => _isGrayscale = value);
              _applyAllFilters();
              _addToHistory('Grayscale');
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: smallPadding),
          SwitchListTile(
            title: Text(
              AppStrings.sepia,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
            ),
            value: _isSepia,
            onChanged: (value) {
              setState(() => _isSepia = value);
              _applyAllFilters();
              _addToHistory('Sepia');
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStickersPanel() {
    final padding = AppMeasurements.getResponsivePadding(context) * MediaQuery.of(context).size.width / 400;
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context) * MediaQuery.of(context).size.width / 400;

    return Container(
      padding: EdgeInsets.all(padding),
      child: Wrap(
        spacing: smallPadding,
        runSpacing: smallPadding,
        children: [
          _buildStickerIcon(Icons.favorite, 'Heart'),
          _buildStickerIcon(Icons.star, 'Star'),
          _buildStickerIcon(Icons.local_florist, 'Flower'),
        ],
      ),
    );
  }

  Widget _buildStickerIcon(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        // Placeholder for sticker placement (to be implemented with image assets)
        setState(() {
          _textAnnotations.add(TextAnnotation(
            position: Offset(0.5, 0.5), // Center by default
            text: label,
            style: TextStyle(
              color: _selectedColor,
              fontSize: 40.0,
              fontWeight: FontWeight.bold,
            ),
            rotation: 0.0,
          ));
        });
        _applyAllFilters();
        _addToHistory('Add Sticker: $label');
      },
      child: Chip(
        avatar: Icon(icon, color: _selectedColor),
        label: Text(label),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildCurvesPanel() {
    final padding = AppMeasurements.getResponsivePadding(context) * MediaQuery.of(context).size.width / 400;
    return Container(
      padding: EdgeInsets.all(padding),
      child: CustomPaint(
        painter: CurvePainter(_rgbCurve, _redCurve, _greenCurve, _blueCurve),
        child: GestureDetector(
          onPanUpdate: (details) {
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox == null) return;

            final localPosition = renderBox.globalToLocal(details.globalPosition);
            final x = (localPosition.dx / renderBox.size.width).clamp(0.0, 1.0);
            final y = 1.0 - (localPosition.dy / renderBox.size.height).clamp(0.0, 1.0);

            setState(() {
              _rgbCurve.add(Offset(x, y));
              _applyCurveAdjustments();
            });
          },
          child: SizedBox(
            height: 200.0 * MediaQuery.of(context).size.height / 800,
            width: double.infinity,
          ),
        ),
      ),
    );
  }

  void _applyCurveAdjustments() {
    if (_editedImage == null) return;

    for (int y = 0; y < _editedImage!.height; y++) {
      for (int x = 0; x < _editedImage!.width; x++) {
        final pixel = _editedImage!.getPixel(x, x);
        final normalized = x / _editedImage!.width;

        final r = _interpolateCurve(normalized, _redCurve).clamp(0, 1) * 255;
        final g = _interpolateCurve(normalized, _greenCurve).clamp(0, 1) * 255;
        final b = _interpolateCurve(normalized, _blueCurve).clamp(0, 1) * 255;

        _editedImage!.setPixel(x, y, img.ColorRgb8(r.toInt(), g.toInt(), b.toInt()));
      }
    }
    _applyAllFilters();
    _addToHistory('Curve Adjustment');
  }

  double _interpolateCurve(double x, List<Offset> curve) {
    if (curve.length < 2) return x;

    for (int i = 0; i < curve.length - 1; i++) {
      if (x >= curve[i].dx && x <= curve[i + 1].dx) {
        final t = (x - curve[i].dx) / (curve[i + 1].dx - curve[i].dx);
        return curve[i].dy + t * (curve[i + 1].dy - curve[i].dy);
      }
    }
    return curve.last.dy;
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
  }) {
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context) * MediaQuery.of(context).size.width / 400;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: smallPadding),
      child: Row(
        children: [
          SizedBox(
            width: AppMeasurements.getResponsiveFontSize(context, baseSize: 100) * MediaQuery.of(context).size.width / 400,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
              ),
            ),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
          SizedBox(
            width: AppMeasurements.getResponsiveFontSize(context, baseSize: 50) * MediaQuery.of(context).size.width / 400,
            child: Text(
              value.toStringAsFixed(2),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  final List<Offset> rgbCurve;
  final List<Offset> redCurve;
  final List<Offset> greenCurve;
  final List<Offset> blueCurve;

  CurvePainter(this.rgbCurve, this.redCurve, this.greenCurve, this.blueCurve);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    path.moveTo(0, size.height);
    for (final point in rgbCurve) {
      path.lineTo(point.dx * size.width, (1 - point.dy) * size.height);
    }
    canvas.drawPath(path, paint);

    paint.color = Colors.red;
    final redPath = Path();
    redPath.moveTo(0, size.height);
    for (final point in redCurve) {
      redPath.lineTo(point.dx * size.width, (1 - point.dy) * size.height);
    }
    canvas.drawPath(redPath, paint);

    paint.color = Colors.green;
    final greenPath = Path();
    greenPath.moveTo(0, size.height);
    for (final point in greenCurve) {
      greenPath.lineTo(point.dx * size.width, (1 - point.dy) * size.height);
    }
    canvas.drawPath(greenPath, paint);

    paint.color = Colors.blue;
    final bluePath = Path();
    bluePath.moveTo(0, size.height);
    for (final point in blueCurve) {
      bluePath.lineTo(point.dx * size.width, (1 - point.dy) * size.height);
    }
    canvas.drawPath(bluePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
