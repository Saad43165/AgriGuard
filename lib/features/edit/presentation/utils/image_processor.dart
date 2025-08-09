import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/drawing_point.dart';
import '../models/text_annotation.dart';
import 'constants.dart';

/// Manages image processing, including loading, editing, and saving images with adjustments,
/// drawings, and text annotations.
class ImageProcessor {
  static const int _imageWidth = 1200;
  static const int _jpegQuality = 95;
  static const double _paragraphWidth = 200.0;

  img.Image? _originalImage;
  img.Image? _editedImage;
  Uint8List? _encodedImage;

  // Adjustment parameters
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  double _hue = 0.0;
  double _temperature = 0.0;
  double _tint = 0.0;
  double _blurRadius = 0.0;
  double _posterizeLevel = 0.0;
  bool _isGrayscale = false;
  bool _isSepia = false;

  // Drawing and annotations
  final List<DrawingPoint> _drawingPoints = [];
  final List<TextAnnotation> _textAnnotations = [];
  Color _selectedColor = Colors.red;
  double _brushSize = 5.0;
  double _brushOpacity = 1.0;
  Color _highlightColor = Colors.yellow;
  double _highlightSize = 20.0;

  Uint8List? get encodedImage => _encodedImage;
  img.Image? get editedImage => _editedImage;

