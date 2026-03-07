import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import '../models/leaf_analysis_result.dart';
import '../utils/constants.dart';

class LeafDetectionService {
  static Future<LeafAnalysisResult> analyzeImage(
      String? imagePath,
      String? imageBase64,
      ) async {
    try {
      if (imagePath == null && imageBase64 == null) {
        return LeafAnalysisResult(
          isLeaf: true,
          confidence: 50.0,
          reasons: ['No image available for analysis'],
        );
      }

      Uint8List imageBytes;

      if (imageBase64 != null) {
        imageBytes = base64Decode(imageBase64);
      } else {
        imageBytes = await File(imagePath!).readAsBytes();
      }

      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return LeafAnalysisResult(
          isLeaf: true,
          confidence: 50.0,
          reasons: ['Failed to decode image'],
        );
      }

      return _analyzeImageFeatures(image);
    } catch (e) {
      debugPrint('Leaf detection error: $e');
      return LeafAnalysisResult(
        isLeaf: true,
        confidence: 50.0,
        reasons: ['Detection error, defaulting to leaf'],
      );
    }
  }

  static LeafAnalysisResult _analyzeImageFeatures(img.Image image) {
    final resizedImage = img.copyResize(image, width: 300);

    final greenAnalysis = _analyzeGreenDominance(resizedImage);
    final textureAnalysis = _analyzeTexture(resizedImage);
    final shapeAnalysis = _analyzeShape(resizedImage);
    final colorAnalysis = _analyzeColorDistribution(resizedImage);
    final edgeAnalysis = _analyzeEdgeFeatures(resizedImage);

    double totalScore = _calculateTotalScore([
      greenAnalysis['score'] * 0.4,
      textureAnalysis['score'] * 0.25,
      shapeAnalysis['score'] * 0.2,
      edgeAnalysis['score'] * 0.15,
    ]);

    final normalizedScore = totalScore * 100;
    final isLeaf = normalizedScore > ResultScreenConstants.leafDetectionThreshold;
    final reasons = _generateReasons(
      isLeaf,
      greenAnalysis,
      textureAnalysis,
      colorAnalysis,
      edgeAnalysis,
    );

    debugPrint('🍃 Leaf Detection Results:');
    debugPrint('   Overall Score: ${normalizedScore.toStringAsFixed(1)}%');
    debugPrint('   Green: ${greenAnalysis['greenPercentage'].toStringAsFixed(1)}%');
    debugPrint('   Is Leaf: $isLeaf');

    return LeafAnalysisResult(
      isLeaf: isLeaf,
      confidence: normalizedScore,
      reasons: reasons,
      details: {
        'greenAnalysis': greenAnalysis,
        'textureAnalysis': textureAnalysis,
        'shapeAnalysis': shapeAnalysis,
        'colorAnalysis': colorAnalysis,
        'edgeAnalysis': edgeAnalysis,
      },
    );
  }

  static double _calculateTotalScore(List<double> scores) {
    return scores.fold(0.0, (sum, score) => sum + score);
  }

  static Map<String, dynamic> _analyzeGreenDominance(img.Image image) {
    int greenPixels = 0;
    int totalPixels = image.width * image.height;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        if (g > r * 1.2 && g > b * 1.2 && g > 30) {
          greenPixels++;
        }
      }
    }

    final greenPercentage = (greenPixels / totalPixels) * 100;

    double score = 0.0;
    if (greenPercentage > 60) {
      score = 1.0;
    } else if (greenPercentage > 40) {
      score = 0.8;
    } else if (greenPercentage > 20) {
      score = 0.5;
    } else if (greenPercentage > 10) {
      score = 0.3;
    }

    return {
      'greenPercentage': greenPercentage,
      'score': score,
      'greenPixels': greenPixels,
      'totalPixels': totalPixels,
    };
  }

  static Map<String, dynamic> _analyzeTexture(img.Image image) {
    final gray = img.grayscale(image);

    int edgeCount = 0;
    final edgeThreshold = 25;

    for (int y = 1; y < gray.height - 1; y++) {
      for (int x = 1; x < gray.width - 1; x++) {
        final center = _getLuminance(gray.getPixel(x, y));
        final right = _getLuminance(gray.getPixel(x + 1, y));
        final bottom = _getLuminance(gray.getPixel(x, y + 1));

        if ((center - right).abs() > edgeThreshold ||
            (center - bottom).abs() > edgeThreshold) {
          edgeCount++;
        }
      }
    }

    final edgeDensity = (edgeCount / (gray.width * gray.height)) * 100;

    double score = 0.0;
    if (edgeDensity > 5 && edgeDensity < 40) {
      score = 0.7 + (edgeDensity / 100);
    } else if (edgeDensity < 2) {
      return {'score': 0.2, 'edgeDensity': edgeDensity, 'isTooUniform': true};
    } else if (edgeDensity > 50) {
      return {'score': 0.3, 'edgeDensity': edgeDensity, 'isTooNoisy': true};
    }

    return {
      'score': score,
      'edgeDensity': edgeDensity,
      'hasComplexTexture': edgeDensity > 10,
    };
  }

  static Map<String, dynamic> _analyzeShape(img.Image image) {
    final aspectRatio = image.width / image.height;

    double score = 0.0;
    if (aspectRatio >= 1.2 && aspectRatio <= 4.0) {
      score = 0.8;
    } else if (aspectRatio >= 1.0 && aspectRatio <= 1.5) {
      score = 0.5;
    } else {
      score = 0.3;
    }

    return {
      'score': score,
      'aspectRatio': aspectRatio,
      'width': image.width,
      'height': image.height,
    };
  }

  static Map<String, dynamic> _analyzeColorDistribution(img.Image image) {
    Map<String, int> colorBins = {};

    for (int y = 0; y < image.height; y += 2) {
      for (int x = 0; x < image.width; x += 2) {
        final pixel = image.getPixel(x, y);
        final colorKey =
            '${(pixel.r ~/ 32)}-${(pixel.g ~/ 32)}-${(pixel.b ~/ 32)}';
        colorBins[colorKey] = (colorBins[colorKey] ?? 0) + 1;
      }
    }

    final uniqueColors = colorBins.length;
    final totalSamples = (image.width / 2) * (image.height / 2);
    final colorVariety = (uniqueColors / totalSamples) * 100;

    return {
      'uniqueColors': uniqueColors,
      'colorVariety': colorVariety,
      'hasTooManyColors': colorVariety > 15,
    };
  }

  static Map<String, dynamic> _analyzeEdgeFeatures(img.Image image) {
    final gray = img.grayscale(image);
    final edges = img.sobel(gray);

    int straightEdgeCount = 0;
    int totalEdgePixels = 0;

    for (int y = 1; y < edges.height - 1; y++) {
      for (int x = 1; x < edges.width - 1; x++) {
        final pixel = edges.getPixel(x, y);
        final luminance = _getLuminance(pixel);

        if (luminance > 100) {
          totalEdgePixels++;

          final neighbors = [
            _getLuminance(edges.getPixel(x - 1, y - 1)),
            _getLuminance(edges.getPixel(x, y - 1)),
            _getLuminance(edges.getPixel(x + 1, y - 1)),
            _getLuminance(edges.getPixel(x - 1, y)),
            _getLuminance(edges.getPixel(x + 1, y)),
            _getLuminance(edges.getPixel(x - 1, y + 1)),
            _getLuminance(edges.getPixel(x, y + 1)),
            _getLuminance(edges.getPixel(x + 1, y + 1)),
          ];

          int alignedNeighbors = 0;
          for (final neighbor in neighbors) {
            if (neighbor > 50) alignedNeighbors++;
          }

          if (alignedNeighbors >= 4) {
            straightEdgeCount++;
          }
        }
      }
    }

    final straightEdgeRatio = totalEdgePixels > 0
        ? (straightEdgeCount / totalEdgePixels) * 100
        : 0;

    double score = 0.0;
    if (straightEdgeRatio < 20) {
      score = 0.8;
    } else if (straightEdgeRatio < 40) {
      score = 0.5;
    } else {
      score = 0.2;
    }

    return {
      'score': score,
      'straightEdgeRatio': straightEdgeRatio,
      'totalEdgePixels': totalEdgePixels,
      'straightEdgeCount': straightEdgeCount,
      'hasTooManyStraightEdges': straightEdgeRatio > 30,
    };
  }

  static double _getLuminance(img.Pixel pixel) {
    return (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b);
  }

  static List<String> _generateReasons(
      bool isLeaf,
      Map<String, dynamic> greenAnalysis,
      Map<String, dynamic> textureAnalysis,
      Map<String, dynamic> colorAnalysis,
      Map<String, dynamic> edgeAnalysis,
      ) {
    final reasons = <String>[];

    if (!isLeaf) {
      reasons.add('Image appears to be non-plant material');
      if (greenAnalysis['greenPercentage'] < 20) {
        reasons.add(
            'Low green color presence (${greenAnalysis['greenPercentage'].toStringAsFixed(1)}%)');
      }
      if (textureAnalysis['isTooUniform'] ?? false) {
        reasons.add('Texture appears artificial or uniform');
      }
      if (colorAnalysis['hasTooManyColors'] ?? false) {
        reasons.add('Unnatural color distribution for plant leaves');
      }
      if (edgeAnalysis['hasTooManyStraightEdges'] ?? false) {
        reasons.add('Contains many straight edges (uncommon for leaves)');
      }
    } else {
      reasons.add('Image characteristics match plant leaves');
      if (greenAnalysis['greenPercentage'] > 40) {
        reasons.add(
            'Significant green color present (${greenAnalysis['greenPercentage'].toStringAsFixed(1)}%)');
      }
      if (textureAnalysis['hasComplexTexture'] ?? false) {
        reasons.add('Complex texture pattern detected');
      }
    }

    return reasons;
  }
}