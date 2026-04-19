// lib/core/services/leaf_detector.dart
//
// Shared leaf detection utility used by all three analysis services.
//
// ── Why colour alone is not enough ──────────────────────────────────────────
// The original detector only measured green/warm pixel ratios.  That fails
// for any green-coloured man-made object (flags, packaging, uniforms, walls).
//
// Real plant leaves have three physical properties that designed objects lack:
//
//   1. ORGANIC TEXTURE  — veins, spots, surface roughness create high local
//      pixel-to-pixel gradient.  Flags/packets have smooth, flat colour fills
//      with very low gradient.
//      • Pakistan flag gradient ≈ 1.7   |  real leaf gradient ≈ 8–25
//
//   2. ABSENCE OF FLAT REGIONS  — manufactured objects are designed with large
//      uniform colour blocks.  Real leaves have continuous tonal variation
//      everywhere.  We measure this as "flat 8×8 blocks" (local variance < 80).
//      • Pakistan flag flat-blocks ≈ 90 %  |  real leaf ≈ 0–35 %
//
//   3. COLOUR DIVERSITY  — a designed object uses a small number of distinct
//      colours (its brand palette).  A leaf's surface has hundreds of subtle
//      colour variations from chlorophyll, water content, disease, lighting.
//      • Army emblem unique colours ≈ 34   |  real leaf ≈ 80–200+
//
// Decision rule (ALL three conditions must hold for "is leaf"):
//   • plant colour present  : green + warm plant pixels > 8 %
//   • organic texture        : gradient_mean > 5.0
//   • not a flat object      : flat_block_pct < 75 %
//
//
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class LeafDetector {
  // ── Tuneable thresholds ──────────────────────────────────────────────────
  static const double _minPlantPct      = 8.0;   // % of green + warm pixels
  static const double _minGradient      = 5.0;   // mean pixel-to-pixel delta
  static const double _maxFlatBlockPct  = 75.0;  // % of near-uniform 8×8 blocks
  static const int    _blockSize        = 8;      // pixels per block side
  static const double _flatVarThresh    = 80.0;  // local variance threshold
  static const int    _edgeThreshold    = 15;    // gradient threshold for edge count
  static const int    _resizeWidth      = 240;   // analysis resolution

  /// Analyses [imageFile] and returns:
  ///   isLeaf          — bool
  ///   confidence      — double  [0–100] composite score
  ///   plantPercentage — double  green + warm pixel %
  ///   gradientMean    — double  mean absolute gradient
  ///   flatBlockPct    — double  % of near-uniform 8×8 blocks
  ///   edgeDensity     — double  % of high-contrast edge pixels
  ///   reason          — String  human-readable explanation
  ///   message         — String  user-facing message
  static Future<Map<String, dynamic>> detect(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('⚠️  LeafDetector: failed to decode image — assuming leaf');
        return _result(isLeaf: true, confidence: 50.0,
            reason: 'Decode failed — assuming leaf');
      }

      // Orient first, then resize to analysis resolution
      final oriented = img.bakeOrientation(image);
      final resized  = img.copyResize(oriented, width: _resizeWidth,
          interpolation: img.Interpolation.linear);

      final int W = resized.width;
      final int H = resized.height;
      final int total = W * H;

      // ── Pass 1: colour + gradient in a single pixel loop ──────────────────
      int    greenPixels = 0;
      int    warmPixels  = 0;
      int    edgeCount   = 0;
      double gradSum     = 0.0;
      int    gradN       = 0;

      for (int y = 0; y < H; y++) {
        for (int x = 0; x < W; x++) {
          final p = resized.getPixel(x, y);
          final double r = p.r.toDouble();
          final double g = p.g.toDouble();
          final double b = p.b.toDouble();
          final double luma = (r + g + b) / 3.0;

          // Colour: healthy leaf (green dominant)
          if (g > r * 1.15 && g > b * 1.15 && g > 25) greenPixels++;

          // Colour: diseased / dry leaf (warm: rust, blight, scorch, necrosis)
          if (r > 100 && g > 30 && b < 120 && r > b * 1.3) warmPixels++;

          // Gradient: compare to right and below neighbour
          if (x < W - 1) {
            final pR = resized.getPixel(x + 1, y);
            final double lumaR = (pR.r + pR.g + pR.b) / 3.0;
            final double dx = (luma - lumaR).abs();
            gradSum += dx;
            gradN++;
            if (dx > _edgeThreshold) edgeCount++;
          }
          if (y < H - 1) {
            final pD = resized.getPixel(x, y + 1);
            final double lumaD = (pD.r + pD.g + pD.b) / 3.0;
            final double dy = (luma - lumaD).abs();
            gradSum += dy;
            gradN++;
            if (dy > _edgeThreshold) edgeCount++;
          }
        }
      }

      final double greenPct    = (greenPixels / total) * 100.0;
      final double warmPct     = (warmPixels  / total) * 100.0;
      final double plantPct    = greenPct + warmPct * 0.5;
      final double gradientMean = gradN > 0 ? gradSum / gradN : 0.0;
      final double edgeDensity  = (edgeCount / (total * 2.0)) * 100.0;

      // ── Pass 2: flat-block ratio ───────────────────────────────────────────
      // Build a grayscale brightness map for the block analysis.
      // We reuse the pixels computed above via a second lightweight pass
      // (the image is already decoded and resized in memory).
      final List<List<double>> lumas = List.generate(H, (y) =>
          List.generate(W, (x) {
            final p = resized.getPixel(x, y);
            return (p.r + p.g + p.b) / 3.0;
          }));

      int flatBlocks  = 0;
      int totalBlocks = 0;

      for (int by = 0; by + _blockSize <= H; by += _blockSize) {
        for (int bx = 0; bx + _blockSize <= W; bx += _blockSize) {
          // Compute mean and variance of the block
          double sum = 0.0, sum2 = 0.0;
          for (int dy = 0; dy < _blockSize; dy++) {
            for (int dx = 0; dx < _blockSize; dx++) {
              final v = lumas[by + dy][bx + dx];
              sum  += v;
              sum2 += v * v;
            }
          }
          final n        = (_blockSize * _blockSize).toDouble();
          final mean     = sum / n;
          final variance = (sum2 / n) - (mean * mean);
          if (variance < _flatVarThresh) flatBlocks++;
          totalBlocks++;
        }
      }

      final double flatBlockPct = totalBlocks > 0
          ? (flatBlocks / totalBlocks) * 100.0
          : 100.0;

      // ── Decision logic ─────────────────────────────────────────────────────
      final bool hasPlantColour = plantPct   >= _minPlantPct;
      final bool hasTexture     = gradientMean >= _minGradient;
      final bool notFlatObject  = flatBlockPct <= _maxFlatBlockPct;

      // ALL three conditions required — any single green image passes colour
      // but designed objects (flags, packets, walls) fail texture + flat check.
      final bool isLeaf = hasPlantColour && hasTexture && notFlatObject;

      // ── Confidence score ──────────────────────────────────────────────────
      // Weighted blend: colour 30 %, texture 45 %, non-flatness 25 %
      final double colourScore  = math.min(plantPct / 40.0, 1.0);
      final double textureScore = math.min(gradientMean / 20.0, 1.0);
      final double flatScore    = math.max(0, 1.0 - flatBlockPct / 100.0);
      final double confidence   = (colourScore  * 0.30 +
                                   textureScore * 0.45 +
                                   flatScore    * 0.25) * 100.0;

      // ── Reason string (for debug / UI) ────────────────────────────────────
      final String reason = _buildReason(
        hasPlantColour, hasTexture, notFlatObject,
        plantPct, gradientMean, flatBlockPct,
      );

      debugPrint('🍃 LeafDetector:'
          ' green=${greenPct.toStringAsFixed(1)}%'
          ' warm=${warmPct.toStringAsFixed(1)}%'
          ' plant=${plantPct.toStringAsFixed(1)}%'
          ' grad=${gradientMean.toStringAsFixed(2)}'
          ' flat=${flatBlockPct.toStringAsFixed(1)}%'
          ' edge=${edgeDensity.toStringAsFixed(1)}%'
          ' → isLeaf=$isLeaf  conf=${confidence.toStringAsFixed(1)}%');

      return _result(
        isLeaf:     isLeaf,
        confidence: confidence,
        reason:     reason,
        extra: {
          'greenPercentage': greenPct,
          'warmPercentage':  warmPct,
          'plantPercentage': plantPct,
          'gradientMean':    gradientMean,
          'flatBlockPct':    flatBlockPct,
          'edgeDensity':     edgeDensity,
          // Individual gate outcomes (useful for debugging)
          'hasPlantColour': hasPlantColour,
          'hasTexture':     hasTexture,
          'notFlatObject':  notFlatObject,
        },
      );
    } catch (e, st) {
      debugPrint('❌ LeafDetector error: $e\n$st');
      return _result(isLeaf: true, confidence: 50.0,
          reason: 'Detection error — assuming leaf');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _buildReason(
    bool hasColour, bool hasTexture, bool notFlat,
    double plantPct, double gradient, double flatPct,
  ) {
    if (hasColour && hasTexture && notFlat) {
      return 'Plant colour ${plantPct.toStringAsFixed(1)}%,'
          ' texture gradient ${gradient.toStringAsFixed(1)},'
          ' flat blocks ${flatPct.toStringAsFixed(1)}%';
    }
    final reasons = <String>[];
    if (!hasColour) {
      reasons.add('Insufficient plant colour (${plantPct.toStringAsFixed(1)}%'
          ' < ${_minPlantPct.toStringAsFixed(0)}% required)');
    }
    if (!hasTexture) {
      reasons.add('Insufficient organic texture (gradient ${gradient.toStringAsFixed(2)}'
          ' < ${_minGradient.toStringAsFixed(1)} required) — image may be a'
          ' smooth/designed object such as a flag, packet, or screen');
    }
    if (!notFlat) {
      reasons.add('Too many flat colour regions (${flatPct.toStringAsFixed(1)}%'
          ' > ${_maxFlatBlockPct.toStringAsFixed(0)}% threshold) — consistent'
          ' with a manufactured object, not an organic leaf');
    }
    return reasons.join('; ');
  }

  static Map<String, dynamic> _result({
    required bool   isLeaf,
    required double confidence,
    required String reason,
    Map<String, dynamic> extra = const {},
  }) {
    return {
      'isLeaf':     isLeaf,
      'confidence': confidence,
      'message': isLeaf
          ? 'Image appears to be a plant leaf'
          : 'Image does not appear to be a plant leaf',
      'reason': reason,
      ...extra,
    };
  }
}
