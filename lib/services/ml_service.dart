import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

// Top-level function for isolate
List<List<List<List<double>>>> _preprocessImageInIsolate(Uint8List imageBytes) {
  // 1. Decode the image
  img.Image? originalImage = img.decodeImage(imageBytes);
  if (originalImage == null) {
    throw Exception('Failed to decode image.');
  }

  // 2. Resize image to model input size (e.g. 224x224)
  img.Image resizedImage = img.copyResize(
    originalImage,
    width: MlService.inputSize,
    height: MlService.inputSize,
  );

  // 3. Convert image to input tensor format
  // MobileNetV3 handles its own normalization internally, so we pass raw 0-255 values.
  var input = List.generate(
    1,
    (i) => List.generate(
      MlService.inputSize,
      (y) => List.generate(
        MlService.inputSize, 
        (x) => List.generate(3, (c) => 0.0),
      ),
    ),
  );

  for (int y = 0; y < MlService.inputSize; y++) {
    for (int x = 0; x < MlService.inputSize; x++) {
      final pixel = resizedImage.getPixelSafe(x, y);

      input[0][y][x][0] = pixel.r.toDouble();
      input[0][y][x][1] = pixel.g.toDouble();
      input[0][y][x][2] = pixel.b.toDouble();
    }
  }
  
  return input;
}

class MlService {
  Interpreter? _interpreter;
  List<String>? _labels;

  static const String modelPath = 'assets/model/model.tflite';
  static const String labelsPath = 'assets/model/labels.txt';

  // Update this to match your model's expected input size
  static const int inputSize = 224;

  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      await _loadLabels();
      debugPrint('ML Model loaded successfully.');
    } catch (e) {
      debugPrint('Error loading ML Model: $e');
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelData = await rootBundle.loadString(labelsPath);
      _labels = labelData
          .split('\n')
          .where((label) => label.trim().isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error loading labels: $e');
    }
  }

  Future<Map<String, dynamic>?> runInference(Uint8List imageBytes) async {
    if (_interpreter == null || _labels == null || _labels!.isEmpty) {
      debugPrint('Interpreter or labels not initialized.');
      return null;
    }

    try {
      // Run preprocessing in a background isolate to avoid blocking the UI thread (fixing ANR)
      var input = await compute(_preprocessImageInIsolate, imageBytes);

      // 4. Prepare output tensor
      // Assuming classification model with output shape [1, num_classes]
      var output = List.filled(
        1 * _labels!.length,
        0.0,
      ).reshape([1, _labels!.length]);

      // 5. Run inference
      _interpreter!.run(input, output);

      // 6. Process results
      final List<double> results = List<double>.from(output[0]);
      debugPrint('Debug: Output tensor values: $results');

      // Find the index of the highest confidence
      double maxScore = -1;
      int maxIndex = -1;

      for (int i = 0; i < results.length; i++) {
        if (results[i] > maxScore) {
          maxScore = results[i];
          maxIndex = i;
        }
      }

      debugPrint('Debug: Predicted index: $maxIndex');
      if (maxIndex != -1) {
        debugPrint('Debug: Predicted label: ${_labels![maxIndex]}');
        return {'disease': _labels![maxIndex], 'confidence': maxScore};
      }
    } catch (e) {
      debugPrint('Error running inference: $e');
    }
    return null;
  }
}
