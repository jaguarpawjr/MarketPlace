import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class MlService {
  Interpreter? _interpreter;
  List<String>? _labels;

  static const String MODEL_PATH = 'assets/model/model.tflite';
  static const String LABELS_PATH = 'assets/model/labels.txt';
  
  // Update this to match your model's expected input size
  static const int INPUT_SIZE = 224; 

  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset(MODEL_PATH);
      await _loadLabels();
      print('ML Model loaded successfully.');
    } catch (e) {
      print('Error loading ML Model: $e');
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelData = await rootBundle.loadString(LABELS_PATH);
      _labels = labelData.split('\n').where((label) => label.trim().isNotEmpty).toList();
    } catch (e) {
      print('Error loading labels: $e');
    }
  }

  Future<Map<String, dynamic>?> runInference(Uint8List imageBytes) async {
    if (_interpreter == null || _labels == null || _labels!.isEmpty) {
      print('Interpreter or labels not initialized.');
      return null;
    }

    try {
      // 1. Decode the image
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        print('Failed to decode image.');
        return null;
      }

      // 2. Resize image to model input size (e.g. 224x224)
      img.Image resizedImage = img.copyResize(originalImage, width: INPUT_SIZE, height: INPUT_SIZE);

      // 3. Convert image to input tensor format
      // MobileNetV3 handles its own normalization internally, so we pass raw 0-255 values.
      var input = List.generate(1, (i) => List.generate(INPUT_SIZE, (y) => List.generate(INPUT_SIZE, (x) => List.generate(3, (c) => 0.0))));
      
      double minPixel = double.infinity;
      double maxPixel = double.negativeInfinity;

      for (int y = 0; y < INPUT_SIZE; y++) {
        for (int x = 0; x < INPUT_SIZE; x++) {
          final pixel = resizedImage.getPixelSafe(x, y);
          
          double r = pixel.r.toDouble();
          double g = pixel.g.toDouble();
          double b = pixel.b.toDouble();
          
          input[0][y][x][0] = r;
          input[0][y][x][1] = g;
          input[0][y][x][2] = b;
          
          if (r < minPixel) minPixel = r;
          if (r > maxPixel) maxPixel = r;
          if (g < minPixel) minPixel = g;
          if (g > maxPixel) maxPixel = g;
          if (b < minPixel) minPixel = b;
          if (b > maxPixel) maxPixel = b;
        }
      }

      print('Debug: Input tensor shape: [1, $INPUT_SIZE, $INPUT_SIZE, 3]');
      print('Debug: Input value range: min=$minPixel, max=$maxPixel');

      // 4. Prepare output tensor
      // Assuming classification model with output shape [1, num_classes]
      var output = List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);

      // 5. Run inference
      _interpreter!.run(input, output);

      // 6. Process results
      final List<double> results = List<double>.from(output[0]);
      print('Debug: Output tensor values: $results');
      
      // Find the index of the highest confidence
      double maxScore = -1;
      int maxIndex = -1;
      
      for (int i = 0; i < results.length; i++) {
        if (results[i] > maxScore) {
          maxScore = results[i];
          maxIndex = i;
        }
      }

      print('Debug: Predicted index: $maxIndex');
      if (maxIndex != -1) {
        print('Debug: Predicted label: ${_labels![maxIndex]}');
        return {
          'disease': _labels![maxIndex],
          'confidence': maxScore,
        };
      }
    } catch (e) {
      print('Error running inference: $e');
    }
    return null;
  }
}
