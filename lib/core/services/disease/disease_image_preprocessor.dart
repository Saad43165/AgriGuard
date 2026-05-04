import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class PreprocessResult {
  final List<List<List<List<double>>>> inputData;
  final List<int> outputShape;
  final int inferenceTime;

  PreprocessResult({
    required this.inputData,
    required this.outputShape,
    required this.inferenceTime,
  });
}

class DiseaseImagePreprocessor {
  static const int _minImageSize = 100;
  static const int _minImageBytes = 10240;

  Future<Map<String, dynamic>> checkImageQuality(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      if (bytes.length < _minImageBytes) {
        return {'isGoodQuality': false, 'reason': 'Image file too small'};
      }

      final image = img.decodeImage(bytes);
      if (image == null) {
        return {'isGoodQuality': false, 'reason': 'Failed to decode image'};
      }

      if (image.width < _minImageSize || image.height < _minImageSize) {
        return {'isGoodQuality': false, 'reason': 'Image dimensions too small'};
      }

      final variation = _calculateColorVariation(image);
      if (variation < 10.0) {
        return {'isGoodQuality': false, 'reason': 'Image may be blurry'};
      }

      return {'isGoodQuality': true, 'reason': 'Image quality acceptable'};
    } catch (e) {
      return {'isGoodQuality': false, 'reason': 'Error analyzing image'};
    }
  }

  Future<PreprocessResult> preprocessForInference(
      File imageFile, List<int> inputShape, List<int> outputShape) async {

    final bytes = await imageFile.readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    image = img.bakeOrientation(image);

    final targetW = inputShape.length >= 3 ? inputShape[2] : 300;
    final targetH = inputShape.length >= 3 ? inputShape[1] : 300;
    final resized = img.copyResize(image, width: targetW, height: targetH,
        interpolation: img.Interpolation.linear);

    final input4D = _to4DList(resized);

    return PreprocessResult(
      inputData: input4D,
      outputShape: outputShape,
      inferenceTime: 0,
    );
  }

  List<List<List<List<double>>>> _to4DList(img.Image image) {
    return List.generate(1, (_) => List.generate(image.height, (y) =>
        List.generate(image.width, (x) {
          final pixel = image.getPixel(x, y);
          return [pixel.r.toDouble(), pixel.g.toDouble(), pixel.b.toDouble()];
        })
    ));
  }

  double _calculateColorVariation(img.Image image) {
    const sampleCount = 100;
    final rVals = <int>[], gVals = <int>[], bVals = <int>[];

    for (int i = 0; i < sampleCount; i++) {
      int x = (i * image.width ~/ sampleCount) % image.width;
      int y = (i * image.height ~/ sampleCount) % image.height;
      final p = image.getPixel(x, y);
      rVals.add(p.r.toInt());
      gVals.add(p.g.toInt());
      bVals.add(p.b.toInt());
    }

    return (_stdDev(rVals) + _stdDev(gVals) + _stdDev(bVals)) / 3.0;
  }

  double _stdDev(List<int> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }
}