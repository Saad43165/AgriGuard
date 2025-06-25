// lib/features/scan/presentation/screens/image_edit_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3, Matrix4;
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import '../../../../core/constants/app_constants.dart';

class ImageEditScreen extends StatefulWidget {
  final String imagePath;

  const ImageEditScreen({super.key, required this.imagePath});

  @override
  State<ImageEditScreen> createState() => _ImageEditScreenState();
}

class _ImageEditScreenState extends State<ImageEditScreen> {
  img.Image? _originalImage;
  img.Image? _editedImage;
  Uint8List? _encodedImage;
  bool _isLoading = true;
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  Color _selectedColor = Colors.red;
  final List<Offset> _points = [];
  final GlobalKey _imageKey = GlobalKey();
  Matrix4 _matrix = Matrix4.identity();
  Rect? _cropRect;
  bool _isCropping = false;
  Offset? _cropStart;

  @override
  void initState() {
    super.initState();
    debugPrint('ImageEditScreen initialized with imagePath: ${widget.imagePath}');
    _loadImage();
  }

  Future<void> _loadImage() async {
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
        _editedImage = img.copyResize(decodedImage, width: 800);
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading image: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _applyFilters() {
    if (_editedImage == null || _originalImage == null) return;
    _editedImage = img.copyResize(_originalImage!, width: 800);
    _editedImage = img.adjustColor(
      _editedImage!,
      brightness: _brightness.clamp(-1.0, 1.0),
      contrast: _contrast.clamp(0.0, 2.0),
      saturation: _saturation.clamp(0.0, 2.0),
    );
    if (_points.isNotEmpty) _highlightAreas();
    if (_cropRect != null) _applyCrop();
    _encodedImage = img.encodeJpg(_editedImage!);
    if (mounted) setState(() {});
  }

  void _highlightAreas() {
    if (_editedImage == null) {
      debugPrint('Error: _editedImage is null in _highlightAreas');
      return;
    }
    for (final point in _points) {
      final x = (point.dx * _editedImage!.width).toInt().clamp(0, _editedImage!.width - 1);
      final y = (point.dy * _editedImage!.height).toInt().clamp(0, _editedImage!.height - 1);
      debugPrint('Highlighting at x: $x, y: $y with color: $_selectedColor');
      img.drawCircle(
        _editedImage!,
        x: x,
        y: y,
        radius: 10,
        color: img.ColorRgb8(_selectedColor.red, _selectedColor.green, _selectedColor.blue),
      );
    }
    _encodedImage = img.encodeJpg(_editedImage!); // Re-encode after highlighting
    if (mounted) setState(() {});
  }

  void _applyCrop() {
    if (_editedImage == null || _cropRect == null) return;

    final imageWidth = _editedImage!.width;
    final imageHeight = _editedImage!.height;

    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final boxSize = renderBox.size;

    // Convert from widget space (cropRect) to image space
    final scaleX = imageWidth / boxSize.width;
    final scaleY = imageHeight / boxSize.height;

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
  }

  Future<void> _saveAndNavigateToResults() async {
    if (_encodedImage == null || _editedImage == null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final editedPath = '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(editedPath).writeAsBytes(_encodedImage!);
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.results,
          arguments: {
            'imageUrl': editedPath,
            'adjustments': {
              'brightness': _brightness,
              'contrast': _contrast,
              'saturation': _saturation,
            },
            'points': _points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
            'cropRect': _cropRect != null
                ? {
              'left': _cropRect!.left,
              'top': _cropRect!.top,
              'width': _cropRect!.width,
              'height': _cropRect!.height,
            }
                : {},
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.editAndAnalyze),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveAndNavigateToResults,
            tooltip: AppStrings.analyze,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Cancel',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTapDown: (details) {
                  if (!_isCropping) {
                    final box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final localPosition = box.globalToLocal(details.globalPosition);
                      final inverseMatrix = _matrix.clone()..invert();
                      final transformedPoint = inverseMatrix.transform3(Vector3(
                        localPosition.dx,
                        localPosition.dy,
                        0,
                      ));

                      final imageSize = box.size;
                      final relativeX = (transformedPoint.x / imageSize.width).clamp(0.0, 1.0);
                      final relativeY = (transformedPoint.y / imageSize.height).clamp(0.0, 1.0);

                      debugPrint('Tapped at local: $localPosition, transformed: $transformedPoint, relative: ($relativeX, $relativeY)');
                      setState(() {
                        _points.add(Offset(relativeX, relativeY));
                        _applyFilters();
                      });
                    }
                  }
                },
                onPanStart: _isCropping
                    ? (details) => setState(() => _cropStart = details.localPosition)
                    : null,
                onPanUpdate: _isCropping
                    ? (details) {
                  if (_cropStart != null) {
                    final current = details.localPosition;
                    final box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    final boxSize = box.size;

                    final left = (_cropStart!.dx < current.dx ? _cropStart!.dx : current.dx)
                        .clamp(0.0, boxSize.width);
                    final top = (_cropStart!.dy < current.dy ? _cropStart!.dy : current.dy)
                        .clamp(0.0, boxSize.height);
                    final width = (_cropStart!.dx - current.dx).abs().clamp(0.0, boxSize.width - left);
                    final height = (_cropStart!.dy - current.dy).abs().clamp(0.0, boxSize.height - top);


                    setState(() => _cropRect = Rect.fromLTWH(left, top, width, height));
                  }
                }
                    : null,
                onPanEnd: _isCropping
                    ? (_) {
                  setState(() {
                    _applyFilters();
                    _cropStart = null;
                  });
                }
                    : null,
                child: Stack(
                  children: [
                    MatrixGestureDetector(
                      onMatrixUpdate: (m, tm, sm, rm) {
                        setState(() => _matrix = m);
                      },
                      child: Container(
                        key: _imageKey,
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                          child: Transform(
                            transform: _matrix,
                            child: _encodedImage != null
                                ? Image.memory(_encodedImage!, fit: BoxFit.contain)
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                    if (_isCropping && _cropRect != null)
                      Positioned(
                        left: _cropRect!.left,
                        top: _cropRect!.top,
                        child: Container(
                          width: _cropRect!.width,
                          height: _cropRect!.height,
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppMeasurements.smallPadding),
            _buildToolbar(),
            _buildAdjustmentSliders(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: AppMeasurements.smallPadding),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () {
              setState(() {
                _points.clear();
                _brightness = 0.0;
                _contrast = 1.0;
                _saturation = 1.0;
                _cropRect = null;
                _applyFilters();
              });
            },
            tooltip: AppStrings.reset,
          ),
          IconButton(
            icon: const Icon(Icons.colorize),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(AppStrings.selectHighlightColor),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: _selectedColor,
                    onColorChanged: (color) => setState(() => _selectedColor = color),
                    showLabel: true,
                    pickerAreaHeightPercent: 0.8,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppStrings.ok),
                  ),
                ],
              ),
            ),
            tooltip: AppStrings.selectColor,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _points.clear();
                _applyFilters();
              });
            },
            tooltip: AppStrings.clearMarks,
          ),
          IconButton(
            icon: const Icon(Icons.crop),
            onPressed: () {
              setState(() {
                _isCropping = !_isCropping;
                if (!_isCropping) _cropRect = null;
              });
            },
            tooltip: _isCropping ? 'Finish Cropping' : 'Crop Image',
            color: _isCropping ? Theme.of(context).primaryColor : null,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              setState(() {
                _matrix = Matrix4.copy(_matrix)..scale(1.2);
              });
            },
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              setState(() {
                _matrix = Matrix4.copy(_matrix)..scale(0.8);
              });
            },
            tooltip: 'Zoom Out',
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentSliders() {
    return Padding(
      padding: const EdgeInsets.all(AppMeasurements.smallPadding),
      child: Column(
        children: [
          _buildSlider(Icons.brightness_6, _brightness, 0.0, 2.0, AppStrings.brightness),
          _buildSlider(Icons.contrast, _contrast, 0.0, 2.0, AppStrings.contrast),
          _buildSlider(Icons.color_lens, _saturation, 0.0, 2.0, AppStrings.saturation),
        ],
      ),
    );
  }

  Widget _buildSlider(IconData icon, double value, double min, double max, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppMeasurements.extraSmallPadding),
      child: Row(
        children: [
          Icon(icon, size: AppMeasurements.iconSizeMedium),
          const SizedBox(width: AppMeasurements.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: 20,
                  label: value.toStringAsFixed(1),
                  onChanged: (newValue) => setState(() {
                    switch (label) {
                      case AppStrings.brightness:
                        _brightness = newValue;
                        break;
                      case AppStrings.contrast:
                        _contrast = newValue;
                        break;
                      case AppStrings.saturation:
                        _saturation = newValue;
                        break;
                    }
                    _applyFilters();
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}