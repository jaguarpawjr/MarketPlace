import 'package:flutter/material.dart';

class DiseaseDetectionScreen extends StatelessWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Disease Detection',
          style: TextStyle(fontSize: 22, color: Colors.white),
        ),
        SizedBox(height: 8),
        Expanded(
          child: Center(
            child: Text(
              'Image upload & analysis placeholder',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ],
    );
  }
}