  /// Loads an image from the specified [path] and initializes editing.
  Future<void> loadImage(String path) async {
    final file = File(path);
    if (!await file.exists()) throw Exception('Image file not found at $path');
    final bytes = await file.readAsBytes();
    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) throw Exception('Failed to decode image');
    _originalImage = decodedImage;
    _editedImage = img.copyResize(decodedImage, width: _imageWidth);
    await _applyAllFilters();
  }

  /// Sets the edited image to a new [image] and applies all filters.
  void setEditedImage(img.Image image) {
    _editedImage = img.copyResize(image, width: image.width);
    _applyAllFilters();
  }

  /// Updates an adjustment parameter based on the [key] and [value].
  void updateAdjustment(String key, double value) {
    switch (key) {
      case 'Brightness':
        _brightness = value;
        break;
      case 'Contrast':
        _contrast = value;
        break;
      case 'Saturation':
        _saturation = value;
        break;
      case 'Hue':
        _hue = value;
        break;
      case 'Temperature':
        _temperature = value;
        break;
      case 'Tint':
        _tint = value;
        break;
    }
    _applyAllFilters();
  }

  /// Updates an effect parameter based on the [key] and [value].
  void updateEffect(String key, Object value) {
    switch (key) {
      case 'Blur':
        _blurRadius = value as double;
        break;
      case 'Posterize':
        _posterizeLevel = value as double;
        break;
      case 'Grayscale':
        _isGrayscale = value as bool;
        break;
      case 'Sepia':
        _isSepia = value as bool;
        break;
    }
    _applyAllFilters();
  }

  /// Updates highlight parameters with the specified [color] and [size].
  void updateHighlight(Color color, double size) {
    _highlightColor = color;
    _highlightSize = size;
    _applyAllFilters();
  }

  /// Updates drawing parameters with the specified [color], [size], and [opacity].
  void updateDraw(Color color, double size, double opacity) {
    _selectedColor = color;
    _brushSize = size;
    _brushOpacity = opacity;
    _applyAllFilters();
  }

  /// Handles user interaction based on the [tool] and [position].
  void handleInteraction(EditingTool tool, Offset position) {
    switch (tool) {
      case EditingTool.highlight:
        _drawingPoints.add(DrawingPoint(
          offset: position,
          color: _highlightColor,
          strokeWidth: _highlightSize,
          opacity: 0.5,
        ));
        break;
      case EditingTool.draw:
        _drawingPoints.add(DrawingPoint(
          offset: position,
          color: _selectedColor,
          strokeWidth: _brushSize,
          opacity: _brushOpacity,
        ));
        break;
      case EditingTool.text:
        _textAnnotations.add(TextAnnotation(
          position: position,
          text: 'Sample Text',
          style: TextStyle(
            color: _selectedColor,
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
          rotation: 0.0,
        ));
        break;
      default:
        break;
    }
    _applyAllFilters();
  }

  /// Adds a text annotation with the specified [text] and [color].
  void addTextAnnotation(String text, Color color) {
    _textAnnotations.add(TextAnnotation(
      position: const Offset(0.5, 0.5),
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
      ),
      rotation: 0.0,
    ));
    _applyAllFilters();
  }

  /// Adds a sticker with the specified [label] and [color].
  void addSticker(String label, Color color) {
    _textAnnotations.add(TextAnnotation(
      position: const Offset(0.5, 0.5),
      text: label,
      style: TextStyle(
        color: color,
        fontSize: 40.0,
        fontWeight: FontWeight.bold,
      ),
      rotation: 0.0,
    ));
    _applyAllFilters();
  }

  /// Applies a crop to the image based on [cropRect], [key], and [scale].
  void applyCrop(Rect cropRect, GlobalKey key, double scale) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (_editedImage == null || renderBox == null) return;
    final imageWidth = _editedImage!.width.toDouble();
    final imageHeight = _editedImage!.height.toDouble();
    final boxSize = renderBox.size;
    final scaleX = imageWidth / (boxSize.width * scale);
    final scaleY = imageHeight / (boxSize.height * scale);
    final x = (cropRect.left * scaleX).round().clamp(0, imageWidth.toInt() - 1);
    final y = (cropRect.top * scaleY).round().clamp(0, imageHeight.toInt() - 1);
    final width = (cropRect.width * scaleX).round().clamp(1, imageWidth.toInt() - x);
    final height = (cropRect.height * scaleY).round().clamp(1, imageHeight.toInt() - y);

    // Adjust drawing points and text annotations
    final cropLeft = x / imageWidth;
    final cropTop = y / imageHeight;
    final cropWidth = width / imageWidth;
    final cropHeight = height / imageHeight;

    _drawingPoints.removeWhere((point) {
      final px = point.offset.dx;
      final py = point.offset.dy;
      return px < cropLeft || px > cropLeft + cropWidth || py < cropTop || py > cropTop + cropHeight;
    });
    _drawingPoints.replaceRange(0, _drawingPoints.length, _drawingPoints.map((point) {
      final newX = (point.offset.dx - cropLeft) / cropWidth;
      final newY = (point.offset.dy - cropTop) / cropHeight;
      return DrawingPoint(
        offset: Offset(newX.clamp(0.0, 1.0), newY.clamp(0.0, 1.0)),
        color: point.color,
        strokeWidth: point.strokeWidth,
        opacity: point.opacity,
      );
    }).toList());

    _textAnnotations.removeWhere((annotation) {
      final px = annotation.position.dx;
      final py = annotation.position.dy;
      return px < cropLeft || px > cropLeft + cropWidth || py < cropTop || py > cropTop + cropHeight;
    });
    _textAnnotations.replaceRange(0, _textAnnotations.length, _textAnnotations.map((annotation) {
      final newX = (annotation.position.dx - cropLeft) / cropWidth;
      final newY = (annotation.position.dy - cropTop) / cropHeight;
      return TextAnnotation(
        position: Offset(newX.clamp(0.0, 1.0), newY.clamp(0.0, 1.0)),
        text: annotation.text,
        style: annotation.style,
        rotation: annotation.rotation,
      );
    }).toList());

    _editedImage = img.copyCrop(_editedImage!, x: x, y: y, width: width, height: height);
    _applyAllFilters();
  }

  /// Resets all adjustments and clears annotations.
  void resetAdjustments() {
    _brightness = 0.0;
    _contrast = 1.0;
    _saturation = 1.0;
    _hue = 0.0;
    _temperature = 0.0;
    _tint = 0.0;
    _blurRadius = 0.0;
    _posterizeLevel = 0.0;
    _isGrayscale = false;
    _isSepia = false;
    _drawingPoints.clear();
    _textAnnotations.clear();
    _applyAllFilters();
  }

  /// Saves the edited image and returns metadata.
  Future<Map<String, dynamic>> saveImage() async {
    if (_encodedImage == null) throw Exception('No image to save');
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '${appDir.path}/$fileName';
    await File(path).writeAsBytes(_encodedImage!);
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'imageUrl': path,
      'result': 'Analyzed Plant',
      'confidence': 95,
      'recommendation': 'Apply recommended treatment',
      'timestamp': DateTime.now().toIso8601String(),
      'severity': 'Medium',
      'treatment': 'Detailed treatment instructions',
    };
  }

  /// Applies all filters and annotations to the image.
  Future<void> _applyAllFilters() async {
    if (_originalImage == null || _editedImage == null) return;
    _editedImage = img.copyResize(_originalImage!, width: _imageWidth);

    // Apply basic adjustments
    _editedImage = img.adjustColor(
      _editedImage!,
      brightness: _brightness.clamp(-1.0, 1.0),
      contrast: _contrast.clamp(0.0, 2.0),
      saturation: _saturation.clamp(0.0, 2.0),
      hue: _hue.clamp(-180.0, 180.0),
    );

    // Apply temperature and tint
    if (_temperature != 0.0 || _tint != 0.0) {
      _applyTemperatureAndTint();
    }

    // Apply drawings
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

    // Apply effects
    if (_isGrayscale) _editedImage = img.grayscale(_editedImage!);
    if (_isSepia) _editedImage = img.sepia(_editedImage!);
    if (_blurRadius > 0) {
      _editedImage = img.gaussianBlur(_editedImage!, radius: _blurRadius.toInt().clamp(0, 10));
    }
    if (_posterizeLevel > 0) {
      final levels = (2 + _posterizeLevel * 14).toInt().clamp(2, 16);
      final step = 255 ~/ (levels - 1);
      for (int y = 0; y < _editedImage!.height; y++) {
        for (int x = 0; x < _editedImage!.width; x++) {
          final pixel = _editedImage!.getPixel(x, y);
          final r = (pixel.r ~/ step) * step;
          final g = (pixel.g ~/ step) * step;
          final b = (pixel.b ~/ step) * step;
          _editedImage!.setPixel(
            x,
            y,
            img.ColorRgb8(r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255)),
          );
        }
      }
    }

    // Apply text annotations
    await _applyTextAnnotations();

    _encodedImage = img.encodeJpg(_editedImage!, quality: _jpegQuality);
  }

  /// Applies temperature and tint adjustments to the image.
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

  /// Renders and applies text annotations to the image.
  Future<void> _applyTextAnnotations() async {
    if (_editedImage == null || _textAnnotations.isEmpty) return;
    for (final annotation in _textAnnotations) {
      final x = (annotation.position.dx * _editedImage!.width)
          .toInt()
          .clamp(0, _editedImage!.width - 1);
      final y = (annotation.position.dy * _editedImage!.height)
          .toInt()
          .clamp(0, _editedImage!.height - 1);

      final paragraphBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          fontSize: annotation.style.fontSize ?? 24.0,
          textAlign: TextAlign.left,
        ),
      )
        ..pushStyle(ui.TextStyle(
          color: annotation.style.color ?? _selectedColor,
          fontWeight: annotation.style.fontWeight,
        ))
        ..addText(annotation.text);

      final paragraph = paragraphBuilder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: _paragraphWidth));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.save();
      canvas.translate(x.toDouble(), y.toDouble());
      canvas.rotate(annotation.rotation);
      canvas.drawParagraph(paragraph, Offset.zero);
      canvas.restore();

      final picture = recorder.endRecording();
      final textImage =
      await picture.toImage(paragraph.maxIntrinsicWidth.ceil(), paragraph.height.ceil());
      final byteData = await textImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) continue;

      final textImg = img.decodePng(byteData.buffer.asUint8List());
      if (textImg != null) {
        _editedImage = img.compositeImage(
          _editedImage!,
          textImg,
          dstX: x,
          dstY: y,
          blend: img.BlendMode.alpha,
        );
      }
    }
  }
}