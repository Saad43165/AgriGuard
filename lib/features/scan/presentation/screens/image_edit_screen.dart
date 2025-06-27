import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_routes.dart';

class ImageEditScreen extends StatefulWidget {
  final String imagePath;

  const ImageEditScreen({super.key, required this.imagePath});

  @override
  State<ImageEditScreen> createState() => _ImageEditScreenState();
}

class _ImageEditScreenState extends State<ImageEditScreen> with TickerProviderStateMixin {
  img.Image? _originalImage;
  img.Image? _editedImage;
  Uint8List? _encodedImage;
  bool _isLoading = true;
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  Color _selectedColor = Colors.red;
  List<Offset> _points = [];
  final GlobalKey _imageKey = GlobalKey();
  Matrix4 _matrix = Matrix4.identity();
  Rect? _cropRect;
  bool _isCropping = false;
  Offset? _cropStart;
  Offset? _cropEnd;
  double _currentScale = 1.0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadImage();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
        _editedImage = img.copyResize(decodedImage, width: 1000);
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.9),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _applyFilters() {
    if (_editedImage == null || _originalImage == null) return;

    _editedImage = img.copyResize(_originalImage!, width: 1000);

    _editedImage = img.adjustColor(
      _editedImage!,
      brightness: _brightness.clamp(-1.0, 1.0),
      contrast: _contrast.clamp(0.5, 1.5),
      saturation: _saturation.clamp(0.5, 1.5),
    );

    if (_points.isNotEmpty) _highlightAreas();

    if (_cropRect != null) _applyCrop();

    _encodedImage = img.encodeJpg(_editedImage!);
    setState(() {});
  }

  void _highlightAreas() {
    if (_editedImage == null) return;

    for (final point in _points) {
      final x = (point.dx * _editedImage!.width).toInt().clamp(0, _editedImage!.width - 1);
      final y = (point.dy * _editedImage!.height).toInt().clamp(0, _editedImage!.height - 1);

      img.drawCircle(
        _editedImage!,
        x: x,
        y: y,
        radius: 20,
        color: img.ColorRgb8(_selectedColor.red, _selectedColor.green, _selectedColor.blue),
      );
      img.drawCircle(
        _editedImage!,
        x: x,
        y: y,
        radius: 15,
        color: img.ColorRgb8(255, 255, 255),
      );
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
                : null,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.9),
          ),
        );
      }
    }
  }

  Widget _buildGlassCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.background.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(12),
            child: child,
          ),
        ),
      ),
    );
  }

  void _handleImageTapDown(TapDownDetails details) {
    if (_isCropping) {
      final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final localPosition = renderBox.globalToLocal(details.globalPosition);
      setState(() {
        _cropStart = localPosition;
        _cropEnd = localPosition;
        _updateCropRect();
      });
    } else {
      final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final localPosition = renderBox.globalToLocal(details.globalPosition);
      final size = renderBox.size;

      final normalizedX = (localPosition.dx / size.width).clamp(0.0, 1.0);
      final normalizedY = (localPosition.dy / size.height).clamp(0.0, 1.0);

      setState(() {
        _points.add(Offset(normalizedX, normalizedY));
        _applyFilters();
      });
    }
  }

  void _handleImagePanUpdate(DragUpdateDetails details) {
    if (_isCropping && _cropStart != null) {
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

  void _resetZoom() {
    setState(() {
      _matrix = Matrix4.identity();
      _currentScale = 1.0;
    });
  }

  void _zoomIn() {
    setState(() {
      _currentScale *= 1.2;
      _matrix = Matrix4.identity()..scale(_currentScale);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentScale = (_currentScale / 1.2).clamp(0.5, 10.0);
      _matrix = Matrix4.identity()..scale(_currentScale);
    });
  }

  @override
  Widget build( context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
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
            AppStrings.editAndAnalyze,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        actions: [
          _buildActionButton(
            icon: Icons.check_rounded,
            color: Theme.of(context).colorScheme.primary,
            onTap: _saveAndNavigateToResults,
          ),
          _buildActionButton(
            icon: Icons.close_rounded,
            color: Theme.of(context).colorScheme.error,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
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
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
            : SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildGlassCard(
                      child: GestureDetector(
                        onTapDown: _handleImageTapDown,
                        onPanUpdate: _handleImagePanUpdate,
                        onPanEnd: (_) {
                          if (_isCropping) _applyFilters();
                        },
                        child: Stack(
                          children: [
                            MatrixGestureDetector(
                              onMatrixUpdate: (m, tm, sm, rm) {
                                setState(() {
                                  _matrix = m;
                                  _currentScale = m.getMaxScaleOnAxis();
                                });
                              },
                              child: Container(
                                key: _imageKey,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Transform(
                                  transform: _matrix,
                                  child: _encodedImage != null
                                      ? Image.memory(
                                    _encodedImage!,
                                    fit: BoxFit.contain,
                                  )
                                      : const SizedBox.shrink(),
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
                                    color: Theme.of(context).colorScheme.background.withOpacity(0.3),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _buildToolbar(),
                _buildAdjustmentSliders(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return _buildGlassCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _buildToolButton(
              icon: Icons.undo_rounded,
              label: 'Reset',
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _points.clear();
                  _brightness = 0.0;
                  _contrast = 1.0;
                  _saturation = 1.0;
                  _cropRect = null;
                  _isCropping = false;
                  _matrix = Matrix4.identity();
                  _currentScale = 1.0;
                  _applyFilters();
                });
              },
            ),
            _buildToolButton(
              icon: Icons.colorize_rounded,
              label: 'Color',
              onTap: () {
                HapticFeedback.lightImpact();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                    ),
                    title: Text(
                      'Select Highlight Color',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: _selectedColor,
                        onColorChanged: (color) => setState(() => _selectedColor = color),
                        showLabel: true,
                        pickerAreaHeightPercent: 0.7,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'OK',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            _buildToolButton(
              icon: Icons.clear_rounded,
              label: 'Clear',
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _points.clear();
                  _applyFilters();
                });
              },
            ),
            _buildToolButton(
              icon: Icons.crop_rounded,
              label: _isCropping ? 'Apply' : 'Crop',
              isActive: _isCropping,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _isCropping = !_isCropping;
                  if (!_isCropping && _cropRect != null) {
                    _applyFilters();
                  } else {
                    _cropRect = null;
                  }
                });
              },
            ),
            _buildToolButton(
              icon: Icons.zoom_in_rounded,
              label: 'Zoom In',
              onTap: _zoomIn,
            ),
            _buildToolButton(
              icon: Icons.zoom_out_rounded,
              label: 'Zoom Out',
              onTap: _zoomOut,
            ),
            _buildToolButton(
              icon: Icons.center_focus_strong_rounded,
              label: 'Reset Zoom',
              onTap: _resetZoom,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: isActive
            ? LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        )
            : LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.2),
            Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isActive ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isActive ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdjustmentSliders() {
    return _buildGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSlider(
            icon: Icons.brightness_6_rounded,
            value: _brightness,
            min: -1.0,
            max: 1.0,
            label: 'Brightness',
            onChanged: (value) {
              setState(() {
                _brightness = value;
                _applyFilters();
              });
            },
          ),
          const SizedBox(height: 12),
          _buildSlider(
            icon: Icons.contrast_rounded,
            value: _contrast,
            min: 0.5,
            max: 1.5,
            label: 'Contrast',
            onChanged: (value) {
              setState(() {
                _contrast = value;
                _applyFilters();
              });
            },
          ),
          const SizedBox(height: 12),
          _buildSlider(
            icon: Icons.color_lens_rounded,
            value: _saturation,
            min: 0.5,
            max: 1.5,
            label: 'Saturation',
            onChanged: (value) {
              setState(() {
                _saturation = value;
                _applyFilters();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.3),
                Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              ],
            ),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              Slider(
                value: value,
                min: min,
                max: max,
                divisions: 20,
                label: value.toStringAsFixed(1),
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}