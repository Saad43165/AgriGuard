import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';


class SeverityModelReference {
  Interpreter? _interpreter;
  bool isLoaded = false;

  Future<void> load() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/severity_dynamic_quant.tflite');
      isLoaded = true;
      debugPrint('✅ Severity TFLite model loaded (reference only — not used for inference)');
      debugPrint('   Input: ${_interpreter!.getInputTensors()[0].shape}');
      debugPrint('   Output: ${_interpreter!.getOutputTensors()[0].shape}');
    } catch (e) {
      debugPrint('⚠️ Severity model unavailable: $e');
      isLoaded = false;
    }
  }

  Future<List<double>> predict(List<List<List<List<double>>>> input) async {
    if (!isLoaded) throw Exception('Model not loaded');
    final output = List.filled(4, 0.0);
    _interpreter!.run(input, output);
    return output;
  }

  void dispose() {
    _interpreter?.close();
    isLoaded = false;
  }
}